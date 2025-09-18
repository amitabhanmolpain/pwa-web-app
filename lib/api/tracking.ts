const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

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

/**
 * Try to subscribe to real-time updates over socket.io (client-side). If socket.io-client
 * is not available or connection fails, the caller can fall back to polling (subscribeToLocationUpdates).
 * Returns a cleanup function.
 */
export function subscribeToLocationSocket(
  params: TrackingParams,
  onUpdate: (location: DriverLocation) => void,
  onError: (error: Error) => void
): () => void {
  // Default cleanup that does nothing (in case socket import fails)
  let socket: any = null
  let isConnected = false

  // Begin dynamic import and connection. This function intentionally does not block
  // the caller; it returns a cleanup function immediately and sets up the socket async.
  ;(async () => {
    try {
      // Dynamic import so builds don't fail if socket.io-client isn't installed
      const mod = await import('socket.io-client')
      const io = mod?.io || mod?.default || mod

      const SOCKET_URL = (process.env.NEXT_PUBLIC_SOCKET_URL as string) || (process.env.NEXT_PUBLIC_API_URL?.replace('/api', '') as string) || 'http://localhost:8080'

      socket = io(SOCKET_URL, { transports: ['websocket'] })

      socket.on('connect', () => {
        isConnected = true
        // subscribe by busId or room
        if (params.busId) socket.emit('subscribe', { busId: params.busId })
        if (params.driverId) socket.emit('subscribe', { driverId: params.driverId })
      })

      socket.on('location:update', (payload: any) => {
        try {
          // payload expected to be compatible with DriverLocation
          if (!payload) return
          onUpdate(payload as DriverLocation)
        } catch (err) {
          // ignore malformed payloads
        }
      })

      socket.on('connect_error', (err: any) => {
        onError(new Error('Socket connect error'))
      })

      socket.on('error', (err: any) => {
        onError(new Error('Socket error'))
      })
    } catch (err) {
      // dynamic import failed or socket connection couldn't be established
      // caller should fall back to polling if needed
      onError(err as Error)
    }
  })()

  // Return cleanup function
  return () => {
    try {
      if (socket && isConnected) {
        if (params.busId) socket.emit('unsubscribe', { busId: params.busId })
        if (params.driverId) socket.emit('unsubscribe', { driverId: params.driverId })
        socket.disconnect()
      }
    } catch (err) {
      // ignore cleanup errors
    }
  }
}