"use client"

import { useEffect, useRef, useState, useCallback } from "react"
import { Navigation, Maximize2, Bell, AlertTriangle } from "lucide-react"
import { Button } from "@/components/ui/button"
import { toast } from "@/hooks/use-toast"
import {
  getNearbyStops,
  getRouteDetails,
  getOptimizedRoute,
  getTrafficConditions,
  searchLocations,
  type NearbyStop,
  type BusRoute,
  type MapLocation,
  type RoutePoint
} from "@/lib/api/map"

type BusStatus = 'approaching' | 'arrived' | 'departed'

interface TrackingBus {
  route: string
  routeId?: string
  from?: string
  to?: string
  status?: BusStatus
  type?: string
  currentLocation?: { lat: number; lng: number }
}

interface MapViewProps {
  trackingBus?: TrackingBus
  showNearbyBuses?: boolean
  onSOSClick?: () => void
  onNotificationClick?: () => void
}

interface LeafletMap {
  setView: (center: [number, number], zoom: number) => LeafletMap
  remove: () => void
  removeLayer: (layer: any) => LeafletMap
  panTo: (latLng: [number, number], options?: { animate?: boolean; duration?: number }) => LeafletMap
  fitBounds: (bounds: any, options?: { padding?: [number, number] }) => LeafletMap
  addLayer: (layer: any) => LeafletMap
  getContainer: () => HTMLElement
}

type Marker = {
  setLatLng: (latLng: [number, number] | { lat: number; lng: number }) => void
  remove: () => void
  bindPopup: (content: string) => Marker
  openPopup: () => void
  addTo: (map: LeafletMap) => Marker
}

type RouteLayer = {
  remove: () => void
  getBounds: () => any
  addTo: (map: LeafletMap) => RouteLayer
}

export function MapView({ 
  trackingBus, 
  showNearbyBuses = true,
  onSOSClick,
  onNotificationClick
}: MapViewProps) {
  const mapRef = useRef<HTMLDivElement>(null)
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null)
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [map, setMap] = useState<LeafletMap | null>(null)
  const [isMapInitialized, setIsMapInitialized] = useState(false)
  
  // State for markers and layers
  const [busMarkers, setBusMarkers] = useState<Marker[]>([])
  const [stopMarkers, setStopMarkers] = useState<Marker[]>([])
  const [trackingMarker, setTrackingMarker] = useState<Marker | null>(null)
  const [routeLayer, setRouteLayer] = useState<RouteLayer | null>(null)
  const [userMarker, setUserMarker] = useState<Marker | null>(null)
  
  // State for API data
  const [nearbyStops, setNearbyStops] = useState<NearbyStop[]>([])
  const [selectedRoute, setSelectedRoute] = useState<BusRoute | null>(null)
  const [trafficInfo, setTrafficInfo] = useState<{ condition: 'light' | 'moderate' | 'heavy'; delay: number } | null>(null)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  // Function to fetch and display nearby bus stops
  const updateNearbyStops = useCallback(async (lat: number, lng: number) => {
    try {
      setIsLoading(true)
      
      // Clear existing stop markers
      stopMarkers.forEach(marker => marker.remove())
      setStopMarkers([])
      
      const stops = await getNearbyStops(lat, lng)
      setNearbyStops(stops)
      
      // Add markers for each bus stop
      if (map && stops.length > 0) {
        const L = (window as any).L
        const newMarkers = stops.map(stop => {
          const stopIcon = L.divIcon({
            className: "custom-stop-marker",
            html: `<div style="background: linear-gradient(135deg, #0ea5e9 0%, #0284c7 100%); color: #ffffff; padding: 6px 10px; border-radius: 14px; font-size: 11px; font-weight: 900; border: 2px solid #ffffff; box-shadow: 0 3px 6px rgba(0,0,0,0.4);">STOP</div>`,
            iconSize: [50, 32],
            iconAnchor: [25, 16],
          })

          return L.marker([stop.latitude, stop.longitude], { icon: stopIcon })
            .addTo(map)
            .bindPopup(`
              <div class="p-3 min-w-48">
                <h3 class="font-bold text-gray-900 mb-2">${stop.name}</h3>
                <div class="space-y-2 text-sm">
                  ${stop.nextBuses.map(bus => `
                    <div class="border-t pt-2">
                      <p class="text-gray-600">Route: <span class="font-medium">${bus.routeName}</span></p>
                      <p class="text-gray-600">Arrival: <span class="font-medium">${bus.estimatedArrival}</span></p>
                    </div>
                  `).join('')}
                </div>
              </div>
            `)
        })
        
        setStopMarkers(newMarkers)
      }
    } catch (err) {
      console.error('Error fetching nearby stops:', err)
      setError('Failed to load nearby bus stops')
      toast({
        title: "Error",
        description: "Failed to load nearby bus stops. Please try again.",
        variant: "destructive",
      })
    } finally {
      setIsLoading(false)
    }
  }, [map, stopMarkers])
  
  // Function to fetch and display route details
  const updateRouteDetails = useCallback(async (routeId: string) => {
    try {
      setIsLoading(true)
      const route = await getRouteDetails(routeId)
      setSelectedRoute(route)

      if (map && route.points.length > 0) {
        const L = (window as any).L
        const routeCoordinates = route.points.map(point => [point.latitude, point.longitude])
        
        // Remove existing route layer
        if (routeLayer) {
          routeLayer.remove()
        }

        // Create new route layer with color based on traffic
        const trafficConditions = await getTrafficConditions(
          route.points.map(point => ({ lat: point.latitude, lng: point.longitude }))
        )
        setTrafficInfo(trafficConditions)

        const routeColor = trafficConditions.condition === 'heavy' ? '#dc2626' : 
                          trafficConditions.condition === 'moderate' ? '#f97316' : 
                          '#22c55e'

        const newRouteLayer = L.polyline(routeCoordinates, {
          color: routeColor,
          weight: 4,
          opacity: 0.8,
          lineCap: 'round',
          lineJoin: 'round',
          dashArray: trafficConditions.condition === 'heavy' ? '10, 10' : null,
        }).addTo(map)

        setRouteLayer(newRouteLayer)
        
        // Add markers for stops along the route
        route.points
          .filter(point => point.stopType !== 'waypoint')
          .forEach(point => {
            const stopIcon = L.divIcon({
              className: "custom-route-stop-marker",
              html: `<div style="background: linear-gradient(135deg, #f97316 0%, #ea580c 100%); color: #ffffff; padding: 6px 10px; border-radius: 14px; font-size: 11px; font-weight: 900; border: 2px solid #ffffff; box-shadow: 0 3px 6px rgba(0,0,0,0.4);">${point.stopType === 'pickup' ? 'PICK UP' : 'DROP OFF'}</div>`,
              iconSize: [70, 32],
              iconAnchor: [35, 16],
            })

            L.marker([point.latitude, point.longitude], { icon: stopIcon })
              .addTo(map)
              .bindPopup(`
                <div class="p-3">
                  <p class="font-medium text-gray-900">${point.stopType === 'pickup' ? 'Pick-up Point' : 'Drop-off Point'}</p>
                  ${point.waitTime ? `<p class="text-sm text-gray-600">Wait time: ${point.waitTime} mins</p>` : ''}
                  ${point.distance ? `<p class="text-sm text-gray-600">Distance: ${point.distance.toFixed(1)} km</p>` : ''}
                </div>
              `)
          })

        // Fit map bounds to show entire route
        map.fitBounds(newRouteLayer.getBounds(), { padding: [50, 50] })

        // Show traffic alert if conditions are heavy
        if (trafficConditions.condition === 'heavy') {
          toast({
            title: "Heavy Traffic Alert",
            description: `Expected delay of ${trafficConditions.delay} minutes on this route.`,
            variant: "destructive",
          })
        }
      }
    } catch (err) {
      console.error('Error fetching route details:', err)
      setError('Failed to load route details')
      toast({
        title: "Error",
        description: "Failed to load route details. Please try again.",
        variant: "destructive",
      })
    } finally {
      setIsLoading(false)
    }
  }, [map, routeLayer])

  // Initialize map when component mounts
  useEffect(() => {
    if (!userLocation || !mapRef.current || isMapInitialized) return

    const initializeMap = async () => {
      try {
        const L = (window as any).L
        
        // Create map centered on user's location
        const newMap = L.map(mapRef.current).setView([userLocation.lat, userLocation.lng], 15)
        
        // Add tile layer
        L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
          attribution: "© OpenStreetMap contributors",
          maxZoom: 19,
          minZoom: 4,
          detectRetina: true,
          updateWhenIdle: true,
        }).addTo(newMap)
        
        setMap(newMap)
        setIsMapInitialized(true)
        
        // Add user marker
        const userIcon = L.divIcon({
          className: "custom-user-marker",
          html: '<div style="background-color: #3b82f6; width: 16px; height: 16px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3); animation: pulse 1.5s infinite;"></div>',
          iconSize: [22, 22],
          iconAnchor: [11, 11],
        })
        
        const marker = L.marker([userLocation.lat, userLocation.lng], { icon: userIcon })
          .addTo(newMap)
          .bindPopup('<div class="p-2 text-sm font-medium">Your Location</div>')
        
        setUserMarker(marker)
      } catch (error) {
        console.error('Error initializing map:', error)
      }
    }

    // Load Leaflet if not already loaded
    if (!(window as any).L) {
      Promise.all([
        loadScript("https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"),
        loadStylesheet("https://unpkg.com/leaflet@1.9.4/dist/leaflet.css")
      ]).then(initializeMap)
    } else {
      initializeMap()
    }
  }, [userLocation, isMapInitialized])

  // Update tracking bus route and location
  useEffect(() => {
    if (!map || !trackingBus) return
    
    // When a routeId is provided, show the route details
    if (trackingBus.routeId) {
      updateRouteDetails(trackingBus.routeId)
    }
    
    // When there's a current location, show nearby stops
    if (trackingBus.currentLocation) {
      updateNearbyStops(trackingBus.currentLocation.lat, trackingBus.currentLocation.lng)
    }
  }, [map, trackingBus, updateRouteDetails, updateNearbyStops])

  // Get user's location and set up location tracking
  useEffect(() => {
    if (navigator.geolocation) {
      // Get initial location
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const newLocation = {
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          }
          setUserLocation(newLocation)
        },
        (error) => {
          console.error("Error getting location:", error)
          setUserLocation({ lat: 12.9716, lng: 77.5946 }) // Default to Bangalore
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0
        }
      )
      
      // Set up continuous location tracking
      const watchId = navigator.geolocation.watchPosition(
        (position) => {
          if (userMarker) {
            const newPos = {
              lat: position.coords.latitude,
              lng: position.coords.longitude,
            }
            userMarker.setLatLng(newPos)
            setUserLocation(newPos)
          }
        },
        (error) => {
          console.error("Error watching location:", error)
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0
        }
      )
      
      return () => {
        navigator.geolocation.clearWatch(watchId)
      }
    }
  }, [userMarker])

  // Cleanup function
  useEffect(() => {
    return () => {
      if (map && mapRef.current) {
        // Clean up all markers and layers
        userMarker?.remove()
        busMarkers.forEach(marker => marker.remove())
        stopMarkers.forEach(marker => marker.remove())
        trackingMarker?.remove()
        routeLayer?.remove()

        // Remove the map instance if the container exists
        if (mapRef.current.parentNode) {
          map.remove()
        }
        
        // Reset all state
        setMap(null)
        setBusMarkers([])
        setStopMarkers([])
        setTrackingMarker(null)
        setRouteLayer(null)
        setUserMarker(null)
      }
    }
  }, [map, userMarker, busMarkers, stopMarkers, trackingMarker, routeLayer])

  // Helper function to load external scripts
  const loadScript = (src: string): Promise<void> => {
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = src
      script.onload = () => resolve()
      script.onerror = () => reject()
      document.head.appendChild(script)
    })
  }

  // Helper function to load external stylesheets
  const loadStylesheet = (href: string): Promise<void> => {
    return new Promise((resolve, reject) => {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = href
      link.onload = () => resolve()
      link.onerror = () => reject()
      document.head.appendChild(link)
    })
  }

  return (
    <div className="relative w-full">
      {/* SOS Button */}
      <Button 
        size="sm" 
        variant="destructive" 
        className="absolute top-2 left-2 z-20 shadow-md flex items-center gap-1 font-medium"
        onClick={onSOSClick}
      >
        <AlertTriangle className="w-4 h-4" />
        SOS
      </Button>
      
      {/* Notification Button */}
      <Button 
        size="sm" 
        variant="secondary" 
        className="absolute top-2 right-2 z-20 shadow-md bg-white hover:bg-orange-50 h-8 p-2 flex items-center gap-1"
        onClick={onNotificationClick}
      >
        <Bell className="w-4 h-4 text-orange-600" />
        <span className="text-orange-600 hidden sm:inline">Alerts</span>
      </Button>

      <div
        ref={mapRef}
        className={`relative overflow-hidden transition-all duration-300 rounded-lg border-2 border-orange-200 ${
          isFullscreen ? "fixed inset-4 z-50 h-auto" : "h-48 md:h-64 lg:h-80"
        }`}
      >
        {/* Map Controls */}
        <div className="absolute bottom-2 right-2 flex flex-col space-y-2 z-10">
          <Button 
            size="sm" 
            variant="secondary" 
            className="shadow-md bg-white hover:bg-orange-50 h-8 w-8 p-0"
            onClick={() => userLocation && map?.setView([userLocation.lat, userLocation.lng], 15)}
          >
            <Navigation className="w-4 h-4 text-orange-600" />
          </Button>
          <Button
            size="sm"
            variant="secondary"
            className="shadow-md bg-white hover:bg-orange-50 h-8 w-8 p-0"
            onClick={() => setIsFullscreen(!isFullscreen)}
          >
            <Maximize2 className="w-4 h-4 text-orange-600" />
          </Button>
        </div>

        {isFullscreen && (
          <Button
            size="sm"
            variant="secondary"
            className="absolute top-2 left-20 shadow-md bg-white hover:bg-orange-50 h-8 w-8 p-0 z-10"
            onClick={() => setIsFullscreen(false)}
          >
            <span className="text-orange-600">✕</span>
          </Button>
        )}

        {/* Loading and Error States */}
        {isLoading && (
          <div className="absolute inset-0 bg-black/10 flex items-center justify-center">
            <div className="bg-white p-4 rounded-lg shadow-lg">
              <p className="text-sm font-medium">Loading...</p>
            </div>
          </div>
        )}

        {error && (
          <div className="absolute bottom-4 left-1/2 transform -translate-x-1/2">
            <div className="bg-red-50 border border-red-200 text-red-800 px-4 py-2 rounded-lg shadow-lg">
              <p className="text-sm font-medium">{error}</p>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}