import { BusType } from '@/types/schedule'

export interface Driver {
  id: string
  name: string
  phone: string
  rating: number
  totalTrips: number
  verified: boolean
}

export interface Bus {
  id: string
  route: string
  from: string
  to: string
  departure: string
  arrival: string
  seatsAvailable: number
  totalSeats: number
  speed: string
  hasWomenConductor: boolean
  womenSeats: number
  image: string
  driver: Driver
  type: BusType
  price: string
  busCategory: string
  currentLocation?: {
    lat: number
    lng: number
  }
}

export interface SearchParams {
  from?: string
  to?: string
  busId?: string
  womenOnly?: boolean
  busType?: BusType | 'all'
}

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api'

export async function searchAvailableBuses(params: SearchParams): Promise<Bus[]> {
  try {
    const queryParams = new URLSearchParams()
    
    if (params.from) queryParams.append('from', params.from)
    if (params.to) queryParams.append('to', params.to)
    if (params.busId) queryParams.append('busId', params.busId)
    if (params.womenOnly) queryParams.append('womenOnly', 'true')
    if (params.busType && params.busType !== 'all') queryParams.append('busType', params.busType)

    const response = await fetch(`${BASE_URL}/search/buses?${queryParams.toString()}`)
    if (!response.ok) {
      throw new Error('Failed to fetch buses')
    }

    const data = await response.json()
    return data.buses
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error occurred'
    throw new Error('Failed to search buses: ' + message)
  }
}

export async function getRouteDrivers(route: string): Promise<Driver[]> {
  try {
    const response = await fetch(`${BASE_URL}/search/drivers?route=${encodeURIComponent(route)}`)
    if (!response.ok) {
      throw new Error('Failed to fetch route drivers')
    }

    const data = await response.json()
    return data.drivers
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error occurred'
    throw new Error('Failed to fetch route drivers: ' + message)
  }
}

export async function getNearbyDrivers(lat: number, lng: number, radius: number = 5): Promise<Driver[]> {
  try {
    const response = await fetch(
      `${BASE_URL}/search/nearby-drivers?lat=${lat}&lng=${lng}&radius=${radius}`
    )
    if (!response.ok) {
      throw new Error('Failed to fetch nearby drivers')
    }

    const data = await response.json()
    return data.drivers
  } catch (error) {
    const message = error instanceof Error ? error.message : 'Unknown error occurred'
    throw new Error('Failed to fetch nearby drivers: ' + message)
  }
}