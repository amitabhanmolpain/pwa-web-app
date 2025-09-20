"use client"

import { useState, useEffect, type ChangeEvent } from "react"
import { searchAvailableBuses } from "@/lib/api/search"
import type { Bus as BusData, SearchParams } from "@/lib/api/search"
import { toast } from "@/components/ui/use-toast"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Switch } from "@/components/ui/switch"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Search, MapPin, Clock, Users, Navigation, Bus, ArrowRight, Loader2 } from "lucide-react"
import { subscribeToLocationSocket, subscribeToLocationUpdates } from "@/lib/api/tracking"

type BusCategory = "intercity" | "city" | "village" | "all";

interface Bus extends BusData {
  driverName: string;
  driverPhone: string;
}

interface SearchSectionProps {
  onSearch?: (searchData: SearchParams) => void
  onTrackBus?: (busData: Bus) => void
  searchData?: {
    from: string
    to: string
    busType: BusCategory
  }
}

export function SearchSection({ onSearch, onTrackBus, searchData }: SearchSectionProps) {
  const [from, setFrom] = useState("")
  const [to, setTo] = useState("")
  const [busId, setBusId] = useState("")
  const [womenMode, setWomenMode] = useState(false)
  const [busType, setBusType] = useState<BusCategory>(searchData?.busType as BusCategory || "all")
  const [searchResults, setSearchResults] = useState<Bus[]>([])
  const [liveLocations, setLiveLocations] = useState<Record<string, { latitude: number; longitude: number; station?: string }>>({})
  const [hasSearched, setHasSearched] = useState(true)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState("")

  useEffect(() => {
    if (searchData) {
      setFrom(searchData.from || "")
      setTo(searchData.to || "")
      setBusType(searchData.busType as BusCategory || "all")
      handleSearch()
    }
  }, [searchData])

  const handleSearch = async () => {
    const searchParams: SearchParams = {
      from,
      to,
      busId: busId || undefined,
      womenMode,
      busType: busType === "all" ? undefined : busType as unknown as "intercity" | "city" | "village",
    }

    setIsLoading(true)
    setError("")

    try {
      const buses = await searchAvailableBuses(searchParams)
      // Add mock driver info until backend provides it
      const busesWithDriverInfo = buses.map(bus => ({
        ...bus,
        driverName: "Mock Driver",
        driverPhone: "+91 00000 00000",
      }))
      setSearchResults(busesWithDriverInfo)
      setHasSearched(true)
      onSearch?.(searchParams)
    } catch (error) {
      setError("Failed to fetch buses. Please try again.")
      setSearchResults([])
      toast({
        variant: "destructive",
        description: "Failed to fetch buses. Please try again."
      })
    } finally {
      setIsLoading(false)
    }
  }

  const handleTrackBus = (bus: Bus) => {
    toast({
      description: `🚌 Now tracking ${bus.route} from ${bus.from} to ${bus.to}`
    })
    onTrackBus?.(bus)
  }

  // Subscribe to live locations when search results change. For each bus, try socket subscription
  useEffect(() => {
    if (!searchResults || searchResults.length === 0) return

    const cleanups: Array<() => void> = []

    searchResults.forEach((bus) => {
      const params = { busId: bus.id }

      // Try socket subscription first
      const cleanupSocket = subscribeToLocationSocket(
        params,
        (location) => {
          setLiveLocations((prev) => ({
            ...prev,
            [bus.id]: { latitude: location.latitude, longitude: location.longitude, station: location.currentLocation }
          }))
        },
        (err) => {
          // If socket fails, fall back to polling subscription
          const pollCleanup = subscribeToLocationUpdates(
            params,
            (location) => {
              setLiveLocations((prev) => ({
                ...prev,
                [bus.id]: { latitude: location.latitude, longitude: location.longitude, station: location.currentLocation }
              }))
            },
            (err) => {
              console.error('Location subscription error for bus', bus.id, err)
            }
          )
          cleanups.push(pollCleanup)
        }
      )

      cleanups.push(cleanupSocket)
    })

    return () => {
      cleanups.forEach((fn) => fn())
    }
  }, [searchResults])

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
                    onChange={(e: ChangeEvent<HTMLInputElement>) => setFrom(e.target.value)}
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
                    onChange={(e: ChangeEvent<HTMLInputElement>) => setTo(e.target.value)}
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
                  onChange={(e: ChangeEvent<HTMLInputElement>) => setBusId(e.target.value)}
                  className="h-12 border-gray-200 focus:border-orange-500 focus:ring-orange-500 text-base"
                />
              </div>

              <div className="space-y-2">
                <label className="text-sm font-semibold text-gray-700">Bus Type</label>
                <Select 
                  value={busType} 
                  onValueChange={(value: string) => setBusType(value as BusCategory)}
                >
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
                disabled={isLoading}
                className="w-full h-14 bg-gradient-to-r from-orange-500 to-orange-600 hover:from-orange-600 hover:to-orange-700 text-white font-semibold text-lg rounded-xl shadow-lg transition-all duration-200 transform hover:scale-[1.02]"
              >
                {isLoading ? (
                  <>
                    <Loader2 className="w-5 h-5 mr-3 animate-spin" />
                    Searching...
                  </>
                ) : (
                  <>
                    <Search className="w-5 h-5 mr-3" />
                    Search Buses
                  </>
                )}
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

          {error ? (
            <Card className="border-0 shadow-lg bg-red-50">
              <CardContent className="text-center py-12">
                <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
                  <Search className="w-8 h-8 text-red-400" />
                </div>
                <h3 className="text-lg font-semibold text-red-900 mb-2">Error</h3>
                <p className="text-red-600 text-sm sm:text-base px-4 text-pretty">{error}</p>
              </CardContent>
            </Card>
          ) : searchResults.length > 0 ? (
            <div className="space-y-4">
              {searchResults.map((bus) => (
                <Card
                  key={bus.id}
                  className="border-0 shadow-lg hover:shadow-xl transition-all duration-200 bg-white overflow-hidden"
                >
                  <CardContent className="p-4 sm:p-6">
                    <div className="space-y-4">
                      <div className="flex flex-wrap items-center gap-2">
                        <Badge className="bg-orange-500 text-white px-3 py-1 font-semibold text-sm">{bus.route}</Badge>
                        <Badge variant="outline" className="text-gray-600 text-sm">
                          {bus.id}
                        </Badge>
                        <Badge className={`${getBusTypeColor(bus.type)} text-sm`}>{bus.type}</Badge>
                        {bus.hasWomenConductor && (
                          <Badge className="bg-pink-100 text-pink-800 text-xs">✓ Women conductor</Badge>
                        )}
                      </div>

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

                      {/* Live location preview (if available) */}
                      {liveLocations[bus.id] && (
                        <div className="mt-3 text-sm text-gray-700">
                          <div className="flex items-center gap-3">
                            <span className="font-medium">Live:</span>
                            <span>Lat: {liveLocations[bus.id].latitude.toFixed(5)}</span>
                            <span>Lng: {liveLocations[bus.id].longitude.toFixed(5)}</span>
                            {liveLocations[bus.id].station && (
                              <span className="text-gray-500">• {liveLocations[bus.id].station}</span>
                            )}
                          </div>
                        </div>
                      )}

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