"use client"

import { useEffect, useRef, useState } from "react"
import { Navigation, Maximize2, Bell, AlertTriangle } from "lucide-react"
import { Button } from "@/components/ui/button"

type BusStatus = 'approaching' | 'arrived' | 'departed'

interface TrackingBus {
  route: string
  from?: string
  to?: string
  status?: BusStatus
  type?: string
}

interface MapViewProps {
  trackingBus?: TrackingBus
  showNearbyBuses?: boolean
  onSOSClick?: () => void
  onNotificationClick?: () => void
}

type Marker = {
  setLatLng: (latLng: [number, number] | { lat: number; lng: number }) => void
  remove: () => void
  bindPopup: (content: string) => any
  openPopup: () => void
}

interface LeafletMap {
  setView: (center: [number, number], zoom: number) => LeafletMap
  remove: () => void
  removeLayer: (layer: any) => LeafletMap
  panTo: (latLng: [number, number], options?: { animate?: boolean; duration?: number }) => LeafletMap
  fitBounds: (bounds: any, options?: { padding?: [number, number] }) => LeafletMap
  addLayer: (layer: any) => LeafletMap
}

interface LeafletStatic {
  map: (element: HTMLElement | string) => LeafletMap
  tileLayer: (urlTemplate: string, options?: any) => any
  marker: (latLng: [number, number], options?: any) => Marker
  polyline: (latlngs: [number, number][], options?: any) => any
  latLngBounds: (corner1: [number, number], corner2: [number, number]) => any
  divIcon: (options: any) => any
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
  const [busMarkers, setBusMarkers] = useState<Marker[]>([])
  const [trackingMarker, setTrackingMarker] = useState<Marker | null>(null)
  const [routeLayer, setRouteLayer] = useState<{ remove: () => void; addTo: (map: LeafletMap) => void } | null>(null)
  const [userMarker, setUserMarker] = useState<Marker | null>(null)
  const [routePoints, setRoutePoints] = useState<[number, number][]>([])
  const [busMovementInterval, setBusMovementInterval] = useState<NodeJS.Timeout | null>(null)

  useEffect(() => {
    if (navigator.geolocation) {
      // Get initial location
      navigator.geolocation.getCurrentPosition(
        (position) => {
          setUserLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          })
        },
        (error) => {
          console.error("Error getting location:", error)
          setUserLocation({ lat: 12.9716, lng: 77.5946 })
        },
        {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 0
        }
      )
      
      // Set up continuous location watching
      const watchId = navigator.geolocation.watchPosition(
        (position) => {
          setUserLocation({
            lat: position.coords.latitude,
            lng: position.coords.longitude,
          })
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
    } else {
      setUserLocation({ lat: 12.9716, lng: 77.5946 })
    }
  }, [])

  useEffect(() => {
    if (!userLocation || !mapRef.current || map) return

    const loadLeafletMap = async () => {
      if (!(window as any).L) {
        const leafletCSS = document.createElement("link")
        leafletCSS.rel = "stylesheet"
        leafletCSS.href = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"
        document.head.appendChild(leafletCSS)

        const leafletScript = document.createElement("script")
        leafletScript.src = "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"
        leafletScript.onload = initializeLeafletMap
        document.head.appendChild(leafletScript)

        // Optional: Load Leaflet Routing Machine for better route visualization
        const routingMachineCSS = document.createElement("link")
        routingMachineCSS.rel = "stylesheet"
        routingMachineCSS.href = "https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.css"
        document.head.appendChild(routingMachineCSS)

        const routingMachineScript = document.createElement("script")
        routingMachineScript.src = "https://unpkg.com/leaflet-routing-machine@3.2.12/dist/leaflet-routing-machine.min.js"
        document.head.appendChild(routingMachineScript)
      } else {
        initializeLeafletMap()
      }
    }

    const initializeLeafletMap = () => {
      if (!mapRef.current || !userLocation || !(window as any).L || map) return

      const L = (window as any).L as LeafletStatic

      // Create map centered on user's location with improved zoom level
      const newMap = L.map(mapRef.current).setView([userLocation.lat, userLocation.lng], 15)

      // Use a better map tile provider with more road details (OpenStreetMap)
      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "© OpenStreetMap contributors",
        maxZoom: 19,
      }).addTo(newMap)

      setMap(newMap as LeafletMap)

      // Create a pulsing user marker with accuracy circle
      const userIcon = L.divIcon({
        className: "custom-user-marker",
        html: '<div style="background-color: #3b82f6; width: 16px; height: 16px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3); animation: pulse 1.5s infinite;"></div>',
        iconSize: [22, 22],
        iconAnchor: [11, 11],
      })

      // Add a style for the pulsing animation
      if (!document.getElementById("map-pulse-animation")) {
        const style = document.createElement("style")
        style.id = "map-pulse-animation"
        style.innerHTML = `
          @keyframes pulse {
            0% { transform: scale(1); opacity: 1; }
            50% { transform: scale(1.3); opacity: 0.7; }
            100% { transform: scale(1); opacity: 1; }
          }
        `
        document.head.appendChild(style)
      }

      // Add the user marker with location details
      const marker = L.marker([userLocation.lat, userLocation.lng], { icon: userIcon })
        .addTo(newMap)
        .bindPopup('<div class="p-2 text-sm font-medium">Your Location</div>')
      
      setUserMarker(marker)
      
      // If showing nearby buses, add them to the map
      if (showNearbyBuses) {
        addNearbyBuses(newMap, L, userLocation)
      }
    }
    
    // Function to add nearby buses on the map
    const addNearbyBuses = (mapInstance: any, L: any, userLoc: {lat: number, lng: number}) => {
      // Calculate nearby locations based on actual roads and routes
      // These are randomized bus locations in a 1-3km radius, typically along major roads
      const busLocations = [
        {
          lat: userLoc.lat + (Math.random() * 0.01 - 0.005),
          lng: userLoc.lng + (Math.random() * 0.01 - 0.005),
          route: "Route 45A",
          from: "Nearby Location",
          to: "City Center",
          speed: "45 km/h",
          seats: 12,
          price: "₹35",
          type: "City Express",
          image: "/bangalore-volvo-bus-orange-grey.jpg",
        },
        {
          lat: userLoc.lat + (Math.random() * 0.015 - 0.0075),
          lng: userLoc.lng + (Math.random() * 0.015 - 0.0075),
          route: "Route 12B",
          from: "Local Area",
          to: "Business District",
          speed: "32 km/h",
          seats: 8,
          price: "₹25",
          type: "City Bus",
          image: "/bangalore-bmtc-bus-orange-grey.jpg",
        },
        {
          lat: userLoc.lat + (Math.random() * 0.02 - 0.01),
          lng: userLoc.lng + (Math.random() * 0.02 - 0.01),
          route: "Route 23C",
          from: "Suburban Area",
          to: "Metro Station",
          speed: "38 km/h",
          seats: 18,
          price: "₹30",
          type: "Metro Feeder",
          image: "/bangalore-city-bus-orange-grey.jpg",
        },
      ]

      const markers = busLocations.map((bus) => {
        const busIcon = L.divIcon({
          className: "custom-bus-marker",
          html: `<div style="background: linear-gradient(135deg, #f97316 0%, #ea580c 100%); color: #ffffff; padding: 6px 10px; border-radius: 14px; font-size: 11px; font-weight: 900; border: 2px solid #ffffff; box-shadow: 0 3px 6px rgba(0,0,0,0.4); letter-spacing: 0.5px;">BUS</div>`,
          iconSize: [44, 32],
          iconAnchor: [22, 16],
        })

        const marker = L.marker([bus.lat, bus.lng], { icon: busIcon })
          .addTo(mapInstance)
          .bindPopup(`
            <div class="p-3 min-w-48">
              <h3 class="font-bold text-gray-900 mb-2">${bus.route}</h3>
              <div class="space-y-1 text-sm">
                <p class="text-gray-600">Route: <span class="font-medium">${bus.from} → ${bus.to}</span></p>
                <p class="text-gray-600">Speed: <span class="font-medium">${bus.speed}</span></p>
                <p class="text-gray-600">Available Seats: <span class="font-medium">${bus.seats}</span></p>
                <p class="text-gray-600">Price: <span class="font-medium">${bus.price}</span></p>
                <p class="text-orange-600 font-medium">${bus.type}</p>
              </div>
            </div>
          `)

        return marker
      })

      setBusMarkers(markers)
    }

    loadLeafletMap()
    
    // Cleanup function
    return () => {
      try {
        if (map) {
          // Clean up all markers and layers
          userMarker?.remove()
          busMarkers.forEach(marker => marker.remove())
          trackingMarker?.remove()
          routeLayer?.remove()

          // Remove the map instance
          map.remove()
          
          // Reset all state
          setMap(null)
          setBusMarkers([])
          setTrackingMarker(null)
          setRouteLayer(null)
          setUserMarker(null)
        }
        
        if (busMovementInterval) {
          clearInterval(busMovementInterval)
          setBusMovementInterval(null)
        }
      } catch (error) {
        console.error('Error cleaning up map:', error)
      }
    }
  }, [userLocation, showNearbyBuses])

  useEffect(() => {
    if (!mapRef.current || !map || !trackingBus || !(window as any).L) return

    const L = (window as any).L

    // Clean up previous tracking elements
    if (trackingMarker) {
      map.removeLayer(trackingMarker)
    }
    if (routeLayer) {
      map.removeLayer(routeLayer)
    }
    if (busMovementInterval) {
      clearInterval(busMovementInterval)
      setBusMovementInterval(null)
    }

    // Prepare route fetching function
    const fetchRoute = async (startPoint: [number, number], endPoint: [number, number]) => {
      try {
        // Use OSRM for routing along real roads
        const response = await fetch(
          `https://router.project-osrm.org/route/v1/driving/${startPoint[1]},${startPoint[0]};${endPoint[1]},${endPoint[0]}?overview=full&geometries=geojson`
        );
        const data = await response.json();
        
        if (data.routes && data.routes.length > 0) {
          // Convert to Leaflet format [lat, lng]
          return data.routes[0].geometry.coordinates.map((coord: [number, number]) => [coord[1], coord[0]]);
        }
        return null;
      } catch (error) {
        console.error("Error fetching route:", error);
        return null;
      }
    };

    // Function to create a simple route if OSRM fails
    const createSimpleRoute = (startPoint: [number, number], endPoint: [number, number], numPoints = 20) => {
      const route = [];
      for (let i = 0; i <= numPoints; i++) {
        const ratio = i / numPoints;
        const lat = startPoint[0] + (endPoint[0] - startPoint[0]) * ratio;
        const lng = startPoint[1] + (endPoint[1] - startPoint[1]) * ratio;
        // Add some randomness to simulate a road
        const jitter = i > 0 && i < numPoints ? (Math.random() - 0.5) * 0.001 : 0;
        route.push([lat + jitter, lng + jitter]);
      }
      return route;
    };

    // Different icon based on bus status
    let iconHTML = `<div style="background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); color: #ffffff; padding: 8px 14px; border-radius: 18px; font-size: 12px; font-weight: 900; border: 3px solid #ffffff; box-shadow: 0 4px 8px rgba(0,0,0,0.5); letter-spacing: 0.5px;">TRACKING ${trackingBus.route}</div>`;
    
    if (trackingBus.status === 'arrived') {
      iconHTML = `<div style="background: linear-gradient(135deg, #16a34a 0%, #15803d 100%); color: #ffffff; padding: 8px 14px; border-radius: 18px; font-size: 12px; font-weight: 900; border: 3px solid #ffffff; box-shadow: 0 4px 8px rgba(0,0,0,0.5); letter-spacing: 0.5px;">BUS ARRIVED</div>`;
    } else if (trackingBus.status === 'approaching') {
      iconHTML = `<div style="background: linear-gradient(135deg, #f59e0b 0%, #d97706 100%); color: #ffffff; padding: 8px 14px; border-radius: 18px; font-size: 12px; font-weight: 900; border: 3px solid #ffffff; box-shadow: 0 4px 8px rgba(0,0,0,0.5); letter-spacing: 0.5px;">APPROACHING</div>`;
    }
    
    const busIcon = L.divIcon({
      className: "custom-tracking-bus",
      html: iconHTML,
      iconSize: [140, 44],
      iconAnchor: [70, 22],
    });

    // Create a new tracking marker
    const marker = L.marker([userLocation?.lat || 12.9716, userLocation?.lng || 77.5946], { icon: busIcon }).addTo(map);
    setTrackingMarker(marker);

    // Function to setup and start bus movement
    const setupBusMovement = async () => {
      // Define start and end points based on tracking status
      let startPoint: [number, number] = [0, 0];
      let endPoint: [number, number] = [0, 0];
      let routeDescription = "";
      
      // Get user's location as end point for approaching buses
      const userLoc: [number, number] = [
        userLocation?.lat || 12.9716, 
        userLocation?.lng || 77.5946
      ];
      
      // Set destination coordinates (MG Road as default)
      const destCoords: [number, number] = [12.9752, 77.6095]; // MG Road
      
      if (trackingBus.status === 'approaching') {
        // For approaching: start from a nearby location, end at user's location
        const nearbyStartLat = userLoc[0] + (Math.random() - 0.5) * 0.01; // About 500m-1km away
        const nearbyStartLng = userLoc[1] + (Math.random() - 0.5) * 0.01;
        startPoint = [nearbyStartLat, nearbyStartLng];
        endPoint = userLoc;
        routeDescription = `Approaching ${trackingBus.from || 'your location'}`;
        
        // Position the bus at the starting point
        marker.setLatLng([startPoint[0], startPoint[1]]);
        
      } else if (trackingBus.status === 'arrived') {
        // For arrived: stay at user's location
        startPoint = userLoc;
        endPoint = userLoc;
        routeDescription = `At ${trackingBus.from || 'your location'}`;
        
        // Position the bus at user's location
        marker.setLatLng([userLoc[0], userLoc[1]]);
        map.setView([userLoc[0], userLoc[1]], 17);
        
        // Show popup for arrived bus
        marker.bindPopup(`
          <div class="p-3">
            <h3 class="font-bold text-green-600">Bus Arrived: ${trackingBus.route}</h3>
            <p class="text-sm text-gray-600 mt-1">At: ${trackingBus.from || 'your location'}</p>
            <p class="text-sm text-gray-600">Waiting for passengers to board</p>
            <p class="text-sm text-green-600 font-medium">Please board now!</p>
          </div>
        `).openPopup();
        
        return; // No movement needed while arrived
        
      } else if (trackingBus.status === 'departed') {
        // For departed: start from user's location, end at destination
        startPoint = userLoc;
        endPoint = destCoords;
        routeDescription = `${trackingBus.from || 'Your location'} to ${trackingBus.to || 'MG Road'}`;
      } else {
        // Default tracking
        startPoint = userLoc;
        endPoint = destCoords;
        routeDescription = `Live tracking to ${trackingBus.to || 'destination'}`;
      }
      
      // Fetch route from OSRM or create simple route if that fails
      let routeCoordinates = await fetchRoute(startPoint, endPoint);
      
      if (!routeCoordinates || routeCoordinates.length === 0) {
        console.log("Falling back to simple route");
        routeCoordinates = createSimpleRoute(startPoint, endPoint);
      }
      
      // Store route points for animation
      setRoutePoints(routeCoordinates);
      
      // Draw the route line
      const route = L.polyline(routeCoordinates, {
        color: "#f97316",
        weight: 4,
        opacity: 0.8,
        dashArray: trackingBus.status === 'approaching' ? "10, 10" : null, // Dashed line for approaching
      }).addTo(map);
      setRouteLayer(route);
      
      // If bus is not arrived, animate it along the route
      if (trackingBus.status && ['approaching', 'departed'].includes(trackingBus.status)) {
        let currentPoint = 0;
        
        // Set initial position
        if (routeCoordinates.length > 0) {
          marker.setLatLng(routeCoordinates[0]);
        }
        
        // Update popup content based on status
        updateBusPopup(marker, routeDescription);
        
        // Center map to show both user and first point
        if (routeCoordinates.length > 0) {
          const bounds = L.latLngBounds([userLoc, routeCoordinates[0]]);
          map.fitBounds(bounds, { padding: [50, 50] });
        }
        
        // Set up interval to move bus along route
        const interval = setInterval(() => {
          currentPoint++;
          
          if (currentPoint >= routeCoordinates.length) {
            clearInterval(interval);
            
            // If approaching, set status to arrived when reaching destination
            if (trackingBus.status === 'approaching') {
              marker.setLatLng([userLoc[0], userLoc[1]]);
              marker.bindPopup(`
                <div class="p-3">
                  <h3 class="font-bold text-green-600">Bus Arrived: ${trackingBus.route}</h3>
                  <p class="text-sm text-gray-600 mt-1">At: ${trackingBus.from || 'your location'}</p>
                  <p class="text-sm text-gray-600">Waiting for passengers to board</p>
                  <p class="text-sm text-green-600 font-medium">Please board now!</p>
                </div>
              `).openPopup();
            }
            return;
          }
          
          // Move marker to next point
          const nextPoint = routeCoordinates[currentPoint];
          marker.setLatLng(nextPoint);
          
          // Update popup with current speed
          const currentSpeed = Math.floor(Math.random() * 30 + 15);
          updateBusPopup(marker, routeDescription, currentSpeed);
          
          // Keep map centered on bus during movement
          map.panTo(nextPoint, { animate: true, duration: 0.5 });
          
        }, 1000); // Move every 1 second
        
        setBusMovementInterval(interval);
      }
    };
    
    // Helper function to update bus popup
    const updateBusPopup = (busMarker: any, routeDesc: string, speed?: number) => {
      let popupContent = `
        <div class="p-3">
          <h3 class="font-bold text-red-600">Tracking: ${trackingBus.route}</h3>
          <p class="text-sm text-gray-600 mt-1">${routeDesc}</p>
          ${speed ? `<p class="text-sm text-gray-600">Current Speed: ${speed} km/h</p>` : ''}
          <p class="text-sm text-orange-600 font-medium">Live Tracking Active</p>
        </div>
      `;
      
      if (trackingBus.status === 'approaching') {
        popupContent = `
          <div class="p-3">
            <h3 class="font-bold text-orange-600">Approaching: ${trackingBus.route}</h3>
            <p class="text-sm text-gray-600 mt-1">Arriving at: ${trackingBus.from || 'your location'}</p>
            ${speed ? `<p class="text-sm text-gray-600">Current Speed: ${speed} km/h</p>` : ''}
            <p class="text-sm text-orange-600 font-medium">Bus approaching your location</p>
          </div>
        `;
      }
      
      busMarker.bindPopup(popupContent);
    };
    
    // Start the bus movement
    setupBusMovement();

    // Cleanup function
    return () => {
      if (busMovementInterval) {
        clearInterval(busMovementInterval);
      }
      if (marker && map) {
        map.removeLayer(marker);
      }
      if (routeLayer && map) {
        map.removeLayer(routeLayer);
      }
    };
  }, [map, trackingBus, userLocation]);

  return (
    <div className="relative w-full">
      {/* SOS Button on the left */}
      <Button 
        size="sm" 
        variant="destructive" 
        className="absolute top-2 left-2 z-20 shadow-md flex items-center gap-1 font-medium"
        onClick={onSOSClick || (() => alert("SOS Emergency feature activated"))}
      >
        <AlertTriangle className="w-4 h-4" />
        SOS
      </Button>
      
      {/* Notification Button on the right */}
      <Button 
        size="sm" 
        variant="secondary" 
        className="absolute top-2 right-2 z-20 shadow-md bg-white hover:bg-orange-50 h-8 p-2 flex items-center gap-1"
        onClick={onNotificationClick || (() => alert("Notifications panel"))}
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
          <Button size="sm" variant="secondary" className="shadow-md bg-white hover:bg-orange-50 h-8 w-8 p-0">
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
      </div>
    </div>
  )
}
