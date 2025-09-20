# MargDarshak Transport System

A comprehensive multi-platform transport management system consisting of a Flutter mobile driver application, Next.js PWA for passengers, and Spring Boot backend API.

## 📁 Project Structure

```
Flutter-App/
├── .git/                               # Git repository configuration
├── flutter-frontend/                   # Flutter Driver Mobile Application
├── PWA-passenger-web app/              # Next.js Progressive Web App for Passengers
├── backend-folder/                     # Spring Boot Backend API
└── README.md                          # This file
```

## 🚗 Components Overview

### 1. Flutter Frontend (Mobile Driver App)
**Location**: `flutter-frontend/`
**Technology**: Flutter/Dart
**Purpose**: Mobile application for bus drivers to manage trips, schedules, and real-time tracking

#### Key Features:
- Driver authentication and profile management
- Real-time GPS tracking and location sharing
- Trip management and schedule viewing
- Emergency SOS functionality
- Multi-language support
- Dark/Light theme support
- WebSocket communication for real-time updates

#### File Structure:
```
flutter-frontend/
├── android/                           # Android-specific configuration
├── ios/                              # iOS-specific configuration
├── lib/                              # Dart source code
│   ├── main.dart                     # Application entry point
│   ├── login_screen.dart             # Driver login interface
│   ├── dashboard_screen.dart         # Main driver dashboard
│   ├── trip_service.dart             # Trip management services
│   ├── websocket_service.dart        # Real-time communication
│   ├── map_screen.dart               # GPS mapping functionality
│   ├── sos_emergency_screen.dart     # Emergency features
│   ├── journey_planner_screen.dart   # Route planning
│   ├── bus_schedule_screen.dart      # Schedule management
│   ├── settings_screen.dart          # App configuration
│   ├── theme_notifier.dart           # Theme management
│   └── [other screens and utilities]
├── linux/                           # Linux desktop support
├── macos/                           # macOS desktop support
├── web/                             # Web platform support
├── windows/                         # Windows desktop support
├── pubspec.yaml                     # Flutter dependencies
└── README.md                        # Flutter app documentation
```

#### Dependencies:
- `permission_handler`: Location and device permissions
- `geolocator`: GPS location services
- `web_socket_channel`: Real-time communication
- `flutter_secure_storage`: Secure token storage
- `provider`: State management
- `http`: REST API communication
- `table_calendar`: Schedule management

### 2. PWA Passenger Web App
**Location**: `PWA-passenger-web app/`
**Technology**: Next.js, React, TypeScript
**Purpose**: Progressive web application for passengers to book trips, track buses, and manage accounts

#### Key Features:
- Passenger registration and authentication
- Trip booking and payment integration
- Real-time bus tracking
- Route planning and scheduling
- Responsive design for mobile and desktop
- Progressive Web App capabilities
- Modern UI with shadcn/ui components

#### File Structure:
```
PWA-passenger-web app/
├── app/                              # Next.js App Router
│   ├── page.tsx                      # Home page (redirects to login)
│   ├── layout.tsx                    # Root layout component
│   ├── globals.css                   # Global styles
│   ├── api/                          # API route handlers
│   ├── dashboard/                    # Passenger dashboard
│   ├── login/                        # Authentication pages
│   └── signup/                       # User registration
├── components/                       # Reusable React components
├── hooks/                           # Custom React hooks
├── lib/                             # Utility functions and configurations
├── public/                          # Static assets
├── styles/                          # Additional stylesheets
├── types/                           # TypeScript type definitions
├── package.json                     # Node.js dependencies
├── next.config.mjs                  # Next.js configuration
├── tsconfig.json                    # TypeScript configuration
└── tailwind.config.js               # Tailwind CSS configuration
```

#### Dependencies:
- `next`: React framework with SSR/SSG
- `react`: Frontend library
- `@radix-ui/*`: Accessible UI components
- `tailwindcss`: Utility-first CSS framework
- `socket.io-client`: Real-time communication
- `redis`: Session management
- `zod`: Schema validation
- `lucide-react`: Icon library

### 3. Backend API
**Location**: `backend-folder/`
**Technology**: Spring Boot, Java 17, Maven
**Purpose**: RESTful API server providing authentication, trip management, and real-time communication

#### Key Features:
- JWT-based authentication and authorization
- MongoDB database integration
- Redis caching and session management
- WebSocket support for real-time updates
- RESTful API endpoints
- Docker containerization
- OAuth2 integration
- Security with Spring Security

#### File Structure:
```
backend-folder/
├── src/
│   ├── main/
│   │   ├── java/MargDarshakBackend/MargDarshakSIH/
│   │   │   ├── MargDarshakSihApplication.java    # Main application class
│   │   │   ├── config/                          # Configuration classes
│   │   │   ├── Controller/                      # REST API controllers
│   │   │   ├── dto/                             # Data Transfer Objects
│   │   │   ├── entity/                          # Database entities
│   │   │   ├── Filter/                          # Security filters
│   │   │   ├── Model/                           # Data models
│   │   │   ├── Repository/                      # Data access layer
│   │   │   ├── Service/                         # Business logic
│   │   │   ├── Utils/                           # Utility classes
│   │   │   └── websocket/                       # WebSocket handlers
│   │   └── resources/                           # Configuration files
│   └── test/                                    # Unit and integration tests
├── .mvn/                                        # Maven wrapper
├── docker-compose.yml                           # Docker services configuration
├── Dockerfile                                   # Container build instructions
├── pom.xml                                      # Maven dependencies
└── mvnw / mvnw.cmd                             # Maven wrapper scripts
```

#### Dependencies:
- `spring-boot-starter-web`: Web application framework
- `spring-boot-starter-security`: Authentication and authorization
- `spring-boot-starter-data-mongodb`: MongoDB integration
- `spring-boot-starter-data-redis`: Redis caching
- `spring-boot-starter-websocket`: Real-time communication
- `jjwt`: JWT token handling
- `lombok`: Code generation
- `modelmapper`: Object mapping

## 🚀 Setup Instructions

### Prerequisites
- **Java 17+** (for backend)
- **Node.js 18+** and **PNPM** (for PWA)
- **Flutter SDK 3.35.3+** (for mobile app)
- **Docker & Docker Compose** (for backend services)
- **MongoDB** and **Redis** (or use Docker)

### 1. Backend Setup

1. **Navigate to backend directory:**
   ```powershell
   cd backend-folder
   ```

2. **Start services with Docker:**
   ```powershell
   docker-compose up -d
   ```
   This starts MongoDB (port 27017) and Redis (port 6379)

3. **Build and run the Spring Boot application:**
   ```powershell
   # Using Maven wrapper
   .\mvnw clean install
   .\mvnw spring-boot:run
   ```
   
   **OR using Docker:**
   ```powershell
   docker-compose up --build
   ```

4. **API will be available at:** `http://localhost:8080`

### 2. PWA Passenger App Setup

1. **Navigate to PWA directory:**
   ```powershell
   cd "PWA-passenger-web app"
   ```

2. **Install dependencies:**
   ```powershell
   pnpm install
   ```

3. **Run development server:**
   ```powershell
   pnpm dev
   ```

4. **Build for production:**
   ```powershell
   pnpm build
   pnpm start
   ```

5. **PWA will be available at:** `http://localhost:3000`

### 3. Flutter Driver App Setup

1. **Navigate to Flutter directory:**
   ```powershell
   cd flutter-frontend
   ```

2. **Get Flutter dependencies:**
   ```powershell
   flutter pub get
   ```

3. **Create environment file:**
   Create `.env` file in `lib/` directory with:
   ```
   API_BASE_URL=http://localhost:8080
   WEBSOCKET_URL=ws://localhost:8080/ws
   ```

4. **Run on desired platform:**
   ```powershell
   # Android (requires Android SDK)
   flutter run -d android
   
   # iOS (requires Xcode on macOS)
   flutter run -d ios
   
   # Web
   flutter run -d web-server --web-port 8000
   
   # Windows
   flutter run -d windows
   ```

## 🔧 Configuration

### Environment Variables

#### Backend (`backend-folder/src/main/resources/application.properties`):
```properties
# Database Configuration
spring.data.mongodb.uri=mongodb://localhost:27017/margdarshak
spring.redis.host=localhost
spring.redis.port=6379

# JWT Configuration
jwt.secret=your-secret-key
jwt.expiration=86400000

# Server Configuration
server.port=8080
```

#### PWA (`.env.local`):
```env
NEXT_PUBLIC_API_URL=http://localhost:8080
NEXT_PUBLIC_WS_URL=ws://localhost:8080/ws
```

#### Flutter (`flutter-frontend/lib/.env`):
```env
API_BASE_URL=http://localhost:8080
WEBSOCKET_URL=ws://localhost:8080/ws
```

## 🌐 API Endpoints

### Authentication
- `POST /api/auth/login` - User login
- `POST /api/auth/register` - User registration
- `POST /api/auth/logout` - User logout
- `GET /api/auth/profile` - Get user profile

### Trip Management
- `GET /api/trips` - Get all trips
- `POST /api/trips` - Create new trip
- `PUT /api/trips/{id}` - Update trip
- `DELETE /api/trips/{id}` - Delete trip

### Real-time Communication
- `WebSocket /ws` - Real-time location and trip updates

## 🔄 Development Workflow

1. **Start Backend Services:**
   ```powershell
   cd backend-folder
   docker-compose up -d
   .\mvnw spring-boot:run
   ```

2. **Start PWA Development:**
   ```powershell
   cd "PWA-passenger-web app"
   pnpm dev
   ```

3. **Start Flutter Development:**
   ```powershell
   cd flutter-frontend
   flutter run -d web-server --web-port 8000
   ```

## 📱 Supported Platforms

### Flutter Driver App:
- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ macOS
- ✅ Linux

### PWA Passenger App:
- ✅ Web browsers (Chrome, Firefox, Safari, Edge)
- ✅ Mobile browsers (responsive design)
- ✅ Desktop PWA installation

### Backend API:
- ✅ Docker containers
- ✅ Windows
- ✅ macOS
- ✅ Linux

## 🧪 Testing

### Backend Testing:
```powershell
cd backend-folder
.\mvnw test
```

### PWA Testing:
```powershell
cd "PWA-passenger-web app"
pnpm test
```

### Flutter Testing:
```powershell
cd flutter-frontend
flutter test
```

## 📦 Deployment

### Backend Deployment:
1. **Docker Production:**
   ```powershell
   docker-compose -f docker-compose.prod.yml up -d
   ```

2. **JAR Deployment:**
   ```powershell
   .\mvnw clean package
   java -jar target/MargDarshakSIH-0.0.1-SNAPSHOT.jar
   ```

### PWA Deployment:
1. **Build production:**
   ```powershell
   pnpm build
   ```

2. **Deploy to Vercel/Netlify or serve static files**

### Flutter Deployment:
1. **Android APK:**
   ```powershell
   flutter build apk --release
   ```

2. **iOS (requires macOS):**
   ```powershell
   flutter build ios --release
   ```

3. **Web:**
   ```powershell
   flutter build web --release
   ```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License.

## 📞 Support

For support and questions, please contact the development team or create an issue in the repository.

---

**Repository**: [pwa-web-app](https://github.com/amitabhanmolpain/pwa-web-app)
**Last Updated**: September 20, 2025