from authlib.integrations.starlette_client import OAuth
from starlette.config import Config
from app.core.config import settings

# OAuth client singleton
_oauth_client = None

def get_oauth_settings():
    return settings

def get_oauth_client():
    global _oauth_client
    if _oauth_client is None:
        _oauth_client = OAuth()
        
        # Configure Google provider
        _oauth_client.register(
            name='google',
            client_id=settings.GOOGLE_CLIENT_ID,
            client_secret=settings.GOOGLE_CLIENT_SECRET,
            server_metadata_url='https://accounts.google.com/.well-known/openid-configuration',
            client_kwargs={
                'scope': 'openid email profile'
            }
        )
        
    return _oauth_client