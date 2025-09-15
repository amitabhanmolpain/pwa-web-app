import { BusType } from '@/types/schedule'

// Types for API requests and responses
export interface DateRequest {
  from: string
  to: string
  date: string
  time: string
  busType: BusType
}

export interface ScheduleResponse {
  route: string
  time: string
  destination: string
  type: BusType
  frequency: string
}

export interface CalendarDate {
  date: string
  hasSchedule: boolean
  busTypes: BusType[]
}

// API functions for schedule-related operations
const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api'

export async function submitDateRequest(request: DateRequest): Promise<{ success: boolean; message: string }> {
  try {
    const response = await fetch(`${BASE_URL}/schedule/request`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(request),
    })

    if (!response.ok) {
      throw new Error('Failed to submit date request')
    }

    const data = await response.json()
    return data
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error occurred'
    throw new Error('Failed to submit date request: ' + message)
  }
}

export async function getCalendarData(month: number, year: number, busType?: BusType): Promise<CalendarDate[]> {
  try {
    const queryParams = new URLSearchParams({
      month: month.toString(),
      year: year.toString(),
      ...(busType && { busType }),
    })

    const response = await fetch(`${BASE_URL}/schedule/calendar?${queryParams}`)
    if (!response.ok) {
      throw new Error('Failed to fetch calendar data')
    }

    const data = await response.json()
    return data
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error occurred'
    throw new Error('Failed to fetch calendar data: ' + message)
  }
}

export async function getDaySchedule(date: string, busType?: BusType): Promise<ScheduleResponse[]> {
  try {
    const queryParams = new URLSearchParams({
      date,
      ...(busType && { busType }),
    })

    const response = await fetch(`${BASE_URL}/schedule/day?${queryParams}`)
    if (!response.ok) {
      throw new Error('Failed to fetch day schedule')
    }

    const data = await response.json()
    return data
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error occurred'
    throw new Error('Failed to fetch day schedule: ' + message)
  }
}

export async function getWeekSchedule(date: string, busType?: BusType): Promise<Record<string, ScheduleResponse[]>> {
  try {
    const queryParams = new URLSearchParams({
      date,
      ...(busType && { busType }),
    })

    const response = await fetch(`${BASE_URL}/schedule/week?${queryParams}`)
    if (!response.ok) {
      throw new Error('Failed to fetch week schedule')
    }

    const data = await response.json()
    return data
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'Unknown error occurred'
    throw new Error('Failed to fetch week schedule: ' + message)
  }
}