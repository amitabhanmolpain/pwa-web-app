"use client"

import { useState, useEffect } from "react"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Switch } from "@/components/ui/switch"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Search, MapPin, Clock, Users, Navigation, Bus, ArrowRight } from "lucide-react"
import { toast } from "sonner"

interface SearchSectionProps {
  onSearch?: (searchData: any) => void
  onTrackBus?: (busData: any) => void
  searchData?: {
    from: string
    to: string
    busType: string
  }
}

const sampleBuses = [
  {
    id: "KA01-2345",
    route: "Route WF-EC",
    from: "Whitefield",
    to: "Electronic City",
    departure: "07:30",
    arrival: "09:15",
    seatsAvailable: 12,
    totalSeats: 45,
    speed: "45 km/h",
    hasWomenConductor: true,
    womenSeats: 8,
    image: "/bangalore-volvo-bus-orange-grey.jpg",
    driverName: "Rajesh Kumar",
    driverPhone: "+91 98765 43210",
    type: "intercity",
    price: "₹85",
    busCategory: "Intercity Express",
  },
  {
    id: "KA02-6789",
    route: "Route KR-IN",
    from: "Koramangala",
    to: "Indiranagar",
    departure: "08:00",
    arrival: "08:45",
    seatsAvailable: 8,
    totalSeats: 40,
    speed: "35 km/h",
    hasWomenConductor: false,
    womenSeats: 0,
    image: "/bangalore-bmtc-bus-orange-grey.jpg",
    driverName: "Suresh Reddy",
    driverPhone: "+91 98765 43211",
    type: "city",
    price: "₹25",
    busCategory: "City Bus",
  },
  {
    id: "KA03-1234",
    route: "Route MH-SB",
    from: "Marathahalli",
    to: "Silk Board",
    departure: "09:00",
    arrival: "10:30",
    seatsAvailable: 15,
    totalSeats: 50,
    speed: "38 km/h",
    hasWomenConductor: true,
    womenSeats: 12,
    image: "/bangalore-city-express-bus.jpg",
    driverName: "Priya Sharma",
    driverPhone: "+91 98765 43212",
    type: "city",
    price: "₹35",
    busCategory: "City Express",
  },
  {
    id: "KA04-5678",
    route: "Route BS-VJ",
    from: "Banashankari",
    to: "Vijayanagar",
    departure: "10:15",
    arrival: "11:00",
    seatsAvailable: 20,
    totalSeats: 45,
    speed: "40 km/h",
    hasWomenConductor: true,
    womenSeats: 10,
    image: "/bangalore-local-bus.jpg",
    driverName: "Manjunath Gowda",
    driverPhone: "+91 98765 43213",
    type: "city",
    price: "₹30",
    busCategory: "City Route",
  },
  {
    id: "KA05-9012",
    route: "Route HB-YPR",
    from: "Hebbal",
    to: "Yesvantpur",
    departure: "11:30",
    arrival: "12:15",
    seatsAvailable: 25,
    totalSeats: 50,
    speed: "35 km/h",
    hasWomenConductor: false,
    womenSeats: 0,
    image: "/bangalore-ordinary-bus.jpg",
    driverName: "Lakshmi Devi",
    driverPhone: "+91 98765 43214",
    type: "city",
    price: "₹28",
    busCategory: "Local Bus",
  },
  {
    id: "KA06-3456",
    route: "Route JP-MG",
    from: "Jayanagar",
    to: "MG Road",
    departure: "12:00",
    arrival: "12:45",
    seatsAvailable: 18,
    totalSeats: 42,
    speed: "32 km/h",
    hasWomenConductor: true,
    womenSeats: 8,
    image: "/bangalore-city-bus.jpg",
    driverName: "Anitha Rao",
    driverPhone: "+91 98765 43215",
    type: "city",
    price: "₹22",
    busCategory: "City Bus",
  },
  {
    id: "KA07-7890",
    route: "Route RT-KP",
    from: "RT Nagar",
    to: "KR Puram",
    departure: "13:15",
    arrival: "14:30",
    seatsAvailable: 22,
    totalSeats: 48,
    speed: "42 km/h",
    hasWomenConductor: false,
    womenSeats: 0,
    image: "/bangalore-express-bus.jpg",
    driverName: "Venkatesh Murthy",
    driverPhone: "+91 98765 43216",
    type: "intercity",
    price: "₹65",
    busCategory: "Express",
  },
  {
    id: "KA08-2468",
    route: "Route BT-EC",
    from: "BTM Layout",
    to: "Electronic City",
    departure: "14:00",
    arrival: "15:15",
    seatsAvailable: 14,
    totalSeats: 45,
    speed: "38 km/h",
    hasWomenConductor: true,
    womenSeats: 12,
    image: "/bangalore-volvo-bus.jpg",
    driverName: "Kavitha Reddy",
    driverPhone: "+91 98765 43217",
    type: "intercity",
    price: "₹55",
    busCategory: "Volvo AC",
  },
]

export function SearchSection({ onSearch, onTrackBus, searchData }: SearchSectionProps) {
  const [from, setFrom] = useState(searchData?.from || "")
  const [to, setTo] = useState(searchData?.to || "")
  const [busId, setBusId] = useState("")
  const [womenMode, setWomenMode] = useState(false)
  const [busType, setBusType] = useState(searchData?.busType || "all")
  const [searchResults, setSearchResults] = useState<any[]>([])
  const [hasSearched, setHasSearched] = useState(true)

  useEffect(() => {
    if (searchData) {
      setFrom(searchData.from || "")
      setTo(searchData.to || "")
      setBusType(searchData.busType || "all")
      setTimeout(() => {
        handleSearch()
      }, 100)
    } else {
      setSearchResults(sampleBuses)
    }
  }, [searchData])

  const handleSearch = () => {
    const searchParams = {
      from,
      to,
      busId,
      womenMode,
      busType,
    }

    let filteredBuses = sampleBuses

    // More flexible search - partial matches and case insensitive
    if (from.trim()) {
      filteredBuses = filteredBuses.filter(
        (bus) =>
          bus.from.toLowerCase().includes(from.toLowerCase().trim()) ||
          bus.route.toLowerCase().includes(from.toLowerCase().trim()),
      )
    }

    if (to.trim()) {
      filteredBuses = filteredBuses.filter(
        (bus) =>
          bus.to.toLowerCase().includes(to.toLowerCase().trim()) ||
          bus.route.toLowerCase().includes(to.toLowerCase().trim()),
      )
    }

    if (busId.trim()) {
      filteredBuses = filteredBuses.filter(
        (bus) =>
          bus.id.toLowerCase().includes(busId.toLowerCase().trim()) ||
          bus.route.toLowerCase().includes(busId.toLowerCase().trim()) ||
          bus.busCategory.toLowerCase().includes(busId.toLowerCase().trim()),
      )
    }

    if (busType !== "all") {
      filteredBuses = filteredBuses.filter((bus) => bus.type === busType)
    }

    if (womenMode) {
      filteredBuses = filteredBuses.filter((bus) => bus.hasWomenConductor && bus.womenSeats > 0)
    }

    setSearchResults(filteredBuses)
    setHasSearched(true)
    onSearch?.(searchParams)
  }

  const handleTrackBus = (bus: any) => {
    toast.success(`🚌 Now tracking ${bus.route}`, {
      description: `${bus.from} → ${bus.to} • ${bus.busCategory} • Speed: ${bus.speed} • ${bus.seatsAvailable}/${bus.totalSeats} seats • Price: ${bus.price}`,
      duration: 5000,
    })
    onTrackBus?.(bus)
  }

  const getBusTypeColor = (type: string) => {
    switch (type) {
      case "intercity":
        return "bg-blue-100 text-blue-800"
      case "city":
        return "bg-green-100 text-green-800"
      case "village":
        return "bg-purple-100 text-purple-800"
      default:
        return "bg-gray-100 text-gray-800"
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-orange-50 to-white px-4 py-6 sm:px-6 lg:px-8">
      <div className="max-w-4xl mx-auto space-y-6">
        <div className="text-center space-y-4 py-8 sm:py-12 bg-white rounded-2xl border border-gray-100 shadow-lg">
          <div className="flex items-center justify-center mb-6">
            <div className="bg-gradient-to-r from-orange-500 to-orange-600 rounded-full p-4 shadow-lg">
              <Search className="w-8 h-8 text-white" />
            </div>
          </div>
          <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold text-gray-900 text-balance">Find Your Bus</h1>
          <p className="text-gray-600 text-sm sm:text-base max-w-2xl mx-auto px-4 text-pretty">
            Search for buses across intercity, city, and village routes with real-time availability
          </p>
        </div>

        <Card className="border-0 shadow-xl bg-white/80 backdrop-blur-sm">
          <CardContent className="p-4 sm:p-6 lg:p-8 space-y-6">
            <div className="grid grid-cols-1 gap-4 sm:gap-6">
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 sm:gap-6">
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-gray-700 flex items-center">
                    <MapPin className="w-4 h-4 mr-2 text-orange-500" />
                    From
                  </label>
                  <Input
                    placeholder="Enter starting location"
                    value={from}
                    onChange={(e) => setFrom(e.target.value)}
                    className="h-12 border-gray-200 focus:border-orange-500 focus:ring-orange-500 text-base"
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-semibold text-gray-700 flex items-center">
                    <MapPin className="w-4 h-4 mr-2 text-orange-500" />
                    To
                  </label>
                  <Input
                    placeholder="Enter destination"
                    value={to}
                    onChange={(e) => setTo(e.target.value)}
                    className="h-12 border-gray-200 focus:border-orange-500 focus:ring-orange-500 text-base"
                  />
                </div>
              </div>

              <div className="space-y-2">
                <label className="text-sm font-semibold text-gray-700 flex items-center">
                  <Bus className="w-4 h-4 mr-2 text-orange-500" />
                  Bus ID (Optional)
                </label>
                <Input
                  placeholder="Enter specific bus ID or route number"
                  value={busId}
                  onChange={(e) => setBusId(e.target.value)}
                  className="h-12 border-gray-200 focus:border-orange-500 focus:ring-orange-500 text-base"
                />
              </div>

              <div className="space-y-2">
                <label className="text-sm font-semibold text-gray-700">Bus Type</label>
                <Select value={busType} onValueChange={setBusType}>
                  <SelectTrigger className="h-12 border-gray-200 focus:border-orange-500 text-base">
                    <SelectValue placeholder="Select bus type" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="all">All Types</SelectItem>
                    <SelectItem value="intercity">Intercity</SelectItem>
                    <SelectItem value="city">City</SelectItem>
                    <SelectItem value="village">Villages</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <Button
                onClick={handleSearch}
                className="w-full h-14 bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white font-semibold text-lg rounded-xl shadow-lg transition-all duration-200 transform hover:scale-[1.02]"
              >
                <Search className="w-5 h-5 mr-3" />
                Search Buses
              </Button>

              <div className="bg-gradient-to-r from-orange-50 to-pink-50 p-4 sm:p-6 rounded-xl border border-orange-100">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                  <div className="flex-1">
                    <h3 className="font-semibold text-gray-900 flex items-center text-base sm:text-lg">👩 For Women</h3>
                    <p className="text-sm text-gray-600 mt-1 text-pretty">
                      Find buses with women conductors and reserved seats for women passengers
                    </p>
                  </div>
                  <Switch
                    checked={womenMode}
                    onCheckedChange={setWomenMode}
                    className="data-[state=checked]:bg-orange-500 self-start sm:self-center"
                  />
                </div>

                {womenMode && (
                  <div className="mt-4 p-3 bg-white rounded-lg border border-orange-200">
                    <p className="text-sm text-orange-800">
                      <strong>Women Mode Active:</strong> Showing only buses with women conductors and reserved seats
                    </p>
                  </div>
                )}
              </div>
            </div>
          </CardContent>
        </Card>

        <div className="space-y-4 sm:space-y-6">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 sm:gap-4">
            <h3 className="text-xl sm:text-2xl font-bold text-gray-900">
              {hasSearched && (from || to || busId) ? "Search Results" : "Available Buses"}
            </h3>
            <Badge variant="secondary" className="bg-orange-100 text-orange-800 px-3 py-1 self-start sm:self-center">
              {searchResults.length} buses found
            </Badge>
          </div>

          {searchResults.length > 0 ? (
            <div className="space-y-4">
              {searchResults.map((bus) => (
                <Card
                  key={bus.id}
                  className="border-0 shadow-lg hover:shadow-xl transition-all duration-200 bg-white overflow-hidden"
                >
                  <CardContent className="p-4 sm:p-6">
                    <div className="space-y-4">
                      {/* Header with badges */}
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge className="bg-orange-500 text-white px-3 py-1 font-semibold text-sm">{bus.route}</Badge>
                        <Badge variant="outline" className="text-gray-600 text-sm">
                          {bus.id}
                        </Badge>
                        <Badge className={`${getBusTypeColor(bus.type)} text-sm`}>{bus.busCategory}</Badge>
                        {bus.hasWomenConductor && (
                          <Badge className="bg-pink-100 text-pink-800 text-xs">✓ Women conductor</Badge>
                        )}
                      </div>

                      {/* Route and timing */}
                      <div className="space-y-3">
                        <div className="flex items-center justify-between">
                          <div className="flex items-center space-x-2 flex-1 min-w-0">
                            <MapPin className="w-4 h-4 text-orange-500 flex-shrink-0" />
                            <span className="font-medium text-gray-900 truncate">{bus.from}</span>
                            <ArrowRight className="w-4 h-4 text-gray-400 flex-shrink-0" />
                            <span className="font-medium text-gray-900 truncate">{bus.to}</span>
                          </div>
                        </div>

                        <div className="flex items-center space-x-2 text-gray-600">
                          <Clock className="w-4 h-4 text-orange-500 flex-shrink-0" />
                          <span className="text-sm">
                            {bus.departure} - {bus.arrival}
                          </span>
                        </div>
                      </div>

                      {/* Details grid */}
                      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
                        <div className="flex items-center space-x-1 text-green-600">
                          <Users className="w-4 h-4 flex-shrink-0" />
                          <span className="font-medium truncate">
                            {bus.seatsAvailable}/{bus.totalSeats}
                          </span>
                        </div>
                        <div className="text-blue-600 font-medium truncate">{bus.speed}</div>
                        <div className="text-orange-600 font-bold text-lg">{bus.price}</div>
                        {womenMode && bus.womenSeats > 0 && (
                          <div className="text-pink-600 font-medium text-sm">👩 {bus.womenSeats} seats</div>
                        )}
                      </div>

                      {/* Action button */}
                      <Button
                        onClick={() => handleTrackBus(bus)}
                        className="w-full sm:w-auto bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white px-6 py-3 rounded-lg font-semibold transition-all duration-200"
                      >
                        <Navigation className="w-4 h-4 mr-2" />
                        Track Bus
                      </Button>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : (
            <Card className="border-0 shadow-lg bg-gray-50">
              <CardContent className="text-center py-12">
                <div className="w-16 h-16 bg-gray-200 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Search className="w-8 h-8 text-gray-400" />
                </div>
                <h3 className="text-lg font-semibold text-gray-900 mb-2">No buses found</h3>
                <p className="text-gray-600 text-sm sm:text-base px-4 text-pretty">
                  Try adjusting your search parameters or check different routes
                </p>
              </CardContent>
            </Card>
          )}
        </div>
      </div>
    </div>
  )
}
