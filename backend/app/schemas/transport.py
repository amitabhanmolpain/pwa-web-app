from typing import List, Optional
from pydantic import BaseModel, Field
from datetime import datetime


class Location(BaseModel):
    latitude: float
    longitude: float


class RouteBase(BaseModel):
    start_location: Location
    end_location: Location
    name: Optional[str] = None
    description: Optional[str] = None


class RouteCreate(RouteBase):
    pass


class Route(RouteBase):
    id: str
    user_id: str
    created_at: datetime
    updated_at: datetime

    class Config:
        orm_mode = True


class FavoriteRouteCreate(BaseModel):
    route_id: str


class FavoriteRoute(BaseModel):
    id: str
    user_id: str
    route_id: str
    created_at: datetime
    route: Route

    class Config:
        orm_mode = True


class BusStop(BaseModel):
    id: str
    name: str
    location: Location
    routes: List[str] = []

    class Config:
        orm_mode = True


class Bus(BaseModel):
    id: str
    name: str
    route_id: str
    current_location: Optional[Location] = None
    is_active: bool = True
    capacity: int
    current_occupancy: Optional[int] = None
    next_stop_id: Optional[str] = None
    estimated_arrival: Optional[datetime] = None

    class Config:
        orm_mode = True