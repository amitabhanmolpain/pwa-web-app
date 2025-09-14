from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from sqlalchemy.orm import Session

from ..schemas.notifications import (
    Notification, NotificationCreate,
    SOSRequest, SOSRequestCreate
)
from ..db.session import get_db
from ..db.models import Notification as NotificationModel, SOSRequest as SOSRequestModel
from ..core.security import get_current_user

router = APIRouter()


@router.get("/notifications", response_model=List[Notification])
async def get_notifications(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user),
    unread_only: bool = False,
    skip: int = 0,
    limit: int = 100
):
    query = db.query(NotificationModel).filter(
        NotificationModel.user_id == current_user.id
    )
    
    if unread_only:
        query = query.filter(NotificationModel.is_read == False)
    
    notifications = query.order_by(NotificationModel.created_at.desc()).offset(skip).limit(limit).all()
    return notifications


@router.post("/notifications/read/{notification_id}", response_model=Notification)
async def mark_notification_read(
    notification_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    notification = db.query(NotificationModel).filter(
        NotificationModel.id == notification_id,
        NotificationModel.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    db.commit()
    db.refresh(notification)
    return notification


@router.post("/notifications/read-all", status_code=status.HTTP_204_NO_CONTENT)
async def mark_all_notifications_read(
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    db.query(NotificationModel).filter(
        NotificationModel.user_id == current_user.id,
        NotificationModel.is_read == False
    ).update({NotificationModel.is_read: True})
    
    db.commit()
    return None


@router.post("/sos", response_model=SOSRequest, status_code=status.HTTP_201_CREATED)
async def create_sos_request(
    sos_request: SOSRequestCreate,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    # Create SOS request
    db_sos = SOSRequestModel(
        **sos_request.dict(),
        user_id=current_user.id,
        status="pending"
    )
    db.add(db_sos)
    
    # Create notification for user
    notification = NotificationModel(
        user_id=current_user.id,
        title="SOS Request Received",
        content="Your SOS request has been received. Emergency contacts have been notified.",
        type="alert"
    )
    db.add(notification)
    
    db.commit()
    db.refresh(db_sos)
    
    # In a real app, this would trigger notifications to emergency contacts,
    # transit authorities, etc.
    
    return db_sos


@router.get("/sos/{sos_id}", response_model=SOSRequest)
async def get_sos_request(
    sos_id: str,
    db: Session = Depends(get_db),
    current_user = Depends(get_current_user)
):
    sos_request = db.query(SOSRequestModel).filter(
        SOSRequestModel.id == sos_id,
        SOSRequestModel.user_id == current_user.id
    ).first()
    
    if not sos_request:
        raise HTTPException(status_code=404, detail="SOS request not found")
    
    return sos_request