"use client"

import { useState, useEffect } from "react"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Bus, MapPin, Clock, Users, AlertCircle, Navigation } from "lucide-react"

interface BusData {
  id: string
  route: string
  currentLocation: string
  nextStop: string
  estimatedArrival: string
  capacity: "Low" | "Medium" | "High"
  delay: number
  passengers: number
  maxCapacity: number
}

const mockBusData: BusData[] = [
  {
    id: "PB-45A-001",
    route: "Chandigarh - Mohali",
    currentLocation: "Sector 17, Chandigarh",
    nextStop: "IT Park, Mohali",
    estimatedArrival: "3 min",
    capacity: "Low",
    delay: 0,
    passengers: 15,
    maxCapacity: 50,
  },
  {
    id: "PB-12B-002",
    route: "Ludhiana - Jalandhar",
    currentLocation: "Civil Lines, Ludhiana",
    nextStop: "Bus Stand, Jalandhar",
    estimatedArrival: "7 min",
    capacity: "High",
    delay: 5,
    passengers: 48,
    maxCapacity: 50,
  },
  {
    id: "PB-23C-003",
    route: "Amritsar - Patiala",
    currentLocation: "Golden Temple, Amritsar",
    nextStop: "Railway Station, Patiala",
    estimatedArrival: "12 min",
    capacity: "Medium",
    delay: 2,
    passengers: 32,
    maxCapacity: 50,
  },
]

export function LiveTracking() {
  const [buses, setBuses] = useState<BusData[]>(mockBusData)
  const [selectedBus, setSelectedBus] = useState<string | null>(null)

  useEffect(() => {
    // Simulate real-time updates
    const interval = setInterval(() => {
      setBuses((prevBuses) =>
        prevBuses.map((bus) => ({
          ...bus,
          estimatedArrival: `${Math.max(1, Number.parseInt(bus.estimatedArrival) - 1)} min`,
          passengers: Math.min(bus.maxCapacity, bus.passengers + Math.floor(Math.random() * 3) - 1),
        })),
      )
    }, 10000)

    return () => clearInterval(interval)
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

  const getCapacityText = (passengers: number, maxCapacity: number) => {
    const percentage = (passengers / maxCapacity) * 100
    if (percentage < 30) return "Low"
    if (percentage < 70) return "Medium"
    return "High"
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h2 className="text-xl font-semibold text-foreground">Live Bus Tracking</h2>
        <Badge variant="secondary" className="bg-green-100 text-green-800">
          <div className="w-2 h-2 bg-green-500 rounded-full mr-1 animate-pulse"></div>
          Live
        </Badge>
      </div>

      <div className="space-y-3">
        {buses.map((bus) => {
          const capacity = getCapacityText(bus.passengers, bus.maxCapacity)
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
                      {bus.delay > 0 && <AlertCircle className="w-3 h-3 text-red-500" />}
                    </div>
                    <Badge variant="secondary" className="text-xs">
                      <div className={`w-2 h-2 rounded-full ${getCapacityColor(capacity)} mr-1`}></div>
                      {capacity}
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

                    <div className="flex items-center justify-between">
                      <div className="flex items-center space-x-2">
                        <Users className="w-4 h-4 text-muted-foreground" />
                        <span className="text-sm">
                          {bus.passengers}/{bus.maxCapacity} passengers
                        </span>
                      </div>
                      {bus.delay > 0 && (
                        <Badge variant="destructive" className="text-xs">
                          {bus.delay} min delay
                        </Badge>
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
    </div>
  )
}
