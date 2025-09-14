# MargDarshak FastAPI Backend

This is the backend service for the MargDarshak transit application, built with FastAPI, SQLAlchemy, and PostgreSQL.

## Features

- Authentication (JWT-based with refresh tokens)
- Google OAuth integration
- User profiles
- Route planning and favorites
- Live bus tracking
- Notifications
- SOS emergency system

## Setup

1. Create a virtual environment:
```bash
python -m venv venv
```

2. Activate the virtual environment:
- Windows:
```bash
venv\Scripts\activate
```
- Mac/Linux:
```bash
source venv/bin/activate
```

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Create a `.env` file based on `.env.example`:

```
# Database settings
DATABASE_URL=postgresql://user:password@localhost:5432/margdarshak
# For development, you can use SQLite
# DATABASE_URL=sqlite:///./app.db

# Authentication
SECRET_KEY=your-secret-key-here
ACCESS_TOKEN_EXPIRE_MINUTES=10080  # 7 days
REFRESH_TOKEN_EXPIRE_DAYS=30

# CORS
CORS_ORIGINS=http://localhost:3000,https://yourdomain.com

# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=http://localhost:8000/api/auth/google/callback

# Frontend URL for OAuth redirects
FRONTEND_URL=http://localhost:3000

# Backend URL
BACKEND_URL=http://localhost:8000
```

5. Run migrations:
```bash
alembic upgrade head
```

6. Start the development server:
```bash
uvicorn app.main:app --reload
```

## API Documentation

Once the server is running, you can access:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## Project Structure

```
backend/
├── alembic/                # Database migrations
├── app/                    # Application package
│   ├── api/                # API endpoints
│   │   ├── endpoints/      # API route handlers
│   │   │   ├── auth.py     # Authentication endpoints
│   │   │   ├── oauth.py    # OAuth endpoints
│   │   │   ├── transport.py # Transport-related endpoints
│   │   │   └── notifications.py # Notification endpoints
│   │   └── api.py          # API router
│   ├── core/               # Core modules
│   │   ├── config.py       # Settings and configuration
│   │   ├── security.py     # Authentication and security utilities
│   │   └── oauth_config.py # OAuth configuration
│   ├── db/                 # Database
│   │   ├── session.py      # Database session setup
│   │   ├── models.py       # SQLAlchemy models
│   │   └── init_db.py      # Database initialization
│   ├── schemas/            # Pydantic models
│   │   ├── auth.py         # Authentication schemas
│   │   ├── transport.py    # Transport schemas
│   │   └── notifications.py # Notification schemas
│   └── main.py             # Application entry point
├── tests/                  # Test files
├── .env.example            # Example environment variables
├── requirements.txt        # Dependencies
└── README.md               # This file
```

## API Endpoints

The API includes the following endpoints:

### Authentication

- `POST /api/auth/register` - Register a new user
- `POST /api/auth/login` - Login and get access token
- `POST /api/auth/validate` - Validate access token
- `POST /api/auth/logout` - Logout (clear cookies)
- `GET /api/auth/google` - Redirect to Google OAuth
- `GET /api/auth/google/callback` - Handle Google OAuth callback

### Transport

- `GET /api/transport/routes` - Get all routes
- `POST /api/transport/routes` - Create a route
- `GET /api/transport/routes/{route_id}` - Get route details
- `GET /api/transport/favorites` - Get user's favorite routes
- `POST /api/transport/favorites` - Add a route to favorites
- `DELETE /api/transport/favorites/{route_id}` - Remove a route from favorites
- `GET /api/transport/nearby` - Get nearby bus stops
- `GET /api/transport/buses/active` - Get active buses

### Notifications and SOS

- `GET /api/user/notifications` - Get user notifications
- `POST /api/user/notifications/read/{notification_id}` - Mark notification as read
- `POST /api/user/notifications/read-all` - Mark all notifications as read
- `POST /api/user/sos` - Create an SOS request
- `GET /api/user/sos/{sos_id}` - Get SOS request details

## Authentication

The API uses JWT tokens for authentication. Tokens are provided via:
- HTTP-only cookies (preferred for web clients)
- Authorization header (for mobile/other clients)

## Development Notes

- Use `black` for code formatting
- Run tests with `pytest`
- Follow the API contract in the frontend's `app/api/auth/README.md`