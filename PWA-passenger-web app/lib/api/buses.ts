import { BusData, SeatOccupancyData } from "@/types/buses"

export async function getNearbyBuses(lat: number, lng: number, radius: number = 2): Promise<BusData[]> {
  try {
    const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/buses/nearby?lat=${lat}&lng=${lng}&radius=${radius}`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      throw new Error('Failed to fetch nearby buses')
    }

    const data = await response.json()
    return data
  } catch (error) {
    console.error('Error fetching nearby buses:', error)
    return []
  }
}

export async function getBusSeatOccupancy(busId: string): Promise<SeatOccupancyData> {
  try {
    const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/buses/${busId}/occupancy`, {
      method: 'GET',
      headers: {
        'Content-Type': 'application/json',
      },
    })

    if (!response.ok) {
      throw new Error('Failed to fetch bus occupancy data')
    }

    const data = await response.json()
    return data
  } catch (error) {
    console.error('Error fetching bus occupancy:', error)
    return {
      busId: '',
      totalSeats: 0,
      occupiedSeats: 0,
      womenSeatsOccupied: 0,
      lastUpdated: new Date().toISOString(),
    }
  }
}

export async function updateBusSeatOccupancy(
  busId: string, 
  data: Partial<SeatOccupancyData>
): Promise<SeatOccupancyData> {
  try {
    const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/buses/${busId}/occupancy`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(data),
    })

    if (!response.ok) {
      throw new Error('Failed to update bus occupancy data')
    }

    return await response.json()
  } catch (error) {
    console.error('Error updating bus occupancy:', error)
    throw error
  }
}

export function calculateCrowdingStatus(occupancyData: SeatOccupancyData): {
  status: 'Available' | 'Half Full' | 'Nearly Full' | 'Crowded',
  color: string
} {
  const occupancyPercentage = (occupancyData.occupiedSeats / occupancyData.totalSeats) * 100

  if (occupancyPercentage <= 25) {
    return { status: 'Available', color: 'bg-green-500' }
  } else if (occupancyPercentage <= 50) {
    return { status: 'Half Full', color: 'bg-yellow-500' }
  } else if (occupancyPercentage <= 75) {
    return { status: 'Nearly Full', color: 'bg-orange-500' }
  } else {
    return { status: 'Crowded', color: 'bg-red-500' }
  }
}