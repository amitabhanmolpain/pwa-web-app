"use client"

import type React from "react"

import { Button } from "@/components/ui/button"
import { Clock, ChevronLeft, ChevronRight, Navigation, Info, MapPin, Users } from "lucide-react"
import { useState, useEffect } from "react"
import { toast } from "@/hooks/use-toast"
import { getNearbyBuses, getBusSeatOccupancy, calculateCrowdingStatus } from "@/lib/api/buses"
import type { BusData, SeatOccupancyData } from "@/types/buses"

const popularDestinations = [
  {
    name: "MG Road",
    coordinates: { lat: 12.9752, lng: 77.6095 }
  },
  {
    name: "Electronic City",
    coordinates: { lat: 12.8438, lng: 77.6606 }
  },
  {
    name: "Banashankari",
    coordinates: { lat: 12.9255, lng: 77.5468 }
  },
  {
    name: "Whitefield",
    coordinates: { lat: 12.9698, lng: 77.7500 }
  },
  {
    name: "Koramangala",
    coordinates: { lat: 12.9352, lng: 77.6245 }
  },
  {
    name: "Indiranagar",
    coordinates: { lat: 12.9784, lng: 77.6408 }
  }
];

// Sample bus data template
const busSampleData = [
  {
    id: "1",
    route: "Route 45A",
    speed: "45 km/h",
    seatsAvailable: 12,
    womenSeats: 4,
    hasWomenConductor: true,
    driverName: "Rajesh Kumar",
    driverPhone: "+91 98765 43210",
    image: "/bangalore-volvo-bus-orange-grey.jpg",
    capacity: "Available",
    capacityColor: "bg-green-500",
  },
  {
    id: "2",
    route: "Route 12B",
    speed: "32 km/h",
    seatsAvailable: 3,
    womenSeats: 2,
    hasWomenConductor: false,
    driverName: "Suresh Reddy",
    driverPhone: "+91 98765 43211",
    image: "/bangalore-bmtc-bus-orange-grey.jpg",
    capacity: "Crowded",
    capacityColor: "bg-red-500",
  },
  {
    id: "3",
    route: "Route 23C",
    speed: "38 km/h",
    seatsAvailable: 18,
    womenSeats: 6,
    hasWomenConductor: true,
    driverName: "Manjunath S",
    driverPhone: "+91 98765 43212",
    image: "/bangalore-city-bus-orange-grey.jpg",
    capacity: "Half Full",
    capacityColor: "bg-yellow-500",
  },
  {
    id: "4",
    route: "Route 67D",
    speed: "42 km/h",
    seatsAvailable: 25,
    womenSeats: 8,
    hasWomenConductor: false,
    driverName: "Venkatesh M",
    driverPhone: "+91 98765 43213",
    image: "/bangalore-intercity-bus-orange-grey.jpg",
    capacity: "Available",
    capacityColor: "bg-green-500",
  },
  {
    id: "5",
    route: "Route 89E",
    speed: "35 km/h",
    seatsAvailable: 5,
    womenSeats: 2,
    hasWomenConductor: true,
    driverName: "Prakash N",
    driverPhone: "+91 98765 43214",
    image: "/bangalore-public-bus-orange-grey.jpg",
    capacity: "Nearly Full",
    capacityColor: "bg-orange-500",
  },
  {
    id: "6",
    route: "Route 156F",
    speed: "40 km/h",
    seatsAvailable: 20,
    womenSeats: 7,
    hasWomenConductor: true,
    driverName: "Ravi Kumar",
    driverPhone: "+91 98765 43215",
    image: "/bangalore-metro-feeder-bus.jpg",
    capacity: "Available",
    capacityColor: "bg-green-500",
  },
];

interface NearbyBusesProps {
  onBusSelect?: (bus: BusData & { seatOccupancy: SeatOccupancyData }) => void
  onTrackBus?: (bus: BusData & { seatOccupancy: SeatOccupancyData }) => void
}

export function NearbyBuses({ onBusSelect, onTrackBus }: NearbyBusesProps) {
  const [currentPage, setCurrentPage] = useState(0)
  const [selectedBus, setSelectedBus] = useState<any>(null)
  const [userLocation, setUserLocation] = useState<{lat: number, lng: number} | null>(null)
  const [nearbyBuses, setNearbyBuses] = useState<any[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [locationName, setLocationName] = useState<string>("your location")

  // Get user's current location
  useEffect(() => {
    setIsLoading(true);
    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          const userPos = {
            lat: position.coords.latitude,
            lng: position.coords.longitude
          };
          setUserLocation(userPos);
          
          // Try to get location name using reverse geocoding
          fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${userPos.lat}&lon=${userPos.lng}`)
            .then(response => response.json())
            .then(data => {
              if (data.address) {
                const locality = data.address.suburb || data.address.neighbourhood || data.address.city_district;
                if (locality) {
                  setLocationName(locality);
                }
              }
            })
            .catch(err => {
              console.error("Error getting location name:", err);
            });
          
          setIsLoading(false);
        },
        (error) => {
          console.error("Error getting location:", error);
          // Default to Bangalore center if location access is denied
          setUserLocation({ lat: 12.9716, lng: 77.5946 });
          setLocationName("Bangalore");
          setIsLoading(false);
        }
      );
    } else {
      // Geolocation not supported
      setUserLocation({ lat: 12.9716, lng: 77.5946 });
      setLocationName("Bangalore");
      setIsLoading(false);
    }
  }, []);

  // Fetch nearby buses from API
  useEffect(() => {
    const fetchNearbyBuses = async () => {
      if (!userLocation) return;
      
      try {
        // Fetch buses within 2km radius
        const buses = await getNearbyBuses(userLocation.lat, userLocation.lng, 2);
        
        // Get occupancy data for each bus
        const busesWithOccupancy = await Promise.all(
          buses.map(async (bus) => {
            const occupancy = await getBusSeatOccupancy(bus.id);
            const crowdingStatus = calculateCrowdingStatus(occupancy);
            
            return {
              ...bus,
              seatOccupancy: {
                ...occupancy,
                crowdingStatus,
              },
            };
          })
        );
        
        // Sort by arrival time
        busesWithOccupancy.sort((a, b) => {
          const timeA = parseInt(a.arrivalTime.replace(" min", ""));
          const timeB = parseInt(b.arrivalTime.replace(" min", ""));
          return timeA - timeB;
        });
        
        setNearbyBuses(busesWithOccupancy);
      } catch (error) {
        console.error("Error fetching nearby buses:", error);
        toast({
          title: "Error",
          description: "Failed to fetch nearby buses. Please try again.",
          variant: "destructive",
        });
      }
    };
    
    fetchNearbyBuses();
    
    // Set up periodic refresh every 30 seconds
    const refreshInterval = setInterval(fetchNearbyBuses, 30000);
    
    return () => clearInterval(refreshInterval);
  }, [userLocation]);

  const isMobile = typeof window !== "undefined" && window.innerWidth < 768
  const busesPerPage = isMobile ? 1 : 3
  const totalPages = nearbyBuses.length > 0 ? Math.ceil(nearbyBuses.length / busesPerPage) : 0
  const currentBuses = nearbyBuses.slice(currentPage * busesPerPage, (currentPage + 1) * busesPerPage)

  const nextPage = () => {
    if (totalPages > 0) {
      setCurrentPage((prev) => (prev + 1) % totalPages)
    }
  }

  const prevPage = () => {
    if (totalPages > 0) {
      setCurrentPage((prev) => (prev - 1 + totalPages) % totalPages)
    }
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
            disabled={totalPages <= 1}
          >
            <ChevronLeft className="w-4 h-4" />
          </Button>
          <Button
            variant="ghost"
            size="sm"
            onClick={nextPage}
            className="p-1 h-8 w-8 md:opacity-0 md:hover:opacity-100 transition-opacity"
            disabled={totalPages <= 1}
          >
            <ChevronRight className="w-4 h-4" />
          </Button>
        </div>
      </div>

      {isLoading ? (
        <div className="py-8 flex justify-center items-center">
          <div className="animate-pulse flex flex-col items-center">
            <div className="h-10 w-10 rounded-full bg-orange-200 mb-2"></div>
            <div className="h-4 w-32 bg-orange-100 rounded"></div>
            <div className="mt-2 text-sm text-gray-500">Finding buses near you...</div>
          </div>
        </div>
      ) : nearbyBuses.length === 0 ? (
        <div className="py-8 text-center">
          <MapPin className="w-8 h-8 text-orange-400 mx-auto mb-2" />
          <p className="text-gray-600">No buses found nearby at the moment.</p>
          <p className="text-sm text-gray-500 mt-1">Try again later or change your location.</p>
        </div>
      ) : (
        <div className="relative">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
            {currentBuses.map((bus: any) => (
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
                          <Users className="w-3 h-3 text-gray-200" />
                          <div className={`w-2 h-2 rounded-full ${bus.seatOccupancy.crowdingStatus.color}`}></div>
                          <span className="text-xs text-gray-200">{bus.seatOccupancy.crowdingStatus.status}</span>
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
                          <span className="text-gray-500">Available Seats:</span>
                          <span className="ml-1 font-medium">
                            {bus.seatOccupancy.totalSeats - bus.seatOccupancy.occupiedSeats}
                            <span className="text-gray-400">/{bus.seatOccupancy.totalSeats}</span>
                          </span>
                        </div>
                        <div>
                          <span className="text-gray-500">Driver:</span>
                          <span className="ml-1 font-medium">{bus.driverName}</span>
                        </div>
                        <div>
                          <span className="text-gray-500">ETA:</span>
                          <span className="ml-1 font-medium">{bus.arrivalTime}</span>
                        </div>
                        <div>
                          <span className="text-gray-500">Distance:</span>
                          <span className="ml-1 font-medium">{bus.distance} km</span>
                        </div>
                        <div>
                          <span className="text-gray-500">Last Updated:</span>
                          <span className="ml-1 font-medium">
                            {new Date(bus.seatOccupancy.lastUpdated).toLocaleTimeString()}
                          </span>
                        </div>
                      </div>
                      <div className="flex justify-between items-center text-xs mt-2">
                        {bus.hasWomenConductor && (
                          <div className="text-pink-600">
                            ✓ Women conductor | {bus.womenSeats - bus.seatOccupancy.womenSeatsOccupied} women seats available
                          </div>
                        )}
                        <div className={`flex items-center gap-1 ${bus.seatOccupancy.crowdingStatus.color.replace('bg-', 'text-')}`}>
                          <Users className="w-3 h-3" />
                          <span>{bus.seatOccupancy.crowdingStatus.status}</span>
                        </div>
                      </div>
                    </div>
                  </div>
                )}
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  )
}
