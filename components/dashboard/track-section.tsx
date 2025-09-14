"use client"
import { useEffect, useState } from "react"
import { MapPin, Phone, User, Bus, Navigation2 } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { MapView } from "@/components/dashboard/map-view"
import { toast } from "@/hooks/use-toast"

interface TrackSectionProps {
  busData?: any
}

export function TrackSection({ busData }: TrackSectionProps) {
  const [currentLocation, setCurrentLocation] = useState({ lat: 12.9716, lng: 77.5946 })
  const [busLocation, setBusLocation] = useState({ lat: 12.9716, lng: 77.5946 })
  const [currentSpeed, setCurrentSpeed] = useState(25)
  const [estimatedTime, setEstimatedTime] = useState("45 mins")

  useEffect(() => {
    if (!busData) return

    const calculateEstimatedTime = () => {
      const routeDistances: { [key: string]: number } = {
        "Koramangala-Whitefield": 25,
        "Whitefield-Electronic City": 35,
        "Banashankari-Vijayanagar": 15,
        "Koramangala-Indiranagar": 8,
        "Marathahalli-Silk Board": 20,
        "Hebbal-Yesvantpur": 12,
      }

      const routeKey = `${busData.from}-${busData.to}`
      const distance = routeDistances[routeKey] || 20
      const avgSpeed = 30 // km/h average in Bangalore traffic
      const timeInHours = distance / avgSpeed
      const timeInMinutes = Math.round(timeInHours * 60)

      return `${timeInMinutes} mins`
    }

    const estimatedTime = calculateEstimatedTime()
    setEstimatedTime(estimatedTime)

    toast({
      title: "🚌 Bus Tracking Started",
      description: `Now tracking ${busData.route} from ${busData.from} to ${busData.to}. Speed: ${currentSpeed} km/h, Seats: ${busData.seatsAvailable}, ETA: ${estimatedTime}`,
    })

    const interval = setInterval(() => {
      setBusLocation((prev) => ({
        lat: prev.lat + (Math.random() - 0.5) * 0.001,
        lng: prev.lng + (Math.random() - 0.5) * 0.001,
      }))

      setCurrentSpeed(Math.floor(Math.random() * 45 + 15))
    }, 1500) // Update every 1.5 seconds for rapid changes

    return () => clearInterval(interval)
  }, [busData])

  if (!busData) {
    return (
      <div className="p-4 text-center">
        <p className="text-gray-500">Select a bus to track</p>
      </div>
    )
  }

  const getBusTypeColor = (type: string) => {
    return "bg-orange-100 text-orange-800"
  }

  const getBusCategory = (route?: string) => {
    if (!route) return "City Bus"

    if (busData.destination?.includes("Electronic City") || busData.destination?.includes("Whitefield")) {
      return "Intercity Express"
    } else if (busData.destination?.includes("Village") || busData.route?.includes("Village")) {
      return "Village Route"
    } else {
      return "City to City"
    }
  }

  const getApproximatePrice = () => {
    const category = getBusCategory(busData.route)
    switch (category) {
      case "Intercity Express":
        return "₹45-65"
      case "Village Route":
        return "₹15-25"
      default:
        return "₹20-35"
    }
  }

  return (
    <div className="space-y-6 p-4 max-w-4xl mx-auto">
      <Card className="border-orange-200">
        <CardHeader className="bg-gradient-to-r from-orange-500 to-orange-600 text-white">
          <div className="flex items-center justify-between">
            <div>
              <CardTitle className="text-xl font-bold">{busData.route}</CardTitle>
              <p className="text-orange-100 text-sm">
                From: {busData.from} → To: {busData.to}
              </p>
            </div>
            <div className="flex items-center space-x-2">
              <div className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></div>
              <span className="text-sm">Live Tracking</span>
            </div>
          </div>
        </CardHeader>
        <CardContent className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <div className="flex items-center space-x-3">
                <MapPin className="w-5 h-5 text-orange-500" />
                <div>
                  <p className="font-semibold text-gray-900">
                    {busData.from} → {busData.to}
                  </p>
                  <p className="text-sm text-gray-600">Route Information</p>
                </div>
              </div>
              <div className="flex items-center space-x-3">
                <Badge className={getBusTypeColor("default")}>{getBusCategory(busData.route)}</Badge>
              </div>
            </div>
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="text-center p-3 bg-orange-50 rounded-lg border border-orange-200">
                  <div className="text-lg font-bold text-orange-600">{currentSpeed} km/h</div>
                  <div className="text-xs text-gray-600">Current Speed</div>
                </div>
                <div className="text-center p-3 bg-orange-50 rounded-lg border border-orange-200">
                  <div className="text-lg font-bold text-orange-600">{estimatedTime}</div>
                  <div className="text-xs text-gray-600">Estimated Time</div>
                </div>
              </div>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card className="border-orange-200">
        <CardHeader>
          <CardTitle className="flex items-center text-gray-900">
            <Navigation2 className="w-5 h-5 mr-2 text-orange-500" />
            Live Location Tracking
          </CardTitle>
        </CardHeader>
        <CardContent className="p-0">
          <div className="h-80">
            <MapView trackingBus={busData} showNearbyBuses={false} />
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <Card className="border-orange-200">
          <CardHeader>
            <CardTitle className="flex items-center text-gray-900">
              <Bus className="w-5 h-5 mr-2 text-orange-500" />
              Bus Details
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">ETA</span>
                <span className="font-medium text-gray-900">{estimatedTime}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Current Speed</span>
                <span className="font-medium text-gray-900">{currentSpeed} km/h</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Available Seats</span>
                <span className="font-medium text-gray-900">{busData.seatsAvailable}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Approximate Price</span>
                <span className="font-bold text-orange-600">{getApproximatePrice()}</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm text-gray-600">Bus Category</span>
                <Badge className={getBusTypeColor("default")}>{getBusCategory(busData.route)}</Badge>
              </div>
            </div>

            {busData.womenSeats > 0 && (
              <div className="bg-orange-50 p-3 rounded-lg border border-orange-200">
                <p className="text-sm text-orange-800">
                  <strong>Women Reserved Seats:</strong> {busData.womenSeats} available
                </p>
                {busData.hasWomenConductor && (
                  <p className="text-xs text-orange-600 mt-1">✓ Women conductor available</p>
                )}
              </div>
            )}
          </CardContent>
        </Card>

        <Card className="border-orange-200">
          <CardHeader>
            <CardTitle className="flex items-center text-gray-900">
              <User className="w-5 h-5 mr-2 text-orange-500" />
              Driver Information
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-3">
              <div className="flex items-center space-x-3">
                <User className="w-5 h-5 text-gray-500" />
                <div>
                  <p className="font-medium text-gray-900">{busData.driverName}</p>
                  <p className="text-sm text-gray-600">Driver</p>
                </div>
              </div>
              <div className="flex items-center space-x-3">
                <Phone className="w-5 h-5 text-orange-500" />
                <div>
                  <p className="font-medium text-gray-900">{busData.driverPhone}</p>
                  <p className="text-sm text-gray-600">Contact Number</p>
                </div>
              </div>
            </div>

            <div className="bg-orange-50 p-3 rounded-lg border border-orange-200">
              <p className="text-sm text-orange-800">
                <strong>Emergency Contact:</strong> Available 24/7 for passenger assistance
              </p>
            </div>
          </CardContent>
        </Card>
      </div>

      <Card className="border-orange-200">
        <CardContent className="p-0">
          <div className="relative h-48 rounded-lg overflow-hidden">
            <img
              src={busData.image || "/placeholder.svg?height=200&width=400&query=orange bus"}
              alt={`${busData.route} bus`}
              className="w-full h-full object-cover"
            />
            <div className="absolute top-4 left-4 bg-black text-white px-3 py-1 rounded-full">
              <span className="font-semibold">{busData.route}</span>
            </div>
            <div className="absolute top-4 right-4 bg-orange-500 text-white px-2 py-1 rounded-full text-xs">
              <div className="flex items-center space-x-1">
                <div className="w-1.5 h-1.5 bg-white rounded-full animate-pulse"></div>
                <span>Live</span>
              </div>
            </div>
            <div className="absolute bottom-4 left-4 bg-orange-500 text-white px-3 py-1 rounded-full text-sm font-medium">
              {getBusCategory(busData.route)}
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  )
}
