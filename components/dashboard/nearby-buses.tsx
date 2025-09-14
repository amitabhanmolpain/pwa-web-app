"use client"

import type React from "react"

import { Button } from "@/components/ui/button"
import { Clock, ChevronLeft, ChevronRight, Navigation, Info } from "lucide-react"
import { useState } from "react"
import { toast } from "@/hooks/use-toast"

const nearbyBuses = [
  {
    id: "1",
    route: "Route 45A",
    destination: "Whitefield - Electronic City",
    arrivalTime: "3 min",
    capacity: "Available",
    capacityColor: "bg-green-500",
    image: "/bangalore-volvo-bus-orange-grey.jpg",
    speed: "45 km/h",
    seatsAvailable: 12,
    womenSeats: 4,
    hasWomenConductor: true,
    driverName: "Rajesh Kumar",
    driverPhone: "+91 98765 43210",
  },
  {
    id: "2",
    route: "Route 12B",
    destination: "Koramangala - Indiranagar",
    arrivalTime: "7 min",
    capacity: "Crowded",
    capacityColor: "bg-red-500",
    image: "/bangalore-bmtc-bus-orange-grey.jpg",
    speed: "32 km/h",
    seatsAvailable: 3,
    womenSeats: 2,
    hasWomenConductor: false,
    driverName: "Suresh Reddy",
    driverPhone: "+91 98765 43211",
  },
  {
    id: "3",
    route: "Route 23C",
    destination: "Jayanagar - MG Road",
    arrivalTime: "12 min",
    capacity: "Half Full",
    capacityColor: "bg-yellow-500",
    image: "/bangalore-city-bus-orange-grey.jpg",
    speed: "38 km/h",
    seatsAvailable: 18,
    womenSeats: 6,
    hasWomenConductor: true,
    driverName: "Manjunath S",
    driverPhone: "+91 98765 43212",
  },
  {
    id: "4",
    route: "Route 67D",
    destination: "Banashankari - Marathahalli",
    arrivalTime: "15 min",
    capacity: "Available",
    capacityColor: "bg-green-500",
    image: "/bangalore-intercity-bus-orange-grey.jpg",
    speed: "42 km/h",
    seatsAvailable: 25,
    womenSeats: 8,
    hasWomenConductor: false,
    driverName: "Venkatesh M",
    driverPhone: "+91 98765 43213",
  },
  {
    id: "5",
    route: "Route 89E",
    destination: "HSR Layout - Bellandur",
    arrivalTime: "18 min",
    capacity: "Nearly Full",
    capacityColor: "bg-orange-500",
    image: "/bangalore-public-bus-orange-grey.jpg",
    speed: "35 km/h",
    seatsAvailable: 5,
    womenSeats: 2,
    hasWomenConductor: true,
    driverName: "Prakash N",
    driverPhone: "+91 98765 43214",
  },
  {
    id: "6",
    route: "Route 156F",
    destination: "Rajajinagar - Hebbal",
    arrivalTime: "22 min",
    capacity: "Available",
    capacityColor: "bg-green-500",
    image: "/bangalore-metro-feeder-bus.jpg",
    speed: "40 km/h",
    seatsAvailable: 20,
    womenSeats: 7,
    hasWomenConductor: true,
    driverName: "Ravi Kumar",
    driverPhone: "+91 98765 43215",
  },
]

interface NearbyBusesProps {
  onBusSelect?: (bus: any) => void
  onTrackBus?: (bus: any) => void
}

export function NearbyBuses({ onBusSelect, onTrackBus }: NearbyBusesProps) {
  const [currentPage, setCurrentPage] = useState(0)
  const [selectedBus, setSelectedBus] = useState<any>(null)

  const isMobile = typeof window !== "undefined" && window.innerWidth < 768
  const busesPerPage = isMobile ? 1 : 3
  const totalPages = Math.ceil(nearbyBuses.length / busesPerPage)

  const currentBuses = nearbyBuses.slice(currentPage * busesPerPage, (currentPage + 1) * busesPerPage)

  const nextPage = () => {
    setCurrentPage((prev) => (prev + 1) % totalPages)
  }

  const prevPage = () => {
    setCurrentPage((prev) => (prev - 1 + totalPages) % totalPages)
  }

  const handleBusInfo = (bus: any, e: React.MouseEvent) => {
    e.stopPropagation()
    setSelectedBus(bus)
    onBusSelect?.(bus)
  }

  const handleTrackBus = (bus: any, e: React.MouseEvent) => {
    e.stopPropagation()
    toast({
      title: "Tracking Bus",
      description: `You are now tracking ${bus.route} - ${bus.destination}. Speed: ${bus.speed}, Seats: ${bus.seatsAvailable}`,
    })
    onTrackBus?.(bus)
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold text-gray-900">Nearby Buses</h2>
        <div className="flex items-center space-x-2">
          <Button
            variant="ghost"
            size="sm"
            onClick={prevPage}
            className="p-1 h-8 w-8 md:opacity-0 md:hover:opacity-100 transition-opacity"
          >
            <ChevronLeft className="w-4 h-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={nextPage}
            className="p-1 h-8 w-8 md:opacity-0 md:hover:opacity-100 transition-opacity"
          >
            <ChevronRight className="w-4 h-4" />
          </Button>
        </div>
      </div>

      <div className="relative">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
          {currentBuses.map((bus) => (
            <div key={bus.id} className="relative">
              <div className="relative w-full h-40 md:h-32 rounded-lg overflow-hidden cursor-pointer">
                <img
                  src={bus.image || "/placeholder.svg?height=128&width=192&query=bangalore bus"}
                  alt={`${bus.route} bus`}
                  className="w-full h-full object-cover"
                />

                <div className="absolute inset-0 bg-gradient-to-t from-black/70 via-transparent to-transparent">
                  <div className="absolute bottom-2 left-2 right-2">
                    <p className="font-semibold text-white text-sm">{bus.route}</p>
                    <p className="text-xs text-gray-200 truncate">{bus.destination}</p>

                    <div className="flex items-center justify-between mt-1">
                      <div className="flex items-center space-x-1">
                        <Clock className="w-3 h-3 text-gray-200" />
                        <span className="text-sm font-medium text-white">{bus.arrivalTime}</span>
                      </div>
                      <div className="flex items-center space-x-1">
                        <div className={`w-2 h-2 rounded-full ${bus.capacityColor}`}></div>
                        <span className="text-xs text-gray-200">{bus.capacity}</span>
                      </div>
                    </div>
                  </div>
                </div>

                <div className="absolute top-2 right-2 flex space-x-1">
                  <Button
                    size="sm"
                    variant="secondary"
                    className="h-6 w-6 p-0 bg-white hover:bg-gray-100"
                    onClick={(e) => handleBusInfo(bus, e)}
                  >
                    <Info className="w-3 h-3 text-gray-900" />
                  </Button>
                  <Button
                    size="sm"
                    className="h-6 w-6 p-0 bg-orange-500 hover:bg-orange-600"
                    onClick={(e) => handleTrackBus(bus, e)}
                  >
                    <Navigation className="w-3 h-3 text-white" />
                  </Button>
                </div>
              </div>

              {selectedBus?.id === bus.id && (
                <div className="absolute top-full left-0 right-0 mt-2 bg-white border border-gray-200 rounded-lg p-3 shadow-lg z-10">
                  <div className="space-y-2">
                    <div className="flex items-center justify-between">
                      <span className="font-semibold text-gray-900">{bus.route}</span>
                      <Button
                        size="sm"
                        className="bg-orange-500 hover:bg-orange-600 text-white px-3 py-1"
                        onClick={(e) => handleTrackBus(bus, e)}
                      >
                        <Navigation className="w-3 h-3 mr-1" />
                        Track
                      </Button>
                    </div>
                    <p className="text-sm text-gray-600">{bus.destination}</p>
                    <div className="grid grid-cols-2 gap-2 text-xs">
                      <div>
                        <span className="text-gray-500">Speed:</span>
                        <span className="ml-1 font-medium">{bus.speed}</span>
                      </div>
                      <div>
                        <span className="text-gray-500">Seats:</span>
                        <span className="ml-1 font-medium">{bus.seatsAvailable}</span>
                      </div>
                      <div>
                        <span className="text-gray-500">Driver:</span>
                        <span className="ml-1 font-medium">{bus.driverName}</span>
                      </div>
                      <div>
                        <span className="text-gray-500">ETA:</span>
                        <span className="ml-1 font-medium">{bus.arrivalTime}</span>
                      </div>
                    </div>
                    {bus.hasWomenConductor && (
                      <div className="text-xs text-pink-600">✓ Women conductor | {bus.womenSeats} women seats</div>
                    )}
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
