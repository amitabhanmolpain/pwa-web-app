from fastapi import APIRouter

from .endpoints import auth, oauth, transport, notifications

router = APIRouter()

# Include the routers from endpoints
router.include_router(auth.router, prefix="/auth", tags=["authentication"])
router.include_router(oauth.router, prefix="/auth", tags=["oauth"])
router.include_router(transport.router, prefix="/transport", tags=["transport"])
router.include_router(notifications.router, prefix="/user", tags=["notifications"])

# Additional routers can be added here as the API expands