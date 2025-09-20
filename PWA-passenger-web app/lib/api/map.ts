const BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8080/api';

export interface MapLocation {
  latitude: number;
  longitude: number;
  address?: string;
  landmark?: string;
  type: 'bus-stop' | 'depot' | 'point-of-interest';
}

export interface RoutePoint {
  latitude: number;
  longitude: number;
  order: number;
  stopType: 'pickup' | 'dropoff' | 'waypoint';
  waitTime?: number; // in minutes
  distance?: number; // in kilometers from previous point
}

export interface BusRoute {
  routeId: string;
  routeName: string;
  points: RoutePoint[];
  totalDistance: number;
  estimatedTime: number;
  trafficCondition: 'light' | 'moderate' | 'heavy';
}

export interface NearbyStop {
  stopId: string;
  name: string;
  latitude: number;
  longitude: number;
  distance: number; // in kilometers from user
  nextBuses: {
    routeId: string;
    routeName: string;
    estimatedArrival: string;
    busId: string;
  }[];
}

/**
 * Get nearby bus stops within a radius
 */
export async function getNearbyStops(
  latitude: number,
  longitude: number,
  radius: number = 2 // Default 2km radius
): Promise<NearbyStop[]> {
  const response = await fetch(
    `${BASE_URL}/map/nearby-stops?lat=${latitude}&lng=${longitude}&radius=${radius}`
  );
  
  if (!response.ok) {
    throw new Error('Failed to fetch nearby stops');
  }
  
  return response.json();
}

/**
 * Get route details with all stops
 */
export async function getRouteDetails(routeId: string): Promise<BusRoute> {
  const response = await fetch(`${BASE_URL}/map/route/${routeId}`);
  
  if (!response.ok) {
    throw new Error('Failed to fetch route details');
  }
  
  return response.json();
}

/**
 * Get optimized route between two points considering traffic
 */
export async function getOptimizedRoute(
  from: { lat: number; lng: number },
  to: { lat: number; lng: number },
  options?: {
    avoidTraffic?: boolean;
    preferHighways?: boolean;
  }
): Promise<BusRoute> {
  const params = new URLSearchParams({
    fromLat: from.lat.toString(),
    fromLng: from.lng.toString(),
    toLat: to.lat.toString(),
    toLng: to.lng.toString(),
    ...(options?.avoidTraffic && { avoidTraffic: 'true' }),
    ...(options?.preferHighways && { preferHighways: 'true' }),
  });

  const response = await fetch(`${BASE_URL}/map/optimize-route?${params}`);
  
  if (!response.ok) {
    throw new Error('Failed to fetch optimized route');
  }
  
  return response.json();
}

/**
 * Get current traffic conditions for a route or area
 */
export async function getTrafficConditions(
  points: { lat: number; lng: number }[]
): Promise<{
  condition: 'light' | 'moderate' | 'heavy';
  delay: number; // in minutes
  alternateRoutes?: BusRoute[];
}> {
  const response = await fetch(`${BASE_URL}/map/traffic-conditions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ points }),
  });
  
  if (!response.ok) {
    throw new Error('Failed to fetch traffic conditions');
  }
  
  return response.json();
}

/**
 * Search locations (bus stops, landmarks, etc.)
 */
export async function searchLocations(
  query: string,
  options?: {
    type?: 'bus-stop' | 'depot' | 'point-of-interest';
    limit?: number;
  }
): Promise<MapLocation[]> {
  const params = new URLSearchParams({
    query,
    ...(options?.type && { type: options.type }),
    ...(options?.limit && { limit: options.limit.toString() }),
  });

  const response = await fetch(`${BASE_URL}/map/search?${params}`);
  
  if (!response.ok) {
    throw new Error('Failed to search locations');
  }
  
  return response.json();
}