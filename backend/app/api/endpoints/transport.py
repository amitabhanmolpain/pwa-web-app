from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from sqlalchemy.orm import Session

from ..schemas.transport import (
    Route, RouteCreate, FavoriteRoute, FavoriteRouteCreate, 
    BusStop, Bus
)
from ..db.session import get_db
from ..db.models import Route as RouteModel, FavoriteRoute as FavoriteRouteModel
from ..core.security import get_current_user

router = APIRouter()


@router.get("/routes", response_model=List[Route])
async def get_routes(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    skip: int = 0,
    limit: int = 100
):
    routes = db.query(RouteModel).offset(skip).limit(limit).all()
    return routes


@router.post("/routes", response_model=Route, status_code=status.HTTP_201_CREATED)
async def create_route(
    route: RouteCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    db_route = RouteModel(
        **route.dict(),
        user_id=current_user.id
    )
    db.add(db_route)
    db.commit()
    db.refresh(db_route)
    return db_route


@router.get("/routes/{route_id}", response_model=Route)
async def get_route(
    route_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    route = db.query(RouteModel).filter(RouteModel.id == route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    return route


@router.get("/favorites", response_model=List[FavoriteRoute])
async def get_favorite_routes(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    skip: int = 0,
    limit: int = 100
):
    favorites = db.query(FavoriteRouteModel).filter(
        FavoriteRouteModel.user_id == current_user.id
    ).offset(skip).limit(limit).all()
    return favorites


@router.post("/favorites", response_model=FavoriteRoute, status_code=status.HTTP_201_CREATED)
async def add_favorite_route(
    favorite: FavoriteRouteCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Check if route exists
    route = db.query(RouteModel).filter(RouteModel.id == favorite.route_id).first()
    if not route:
        raise HTTPException(status_code=404, detail="Route not found")
    
    # Check if already favorited
    existing = db.query(FavoriteRouteModel).filter(
        FavoriteRouteModel.user_id == current_user.id,
        FavoriteRouteModel.route_id == favorite.route_id
    ).first()
    
    if existing:
        raise HTTPException(status_code=400, detail="Route already in favorites")
    
    db_favorite = FavoriteRouteModel(
        user_id=current_user.id,
        route_id=favorite.route_id
    )
    db.add(db_favorite)
    db.commit()
    db.refresh(db_favorite)
    return db_favorite


@router.delete("/favorites/{route_id}", status_code=status.HTTP_204_NO_CONTENT)
async def remove_favorite_route(
    route_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    favorite = db.query(FavoriteRouteModel).filter(
        FavoriteRouteModel.user_id == current_user.id,
        FavoriteRouteModel.route_id == route_id
    ).first()
    
    if not favorite:
        raise HTTPException(status_code=404, detail="Favorite route not found")
    
    db.delete(favorite)
    db.commit()
    return None


@router.get("/nearby", response_model=List[BusStop])
async def get_nearby_stops(
    latitude: float,
    longitude: float,
    radius: float = 1.0,  # in kilometers
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # This would normally use a spatial query like PostGIS
    # For now, returning mock data
    return []  # Implement actual nearby stop search with geospatial queries


@router.get("/buses/active", response_model=List[Bus])
async def get_active_buses(
    route_id: str = None,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # This would query active buses, optionally filtered by route
    # For now, returning mock data
    return []  # Implement actual active bus query