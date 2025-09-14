from datetime import datetime
import uuid
from sqlalchemy import Boolean, Column, ForeignKey, String, DateTime, Table, Float, Integer, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.dialects.postgresql import UUID, JSONB

from app.db.session import Base


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=False)
    name = Column(String)
    phone = Column(String)
    hashed_password = Column(String)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # For OAuth users
    oauth_provider = Column(String, nullable=True)
    oauth_id = Column(String, nullable=True)
    
    # Relationships
    favorite_routes = relationship("FavoriteRoute", back_populates="user")
    routes = relationship("Route", back_populates="user")
    notifications = relationship("Notification", back_populates="user")
    sos_requests = relationship("SOSRequest", back_populates="user")


class RefreshToken(Base):
    __tablename__ = "refresh_tokens"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    token = Column(String, index=True, nullable=False)
    expires_at = Column(DateTime, nullable=False)
    revoked = Column(Boolean, default=False)
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User")


class Route(Base):
    __tablename__ = "routes"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=True)
    description = Column(String, nullable=True)
    start_location = Column(JSON, nullable=False)  # {latitude: float, longitude: float}
    end_location = Column(JSON, nullable=False)    # {latitude: float, longitude: float}
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="routes")
    favorite_routes = relationship("FavoriteRoute", back_populates="route")


class FavoriteRoute(Base):
    __tablename__ = "favorite_routes"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    route_id = Column(String, ForeignKey("routes.id"), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="favorite_routes")
    route = relationship("Route", back_populates="favorite_routes")


class BusStop(Base):
    __tablename__ = "bus_stops"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    location = Column(JSON, nullable=False)  # {latitude: float, longitude: float}
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)


class Bus(Base):
    __tablename__ = "buses"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    route_id = Column(String, nullable=True)
    current_location = Column(JSON, nullable=True)  # {latitude: float, longitude: float}
    is_active = Column(Boolean, default=True)
    capacity = Column(Integer, nullable=False)
    current_occupancy = Column(Integer, nullable=True)
    next_stop_id = Column(String, ForeignKey("bus_stops.id"), nullable=True)
    estimated_arrival = Column(DateTime, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    next_stop = relationship("BusStop")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    title = Column(String, nullable=False)
    content = Column(String, nullable=False)
    type = Column(String, nullable=False)  # "alert", "info", "update", etc.
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    # Relationships
    user = relationship("User", back_populates="notifications")


class SOSRequest(Base):
    __tablename__ = "sos_requests"

    id = Column(String, primary_key=True, index=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), nullable=False)
    location = Column(JSON, nullable=False)  # {latitude: float, longitude: float}
    message = Column(String, nullable=True)
    contact_emergency_services = Column(Boolean, default=False)
    status = Column(String, nullable=False)  # "pending", "processing", "resolved"
    created_at = Column(DateTime, default=datetime.utcnow)
    resolved_at = Column(DateTime, nullable=True)

    # Relationships
    user = relationship("User", back_populates="sos_requests")