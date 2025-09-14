"use client"

import { useEffect, useRef, useState } from "react"
import { Navigation, Maximize2 } from "lucide-react"
import { Button } from "@/components/ui/button"

interface MapViewProps {
  trackingBus?: any
  showNearbyBuses?: boolean
}

export function MapView({ trackingBus, showNearbyBuses = true }: MapViewProps) {
  const mapRef = useRef<HTMLDivElement>(null)
  const [userLocation, setUserLocation] = useState<{ lat: number; lng: number } | null>(null)
  const [isFullscreen, setIsFullscreen] = useState(false)
  const [map, setMap] = useState<any>(null)
  const [busMarkers, setBusMarkers] = useState<any[]>([])
  const [trackingMarker, setTrackingMarker] = useState<any>(null)
  const [routeLayer, setRouteLayer] = useState<any>(null)

  useEffect(() => {
    if (navigator.geolocation) {
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
      )
    } else {
      setUserLocation({ lat: 12.9716, lng: 77.5946 })
    }
  }, [])

  useEffect(() => {
    if (!userLocation || !mapRef.current) return

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
      } else {
        initializeLeafletMap()
      }
    }

    const initializeLeafletMap = () => {
      if (!mapRef.current || !userLocation || !(window as any).L) return

      const L = (window as any).L

      const newMap = L.map(mapRef.current).setView([12.9716, 77.5946], 12)

      L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
        attribution: "© OpenStreetMap contributors",
        maxZoom: 19,
      }).addTo(newMap)

      setMap(newMap)

      const userIcon = L.divIcon({
        className: "custom-user-marker",
        html: '<div style="background-color: #f97316; width: 20px; height: 20px; border-radius: 50%; border: 3px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3);"></div>',
        iconSize: [20, 20],
        iconAnchor: [10, 10],
      })

      L.marker([userLocation.lat, userLocation.lng], { icon: userIcon })
        .addTo(newMap)
        .bindPopup('<div class="p-2 text-sm font-medium">Your Location</div>')

      if (showNearbyBuses) {
        const busLocations = [
          {
            lat: 13.0827,
            lng: 77.5877,
            route: "Route WF-EC",
            from: "Whitefield",
            to: "Electronic City",
            speed: "45 km/h",
            seats: 12,
            price: "₹85",
            type: "Intercity Express",
            image: "/bangalore-volvo-bus.jpg",
          },
          {
            lat: 12.9279,
            lng: 77.6271,
            route: "Route KR-IN",
            from: "Koramangala",
            to: "Indiranagar",
            speed: "32 km/h",
            seats: 8,
            price: "₹25",
            type: "City Bus",
            image: "/bangalore-bmtc-bus.jpg",
          },
          {
            lat: 12.9698,
            lng: 77.7499,
            route: "Route MH-SB",
            from: "Marathahalli",
            to: "Silk Board",
            speed: "38 km/h",
            seats: 18,
            price: "₹35",
            type: "City Express",
            image: "/bangalore-city-bus.jpg",
          },
          {
            lat: 12.8406,
            lng: 77.6595,
            route: "Route BS-VJ",
            from: "Banashankari",
            to: "Vijayanagar",
            speed: "40 km/h",
            seats: 15,
            price: "₹30",
            type: "City Route",
            image: "/bangalore-local-bus.jpg",
          },
          {
            lat: 13.0358,
            lng: 77.597,
            route: "Route HB-YPR",
            from: "Hebbal",
            to: "Yesvantpur",
            speed: "35 km/h",
            seats: 20,
            price: "₹28",
            type: "Local Bus",
            image: "/bangalore-ordinary-bus.jpg",
          },
        ]

        const markers = busLocations.map((bus) => {
          const busIcon = L.divIcon({
            className: "custom-bus-marker",
            html: `<div style="background: linear-gradient(135deg, #f97316 0%, #ea580c 100%); color: #000000; padding: 6px 10px; border-radius: 14px; font-size: 11px; font-weight: 900; border: 2px solid #ffffff; box-shadow: 0 3px 6px rgba(0,0,0,0.4); letter-spacing: 0.5px;">BUS</div>`,
            iconSize: [44, 32],
            iconAnchor: [22, 16],
          })

          const marker = L.marker([bus.lat, bus.lng], { icon: busIcon })
            .addTo(newMap)
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
    }

    loadLeafletMap()
  }, [userLocation, showNearbyBuses])

  useEffect(() => {
    if (!map || !trackingBus || !(window as any).L) return

    const L = (window as any).L

    if (trackingMarker) {
      map.removeLayer(trackingMarker)
    }
    if (routeLayer) {
      map.removeLayer(routeLayer)
    }

    let routeCoordinates = []
    let routeDescription = ""

    if (trackingBus.from === "Whitefield" && trackingBus.to === "Electronic City") {
      routeCoordinates = [
        [13.0827, 77.5877], // Whitefield
        [13.0658, 77.5946], // Marathahalli
        [12.9716, 77.5946], // Central Bangalore
        [12.9279, 77.6271], // Koramangala
        [12.8438, 77.6606], // Electronic City
      ]
      routeDescription = "Whitefield to Electronic City"
    } else if (trackingBus.from === "Koramangala" && trackingBus.to === "Indiranagar") {
      routeCoordinates = [
        [12.9279, 77.6271], // Koramangala
        [12.9352, 77.6245], // Intermediate
        [12.9698, 77.6174], // Indiranagar
      ]
      routeDescription = "Koramangala to Indiranagar"
    } else {
      routeCoordinates = [
        [12.8406, 77.6595], // Banashankari
        [12.85, 77.65],
        [12.86, 77.64],
        [12.87, 77.63],
        [12.88, 77.62],
        [12.89, 77.61], // Vijayanagar
      ]
      routeDescription = "Banashankari to Vijayanagar"
    }

    const route = L.polyline(routeCoordinates, {
      color: "#f97316",
      weight: 4,
      opacity: 0.8,
    }).addTo(map)
    setRouteLayer(route)

    const busIcon = L.divIcon({
      className: "custom-tracking-bus",
      html: `<div style="background: linear-gradient(135deg, #dc2626 0%, #b91c1c 100%); color: #ffffff; padding: 8px 14px; border-radius: 18px; font-size: 12px; font-weight: 900; border: 3px solid #ffffff; box-shadow: 0 4px 8px rgba(0,0,0,0.5); letter-spacing: 0.5px;">TRACKING ${trackingBus.route}</div>`,
      iconSize: [140, 44],
      iconAnchor: [70, 22],
    })

    let currentIndex = 0
    const marker = L.marker(routeCoordinates[0], { icon: busIcon }).addTo(map)
    setTrackingMarker(marker)

    const moveInterval = setInterval(() => {
      currentIndex = (currentIndex + 1) % routeCoordinates.length
      const newPosition = routeCoordinates[currentIndex]

      marker.setLatLng(newPosition)
      map.setView(newPosition, 15)

      const currentSpeed = Math.floor(Math.random() * 40 + 20)

      marker.bindPopup(`
        <div class="p-3">
          <h3 class="font-bold text-red-600">Tracking: ${trackingBus.route}</h3>
          <p class="text-sm text-gray-600 mt-1">${routeDescription}</p>
          <p class="text-sm text-gray-600">Current Speed: ${currentSpeed} km/h</p>
          <p class="text-sm text-orange-600 font-medium">Live Tracking Active</p>
        </div>
      `)
    }, 1500)

    return () => {
      clearInterval(moveInterval)
      if (marker) map.removeLayer(marker)
      if (route) map.removeLayer(route)
    }
  }, [map, trackingBus])

  return (
    <div className="relative">
      <div
        ref={mapRef}
        className={`relative overflow-hidden transition-all duration-300 rounded-lg border-2 border-orange-200 ${
          isFullscreen ? "fixed inset-4 z-50 h-auto" : "h-48 md:h-64 lg:h-80"
        }`}
      >
        <div className="absolute top-2 right-2 flex flex-col space-y-2 lg:hidden z-10">
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
            className="absolute top-2 left-2 shadow-md bg-white hover:bg-orange-50 h-8 w-8 p-0 z-10"
            onClick={() => setIsFullscreen(false)}
          >
            <span className="text-orange-600">✕</span>
          </Button>
        )}
      </div>
    </div>
  )
}
