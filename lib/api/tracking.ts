const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';

export interface DriverLocation {
  driverId: string;
  busId: string;
  route: string;
  latitude: number;
  longitude: number;
  speed: number;
  heading: number;
  timestamp: string;
  isOnDuty: boolean;
  nextStop: string;
  estimatedArrival: string;
  currentLocation: string;
  weatherCondition?: string;
}

export interface TrackingParams {
  busId?: string;
  driverId?: string;
  route?: string;
}

export interface BusStatus {
  busId: string;
  status: 'on-time' | 'delayed' | 'ahead' | 'stopped';
  delay?: number; // in minutes
  currentLocation: string;
  nextStop: string;
  estimatedArrival: string;
  occupancy: number;
  totalCapacity: number;
  speed: number;
  trafficCondition: 'light' | 'moderate' | 'heavy';
  weatherCondition?: string;
}

/**
 * Get real-time location of a bus/driver
 */
export async function getDriverLocation(params: TrackingParams): Promise<DriverLocation> {
  const queryParams = new URLSearchParams();
  if (params.busId) queryParams.append('busId', params.busId);
  if (params.driverId) queryParams.append('driverId', params.driverId);
  if (params.route) queryParams.append('route', params.route);

  const response = await fetch(`${BASE_URL}/tracking/location?${queryParams}`);
  if (!response.ok) {
    throw new Error('Failed to fetch driver location');
  }

  return response.json();
}

/**
 * Get detailed bus status including delays, occupancy, etc.
 */
export async function getBusStatus(busId: string): Promise<BusStatus> {
  const response = await fetch(`${BASE_URL}/tracking/status/${busId}`);
  if (!response.ok) {
    throw new Error('Failed to fetch bus status');
  }

  return response.json();
}

/**
 * Subscribe to real-time location updates
 * Returns a cleanup function to unsubscribe
 */
export function subscribeToLocationUpdates(
  params: TrackingParams,
  onUpdate: (location: DriverLocation) => void,
  onError: (error: Error) => void
): () => void {
  // Polling interval in milliseconds
  const POLL_INTERVAL = 5000;

  let isSubscribed = true;

  const pollLocation = async () => {
    try {
      if (!isSubscribed) return;
      
      const location = await getDriverLocation(params);
      onUpdate(location);
      
      if (isSubscribed) {
        setTimeout(pollLocation, POLL_INTERVAL);
      }
    } catch (error) {
      if (isSubscribed) {
        onError(error as Error);
        setTimeout(pollLocation, POLL_INTERVAL);
      }
    }
  };

  pollLocation();

  // Return cleanup function
  return () => {
    isSubscribed = false;
  };
}