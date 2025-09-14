from typing import List, Optional
from pydantic import BaseModel
from datetime import datetime


class NotificationBase(BaseModel):
    title: str
    content: str
    type: str  # "alert", "info", "update", etc.
    is_read: bool = False


class NotificationCreate(NotificationBase):
    pass


class Notification(NotificationBase):
    id: str
    user_id: str
    created_at: datetime
    
    class Config:
        orm_mode = True


class SOSRequestBase(BaseModel):
    location: dict  # latitude and longitude
    message: Optional[str] = None
    contact_emergency_services: bool = False


class SOSRequestCreate(SOSRequestBase):
    pass


class SOSRequest(SOSRequestBase):
    id: str
    user_id: str
    created_at: datetime
    status: str  # "pending", "processing", "resolved"
    resolved_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True