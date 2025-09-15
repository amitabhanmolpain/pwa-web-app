"use client"

import { useState, useEffect } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Bus, MapPin, Clock, Users, AlertCircle, Navigation, Loader2 } from "lucide-react"
import { toast } from "@/components/ui/use-toast"
import { getDriverLocation, getBusStatus, subscribeToLocationUpdates } from "@/lib/api/tracking"
import type { BusStatus, DriverLocation } from "@/lib/api/tracking"

interface BusData extends BusStatus {
  id: string
  route: string
  location?: DriverLocation
  capacity: "Low" | "Medium" | "High"
}

// Initial mock data, will be replaced with API data
const mockBusData: BusData[] = [
  {
    id: "PB-45A-001",
    busId: "PB-45A-001",
    route: "Chandigarh - Mohali",
    status: "on-time",
    currentLocation: "Sector 17, Chandigarh",
    nextStop: "IT Park, Mohali",
    estimatedArrival: "3 min",
    occupancy: 15,
    totalCapacity: 50,
    capacity: "Low",
    speed: 35,
    trafficCondition: "light",
    weatherCondition: "Clear"
  },
  {
    id: "PB-12B-002",
    busId: "PB-12B-002",
    route: "Ludhiana - Jalandhar",
    status: "delayed",
    delay: 5,
    currentLocation: "Civil Lines, Ludhiana",
    nextStop: "Bus Stand, Jalandhar",
    estimatedArrival: "7 min",
    occupancy: 48,
    totalCapacity: 50,
    capacity: "High",
    speed: 40,
    trafficCondition: "moderate",
    weatherCondition: "Cloudy"
  },
  {
    id: "PB-23C-003",
    busId: "PB-23C-003",
    route: "Amritsar - Patiala",
    status: "delayed",
    delay: 2,
    currentLocation: "Golden Temple, Amritsar",
    nextStop: "Railway Station, Patiala",
    estimatedArrival: "12 min",
    occupancy: 32,
    totalCapacity: 50,
    capacity: "Medium",
    speed: 45,
    trafficCondition: "light",
    weatherCondition: "Clear"
  },
]

export function LiveTracking() {
  const [buses, setBuses] = useState<BusData[]>(mockBusData)
  const [selectedBus, setSelectedBus] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    const fetchInitialData = async () => {
      try {
        setIsLoading(true)
        setError(null)

        const busPromises = mockBusData.map(async (bus) => {
          const [status, location] = await Promise.all([
            getBusStatus(bus.busId),
            getDriverLocation({ busId: bus.busId })
          ])

          return {
            ...status,
            id: bus.busId,
            route: bus.route,
            location,
            capacity: getCapacityText(status.occupancy, status.totalCapacity)
          }
        })

        const updatedBuses = await Promise.all(busPromises)
        setBuses(updatedBuses)
      } catch (err) {
        setError('Failed to fetch bus data')
        toast({
          variant: "destructive",
          description: "Failed to fetch bus data. Please try again later."
        })
      } finally {
        setIsLoading(false)
      }
    }

    fetchInitialData()

    // Set up real-time location updates for all buses
    const cleanupFunctions = mockBusData.map(bus => {
      return subscribeToLocationUpdates(
        { busId: bus.busId },
        (location) => {
          setBuses(prev => prev.map(b => 
            b.busId === bus.busId 
              ? { 
                  ...b, 
                  location,
                  currentLocation: location.currentLocation,
                  nextStop: location.nextStop,
                  estimatedArrival: location.estimatedArrival 
                }
              : b
          ))
        },
        (error) => {
          console.error('Error updating location for bus:', bus.busId, error)
          toast({
            variant: "destructive",
            description: `Lost connection to bus ${bus.id}. Trying to reconnect...`
          })
        }
      )
    })

    return () => {
      cleanupFunctions.forEach(cleanup => cleanup())
    }
  }, [])

  const getCapacityColor = (capacity: string) => {
    switch (capacity) {
      case "Low":
        return "bg-green-500"
      case "Medium":
        return "bg-yellow-500"
      case "High":
        return "bg-red-500"
      default:
        return "bg-gray-500"
    }
  }

  const getCapacityText = (occupancy: number, totalCapacity: number): "Low" | "Medium" | "High" => {
    const percentage = (occupancy / totalCapacity) * 100
    if (percentage < 30) return "Low"
    if (percentage < 70) return "Medium"
    return "High"
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold text-foreground">Live Bus Tracking</h2>
        <Badge variant="secondary" className={`${isLoading ? "bg-yellow-100 text-yellow-800" : "bg-green-100 text-green-800"}`}>
          <div className={`w-2 h-2 rounded-full mr-1 animate-pulse ${isLoading ? "bg-yellow-500" : "bg-green-500"}`}></div>
          {isLoading ? "Connecting" : "Live"}
        </Badge>
      </div>

      {error ? (
        <Card className="border-0 shadow-lg bg-red-50">
          <CardContent className="text-center py-12">
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <AlertCircle className="w-8 h-8 text-red-500" />
            </div>
            <h3 className="text-lg font-semibold text-red-900 mb-2">Connection Error</h3>
            <p className="text-red-600 text-sm sm:text-base px-4 text-pretty">{error}</p>
            <Button 
              onClick={() => window.location.reload()} 
              variant="outline" 
              className="mt-4 bg-white hover:bg-red-50"
            >
              Retry Connection
            </Button>
          </CardContent>
        </Card>
      ) : (
        <div className="space-y-3">
          {buses.map((bus) => {
            const speed = bus.location?.speed || bus.speed
            const weather = bus.location?.weatherCondition || bus.weatherCondition
            return (
              <Card
                key={bus.id}
                className={`shadow-sm cursor-pointer transition-all ${
                  selectedBus === bus.id ? "ring-2 ring-primary" : ""
                }`}
                onClick={() => setSelectedBus(selectedBus === bus.id ? null : bus.id)}
              >
                <CardContent className="p-4">
                  <div className="flex items-center justify-between mb-3">
                    <div className="flex items-center space-x-3">
                      <div className="bg-primary/10 rounded-full p-2">
                        <Bus className="w-5 h-5 text-primary" />
                      </div>
                      <div>
                        <p className="font-medium text-card-foreground">{bus.route}</p>
                        <p className="text-sm text-muted-foreground">{bus.id}</p>
                      </div>
                    </div>
                    <div className="text-right">
                      <div className="flex items-center space-x-1 mb-1">
                        <Clock className="w-3 h-3 text-muted-foreground" />
                        <span className="text-sm font-medium">{bus.estimatedArrival}</span>
                        {bus.status === "delayed" && bus.delay && bus.delay > 0 && (
                          <AlertCircle className="w-3 h-3 text-red-500" />
                        )}
                      </div>
                      <Badge variant="secondary" className="text-xs">
                        <div className={`w-2 h-2 rounded-full ${getCapacityColor(bus.capacity)} mr-1`}></div>
                        {bus.capacity}
                      </Badge>
                    </div>
                  </div>

                  {selectedBus === bus.id && (
                    <div className="border-t pt-3 space-y-3">
                      <div className="grid grid-cols-2 gap-4 text-sm">
                        <div className="flex items-center space-x-2">
                          <MapPin className="w-4 h-4 text-muted-foreground" />
                          <div>
                            <p className="text-muted-foreground">Current Location</p>
                            <p className="font-medium">{bus.currentLocation}</p>
                          </div>
                        </div>
                        <div className="flex items-center space-x-2">
                          <Navigation className="w-4 h-4 text-muted-foreground" />
                          <div>
                            <p className="text-muted-foreground">Next Stop</p>
                            <p className="font-medium">{bus.nextStop}</p>
                          </div>
                        </div>
                      </div>

                      <div className="flex flex-wrap items-center justify-between gap-2">
                        <div className="flex items-center space-x-2">
                          <Users className="w-4 h-4 text-muted-foreground" />
                          <span className="text-sm">
                            {bus.occupancy}/{bus.totalCapacity} passengers
                          </span>
                        </div>
                        {bus.status === "delayed" && bus.delay && bus.delay > 0 && (
                          <Badge variant="destructive" className="text-xs">
                            {bus.delay} min delay
                          </Badge>
                        )}
                      </div>

                      <div className="grid grid-cols-2 gap-2 text-sm text-muted-foreground">
                        <div className="flex items-center space-x-1">
                          <Navigation className="w-3 h-3" />
                          <span>{speed} km/h</span>
                        </div>
                        {weather && (
                          <div className="flex items-center space-x-1">
                            <Clock className="w-3 h-3" />
                            <span>{weather}</span>
                          </div>
                        )}
                      </div>

                      <div className="flex space-x-2">
                        <Button size="sm" variant="outline" className="flex-1 bg-transparent">
                          Set Alert
                        </Button>
                        <Button size="sm" className="flex-1">
                          Track on Map
                        </Button>
                      </div>
                    </div>
                  )}
                </CardContent>
              </Card>
            )
          })}
        </div>
      )}
    </div>
  )
}
