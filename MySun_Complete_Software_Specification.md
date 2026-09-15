# MySun - Complete Software Specification & Implementation Plan
## Soroti University Campus Companion Application

**Version:** 2.0  
**Date:** September 2026  
**Prepared for:** Soroti University  
**Status:** Production Ready for Development

---

## TABLE OF CONTENTS

1. [Executive Summary](#executive-summary)
2. [System Architecture Overview](#system-architecture-overview)
3. [Technology Stack](#technology-stack)
4. [Database Design](#database-design)
5. [Backend Specification](#backend-specification)
6. [Frontend Specification](#frontend-specification)
7. [Admin Portal](#admin-portal)
8. [Security & Access Control](#security--access-control)
9. [Authentication & Login System](#authentication--login-system) ⭐ **NEW**
10. [Deployment & Hosting](#deployment--hosting)
11. [Implementation Roadmap](#implementation-roadmap)
12. [API Reference](#api-reference)
13. [Development Guidelines](#development-guidelines)

---

## 1. EXECUTIVE SUMMARY

### 1.1 Problem Statement

Soroti University students face three critical challenges:

1. **Information Fragmentation** - Campus updates scattered across WhatsApp, emails, porticeboards, and various portals
2. **Event Forgetfulness** - Students know about events but forget to attend due to lack of reminders
3. **Transport Insecurity** - Difficulty finding trusted, verified transportation options quickly

### 1.2 Solution: MySun

MySun is a comprehensive campus companion application that:
- Centralizes all campus announcements, events, and updates
- Delivers timely reminders for important events
- Provides a verified directory of safe transportation options
- Connects students with university information in one place

### 1.3 System Components

**Three core components:**

1. **MySun Student App** (Flutter iOS/Android)
   - Campus feed with announcements and events
   - Event discovery and calendar integration
   - Transport directory and bus schedules
   - Bookmarks and notifications
   - Dark mode and offline support ready

2. **MySun Admin Portal** (Flutter Web)
   - Content management (announcements, events, transport)
   - Role-based access control for different departments
   - Moderation workflow for content approval
   - Analytics and engagement tracking
   - User management and audit logs

3. **MySun Backend API** (Python FastAPI)
   - RESTful API for student app
   - Admin portal backend
   - Real-time updates via WebSockets
   - Authentication and authorization
   - File storage and image management
   - Hosted on Soroti University servers (self-hosted)

### 1.4 Key Features

**For Students:**
- Smart campus feed with categorized announcements
- Event search, filtering, and calendar integration
- Verified transport provider directory
- Campus bus schedules and departure times
- Bookmarks and saved items
- Notification center
- Dark mode and responsive design

**For Administrators:**
- Easy content publishing interface
- Role-based permissions (Department Admin, Moderator, Publisher)
- Content moderation workflow
- Analytics and engagement metrics
- Bulk operations (CSV import)
- Audit trails for compliance
- User and role management

**For University:**
- Centralized communication platform
- Reduced communication silos
- Measurable student engagement
- Verified transportation partnerships
- Cost-effective solution (self-hosted)
- Data privacy and control

---

## 2. SYSTEM ARCHITECTURE OVERVIEW

### 2.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    MySun Complete System                        │
└─────────────────────────────────────────────────────────────────┘

PRESENTATION LAYER
┌─────────────────────────┐  ┌─────────────────────────┐
│  Student App            │  │  Admin Portal           │
│  (Flutter iOS/Android)  │  │  (Flutter Web)          │
│                         │  │                         │
│ • Feed                  │  │ • Dashboard             │
│ • Events                │  │ • Content Management    │
│ • Transport             │  │ • Moderation            │
│ • Saved                 │  │ • Analytics             │
│ • Notifications         │  │ • Settings              │
│ • Profile               │  │ • User Management       │
└─────────────────────────┘  └─────────────────────────┘
           │                          │
           │    HTTP/HTTPS (REST)     │
           ├──────────────────────────┤
           │   WebSocket (Real-time)  │
           ▼                          ▼

APPLICATION LAYER
┌─────────────────────────────────────────────────────────────────┐
│              Backend API (Python FastAPI)                       │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ API Routes                                               │  │
│  │ • /api/announcements (GET, POST, PATCH, DELETE)         │  │
│  │ • /api/events (GET, POST, PATCH, DELETE)                │  │
│  │ • /api/transport (GET, POST, PATCH)                     │  │
│  │ • /api/bus-schedules (GET)                              │  │
│  │ • /api/notifications (GET, PATCH)                       │  │
│  │ • /api/auth (POST)                                      │  │
│  │ • /api/search (GET)                                     │  │
│  │ • /api/admin/* (dashboard, moderation, analytics)       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Middleware                                               │  │
│  │ • Authentication (JWT)                                   │  │
│  │ • Authorization (RBAC)                                   │  │
│  │ • Error handling                                         │  │
│  │ • Logging & monitoring                                   │  │
│  │ • Rate limiting                                          │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Services                                                 │  │
│  │ • AnnouncementService                                    │  │
│  │ • EventService                                           │  │
│  │ • TransportService                                       │  │
│  │ • AuthService                                            │  │
│  │ • NotificationService                                    │  │
│  │ • FileUploadService                                      │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
           │
           │    Database Queries
           │    File I/O
           ▼

DATA LAYER
┌─────────────────────────────────────────────────────────────────┐
│                PostgreSQL Database                              │
│                                                                 │
│  Tables:                                                        │
│  • users, admin_users, user_roles                              │
│  • announcements, events, notifications                        │
│  • transport_providers, bus_schedules                          │
│  • user_bookmarks, user_preferences                            │
│  • admin_sessions, audit_logs                                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│            File Storage (Local Server)                          │
│                                                                 │
│  Directories:                                                   │
│  • /storage/announcements/ (images)                            │
│  • /storage/events/ (images)                                   │
│  • /storage/avatars/ (user/provider images)                    │
│  • /storage/uploads/ (admin uploads)                           │
└─────────────────────────────────────────────────────────────────┘

HOSTING
┌─────────────────────────────────────────────────────────────────┐
│       Soroti University Servers (On-Premises)                   │
│                                                                 │
│  • Backend API server (Python + FastAPI)                       │
│  • PostgreSQL database server                                  │
│  • File storage (local filesystem or NAS)                      │
│  • Web server for admin portal (Nginx/Apache)                  │
│  • SSL/TLS certificates                                        │
│  • Backup systems                                              │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Architecture Layers

#### Presentation Layer
- **Student App (Flutter Mobile)**
  - iOS 14+ and Android 9+ support
  - Material Design 3 UI
  - State management: Riverpod
  - Navigation: go_router
  - Local storage: Hive + SharedPreferences

- **Admin Portal (Flutter Web)**
  - Web-based dashboard
  - Same technology stack as mobile
  - Role-based access control
  - Real-time updates via WebSocket

#### Application Layer
- **Backend API (Python FastAPI)**
  - Async/await for high performance
  - Dependency injection
  - Comprehensive error handling
  - Request validation with Pydantic
  - Logging and monitoring
  - Rate limiting

#### Data Layer
- **Database (PostgreSQL)**
  - Relational data model
  - ACID compliance
  - JSON support for flexible fields
  - Full-text search capability
  - Row-level security ready

- **File Storage (Local Server)**
  - Image storage on filesystem
  - CDN-ready (can add Cloudflare later)
  - Organized by content type

#### Deployment
- **Self-hosted on Soroti University servers**
  - Docker containers for easy deployment
  - Systemd services for auto-restart
  - Nginx reverse proxy
  - SSL/TLS encryption
  - Regular backups

---

## 3. TECHNOLOGY STACK

### 3.1 Recommended Technology Stack

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Frontend (Mobile)** | Flutter 3.x | Cross-platform, native performance, Material 3 support |
| **Frontend (Web)** | Flutter Web | Same codebase as mobile, responsive design |
| **Backend** | Python 3.11+ | Easy to maintain, large ecosystem, good for APIs |
| **Backend Framework** | FastAPI | Modern, async, automatic documentation, Pydantic validation |
| **Database** | PostgreSQL 14+ | Open source, reliable, advanced features, JSON support |
| **Language** | Python + Dart | Type-safe, productive, mature ecosystems |
| **State Management** | Riverpod | Reactive, testable, dependency injection |
| **Navigation** | go_router | Declarative, deep linking, web routing |
| **Real-time** | WebSocket | Live updates, built-in FastAPI support |
| **Authentication** | JWT + OAuth2 | Industry standard, scalable |
| **File Storage** | Local Filesystem | Cost-effective, full control, on-premises |
| **Reverse Proxy** | Nginx | Fast, reliable, SSL termination |
| **Containerization** | Docker | Easy deployment, environment consistency |
| **Version Control** | Git + GitHub/GitLab | Standard practice, history tracking |
| **Task Queue** | Celery (optional Phase 2) | Async task processing, email notifications |
| **Caching** | Redis (optional Phase 2) | Performance optimization, session storage |

### 3.2 Python Backend Dependencies

```
FastAPI==0.104.0
uvicorn==0.24.0
pydantic==2.5.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
python-dotenv==1.0.0
python-multipart==0.0.6
PyJWT==2.8.1
passlib[bcrypt]==1.7.4
python-jose[cryptography]==3.3.0
alembic==1.12.1
pytest==7.4.3
pytest-asyncio==0.21.1
aiofiles==23.2.1
pillow==10.1.0
email-validator==2.1.0
```

### 3.3 Flutter Frontend Dependencies

```yaml
riverpod: ^2.4.0
flutter_riverpod: ^2.4.0
go_router: ^10.0.0
dio: ^5.0.0
cached_network_image: ^3.3.0
hive: ^2.2.3
hive_flutter: ^1.1.0
shared_preferences: ^2.2.0
intl: ^0.19.0
freezed_annotation: ^2.4.1
json_serializable: ^6.7.0
web_socket_channel: ^2.4.0
provider: ^6.0.0  # For simple state when needed
```

---

## 4. DATABASE DESIGN

### 4.1 Database Choice: PostgreSQL

**Why PostgreSQL?**

| Feature | Benefit |
|---------|---------|
| **Open Source** | No licensing costs, full control |
| **Reliability** | ACID compliance, data integrity |
| **Performance** | Handles 10,000+ users efficiently |
| **Scalability** | Can grow with university needs |
| **JSON Support** | Flexible data structures when needed |
| **Full-text Search** | Native search on announcements |
| **Row-Level Security** | Database-level access control |
| **On-Premises** | Can be hosted on university servers |
| **Community** | Mature ecosystem, lots of support |

### 4.2 Database Schema

```sql
-- Core Tables

-- Users (Students)
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    student_id VARCHAR(50),
    faculty VARCHAR(100),
    program VARCHAR(100),
    image_url VARCHAR(500),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin Users
CREATE TABLE admin_users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(500) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL, -- 'super_admin', 'moderator', 'publisher', 'transport_admin'
    department VARCHAR(100), -- NULL for super_admin
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Admin Sessions (for token tracking)
CREATE TABLE admin_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES admin_users(id),
    token VARCHAR(1000),
    ip_address VARCHAR(50),
    user_agent VARCHAR(500),
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Announcements
CREATE TABLE announcements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Academic', 'Social', 'Sports', 'Administration', 'Clubs', 'Transport'
    is_important BOOLEAN DEFAULT false,
    publisher_id UUID NOT NULL REFERENCES admin_users(id),
    publisher_name VARCHAR(255) NOT NULL,
    image_url VARCHAR(500),
    status VARCHAR(50) DEFAULT 'draft', -- 'draft', 'pending_review', 'approved', 'published', 'rejected'
    rejection_reason TEXT,
    published_at TIMESTAMP,
    scheduled_for TIMESTAMP, -- NULL for immediate publish
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP -- For time-limited announcements
);

-- Events
CREATE TABLE events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'Academic', 'Sports', 'Social', 'Clubs', 'Workshops'
    organizer_id UUID NOT NULL REFERENCES admin_users(id),
    organizer_name VARCHAR(255) NOT NULL,
    date_time TIMESTAMP NOT NULL,
    end_date_time TIMESTAMP,
    venue VARCHAR(255) NOT NULL,
    image_url VARCHAR(500),
    capacity INTEGER,
    registered_count INTEGER DEFAULT 0,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    status VARCHAR(50) DEFAULT 'draft', -- 'draft', 'pending_review', 'approved', 'published', 'cancelled'
    is_featured BOOLEAN DEFAULT false,
    published_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Transport Providers
CREATE TABLE transport_providers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    contact_person VARCHAR(255),
    image_url VARCHAR(500),
    is_verified BOOLEAN DEFAULT false,
    verified_date TIMESTAMP,
    verification_notes TEXT,
    rating DECIMAL(2,1) DEFAULT 0,
    rating_count INTEGER DEFAULT 0,
    operating_hours VARCHAR(100), -- e.g., "6:00 AM - 10:00 PM"
    service_areas TEXT[], -- Array of service areas
    service_type VARCHAR(50), -- 'boda', 'taxi', 'bus', 'matatu'
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bus Schedules
CREATE TABLE bus_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_name VARCHAR(255) NOT NULL,
    departure_point VARCHAR(255) NOT NULL,
    destination VARCHAR(255) NOT NULL,
    departure_time TIME NOT NULL,
    estimated_duration_minutes INTEGER,
    operating_days VARCHAR(100), -- 'Weekdays', 'Weekend', 'Daily', 'Mon-Fri'
    status VARCHAR(50) DEFAULT 'active', -- 'active', 'suspended', 'cancelled'
    capacity INTEGER,
    current_passengers INTEGER DEFAULT 0,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Bookmarks (Saved Announcements & Events)
CREATE TABLE user_bookmarks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    announcement_id UUID REFERENCES announcements(id),
    event_id UUID REFERENCES events(id),
    bookmark_type VARCHAR(50), -- 'announcement', 'event'
    bookmarked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    CHECK (
        (announcement_id IS NOT NULL AND event_id IS NULL) OR
        (announcement_id IS NULL AND event_id IS NOT NULL)
    )
);

-- User Preferences
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE NOT NULL REFERENCES users(id),
    theme VARCHAR(50) DEFAULT 'system', -- 'light', 'dark', 'system'
    notifications_enabled BOOLEAN DEFAULT true,
    event_reminders_enabled BOOLEAN DEFAULT true,
    selected_categories TEXT[], -- Array of category preferences
    notification_time VARCHAR(50) DEFAULT '09:00', -- Time for daily digest
    last_seen_notification_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    body TEXT NOT NULL,
    type VARCHAR(50) NOT NULL, -- 'announcement', 'event', 'reminder', 'transport', 'system'
    related_id UUID, -- ID of announcement/event/etc
    is_read BOOLEAN DEFAULT false,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Event Reminders
CREATE TABLE event_reminders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    event_id UUID NOT NULL REFERENCES events(id),
    reminder_minutes_before INTEGER DEFAULT 60, -- Minutes before event
    is_enabled BOOLEAN DEFAULT true,
    reminder_sent_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Audit Logs (for compliance & security)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES admin_users(id),
    action VARCHAR(100) NOT NULL, -- 'create_announcement', 'delete_event', etc
    entity_type VARCHAR(50) NOT NULL, -- 'announcement', 'event', 'user', etc
    entity_id UUID,
    old_values JSONB, -- Previous values
    new_values JSONB, -- New values
    ip_address VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create Indexes for Performance
CREATE INDEX idx_announcements_category ON announcements(category);
CREATE INDEX idx_announcements_published_at ON announcements(published_at DESC);
CREATE INDEX idx_announcements_status ON announcements(status);
CREATE INDEX idx_events_date_time ON events(date_time);
CREATE INDEX idx_events_organizer ON events(organizer_id);
CREATE INDEX idx_user_bookmarks_user ON user_bookmarks(user_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_unread ON notifications(user_id, is_read);
CREATE INDEX idx_admin_users_email ON admin_users(email);
CREATE INDEX idx_users_email ON users(email);

-- Full-text Search
CREATE INDEX idx_announcements_search ON announcements USING GIN(
    to_tsvector('english', title || ' ' || description)
);
CREATE INDEX idx_events_search ON events USING GIN(
    to_tsvector('english', title || ' ' || description)
);
```

### 4.3 Database Relationships

```
admin_users
├── announcements (publisher)
├── events (organizer)
├── admin_sessions
└── audit_logs

users
├── user_bookmarks
├── user_preferences
├── notifications
└── event_reminders

announcements
├── user_bookmarks
└── notifications

events
├── user_bookmarks
├── notifications
└── event_reminders

transport_providers
└── (referenced by bus_schedules)

bus_schedules
└── (updates notifications)
```

### 4.4 Database Access Patterns

**Read Heavy (Optimized):**
- Announcements by category
- Events by date range
- Bookmarks by user
- Notifications by user

**Write Operations:**
- Create/update announcements (moderate)
- Create/update events (low-moderate)
- Create notifications (high during peak times)
- User bookmarks (frequent but low impact)

---

## 5. BACKEND SPECIFICATION

### 5.1 Backend Technology: Python FastAPI

**Why FastAPI?**

```
Comparison Matrix:

                Django  FastAPI  Flask
─────────────────────────────────────────
Speed            ★★☆     ★★★★★   ★★☆
Async Support    ★★☆     ★★★★★   ★★☆
Learning Curve   ★★☆     ★★★★☆   ★★★★★
Documentation    ★★★★☆   ★★★★★   ★★★☆
Built-in Auth    ★★★★☆   ★★☆     ★★☆
API Docs Auto    ★★☆     ★★★★★   ★★☆
Production Ready ★★★★★   ★★★★★   ★★★☆
```

**FastAPI Advantages:**
- ⚡ Ultra-fast (async/await)
- 📚 Automatic API documentation (Swagger UI + ReDoc)
- ✅ Built-in data validation (Pydantic)
- 🔒 Built-in OAuth2 + JWT support
- 🧪 Easy to test
- 📦 Modern Python (3.7+)
- 🚀 Perfect for microservices

### 5.2 Backend Project Structure

```
mysun-backend/
├── app/
│   ├── __init__.py
│   ├── main.py              # Application entry point
│   ├── config.py            # Configuration and environment variables
│   ├── database.py          # Database setup and connection
│   ├── security.py          # JWT and authentication
│   │
│   ├── api/
│   │   ├── __init__.py
│   │   ├── v1/              # API v1
│   │   │   ├── __init__.py
│   │   │   ├── announcements.py
│   │   │   ├── events.py
│   │   │   ├── transport.py
│   │   │   ├── bus_schedules.py
│   │   │   ├── notifications.py
│   │   │   ├── bookmarks.py
│   │   │   ├── search.py
│   │   │   ├── auth.py      # Authentication endpoints
│   │   │   └── admin.py     # Admin endpoints
│   │   └── dependencies.py  # Shared dependencies
│   │
│   ├── schemas/             # Pydantic models (request/response)
│   │   ├── __init__.py
│   │   ├── announcement.py
│   │   ├── event.py
│   │   ├── transport.py
│   │   ├── notification.py
│   │   ├── user.py
│   │   ├── admin.py
│   │   └── common.py        # Shared schemas
│   │
│   ├── models/              # SQLAlchemy models (database)
│   │   ├── __init__.py
│   │   ├── user.py
│   │   ├── admin_user.py
│   │   ├── announcement.py
│   │   ├── event.py
│   │   ├── transport.py
│   │   ├── notification.py
│   │   ├── bookmark.py
│   │   ├── audit_log.py
│   │   └── base.py          # Base model class
│   │
│   ├── services/            # Business logic
│   │   ├── __init__.py
│   │   ├── announcement_service.py
│   │   ├── event_service.py
│   │   ├── transport_service.py
│   │   ├── notification_service.py
│   │   ├── auth_service.py
│   │   ├── search_service.py
│   │   ├── file_service.py
│   │   └── admin_service.py
│   │
│   ├── crud/                # Database operations
│   │   ├── __init__.py
│   │   ├── crud_base.py     # Base CRUD class
│   │   ├── announcement.py
│   │   ├── event.py
│   │   ├── transport.py
│   │   ├── user.py
│   │   ├── notification.py
│   │   └── admin_user.py
│   │
│   ├── middleware/
│   │   ├── __init__.py
│   │   ├── error_handler.py
│   │   ├── logging.py
│   │   └── rate_limit.py
│   │
│   ├── utils/
│   │   ├── __init__.py
│   │   ├── validators.py
│   │   ├── email_utils.py   # Email sending (future)
│   │   └── file_utils.py    # File operations
│   │
│   └── tasks/               # Background tasks (Celery - Phase 2)
│       ├── __init__.py
│       ├── notifications.py
│       └── cleanup.py
│
├── migrations/              # Alembic database migrations
│   ├── versions/
│   ├── env.py
│   ├── script.py.mako
│   └── alembic.ini
│
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   ├── test_auth.py
│   ├── test_announcements.py
│   ├── test_events.py
│   ├── test_transport.py
│   └── test_services.py
│
├── storage/                 # File storage directories
│   ├── announcements/
│   ├── events/
│   ├── avatars/
│   └── uploads/
│
├── logs/                    # Application logs
│
├── .env                     # Environment variables (NOT in git)
├── .env.example             # Example environment file
├── .gitignore
├── requirements.txt         # Python dependencies
├── Dockerfile               # Docker configuration
├── docker-compose.yml       # Local development docker
├── nginx.conf               # Nginx configuration
└── README.md
```

### 5.3 Core Endpoints (REST API)

#### Authentication Endpoints
```
POST   /api/v1/auth/login
       Request: { email, password }
       Response: { access_token, refresh_token, admin: {...} }

POST   /api/v1/auth/refresh
       Request: { refresh_token }
       Response: { access_token }

POST   /api/v1/auth/logout
       Request: {}
       Response: { success: true }
```

#### Announcements Endpoints
```
GET    /api/v1/announcements
       Query: category, limit, offset, sort_by
       Response: { items: [...], total, has_more }

GET    /api/v1/announcements/{id}
       Response: { id, title, description, ... }

POST   /api/v1/announcements
       Headers: Authorization
       Request: { title, description, category, image, scheduled_for }
       Response: { id, status: "draft" }

PATCH  /api/v1/announcements/{id}
       Headers: Authorization
       Request: { title, description, category }
       Response: { id, updated_at }

DELETE /api/v1/announcements/{id}
       Headers: Authorization
       Response: { success: true }
```

#### Events Endpoints
```
GET    /api/v1/events
       Query: category, date_from, date_to, limit, offset
       Response: { items: [...], total, has_more }

GET    /api/v1/events/{id}
       Response: { id, title, date_time, venue, ... }

POST   /api/v1/events
       Headers: Authorization
       Request: { title, description, category, date_time, venue, image }
       Response: { id, status: "draft" }

PATCH  /api/v1/events/{id}
       Headers: Authorization
       Request: { title, date_time, venue, ... }
       Response: { id, updated_at }

DELETE /api/v1/events/{id}
       Headers: Authorization
       Response: { success: true }
```

#### Transport Endpoints
```
GET    /api/v1/transport
       Query: limit, offset, sort_by
       Response: { items: [...], total, has_more }

GET    /api/v1/transport/{id}
       Response: { id, name, rating, verified, ... }

GET    /api/v1/bus-schedules
       Query: date (optional), limit, offset
       Response: { items: [...], total }
```

#### Notifications Endpoints
```
GET    /api/v1/notifications
       Headers: Authorization
       Query: limit, offset
       Response: { items: [...], unread_count, total }

PATCH  /api/v1/notifications/{id}/read
       Headers: Authorization
       Response: { id, is_read: true }

DELETE /api/v1/notifications/{id}
       Headers: Authorization
       Response: { success: true }
```

#### Bookmarks Endpoints
```
POST   /api/v1/bookmarks
       Headers: Authorization
       Request: { announcement_id } or { event_id }
       Response: { id, bookmarked_at }

DELETE /api/v1/bookmarks/{id}
       Headers: Authorization
       Response: { success: true }

GET    /api/v1/bookmarks
       Headers: Authorization
       Query: type (announcement|event), limit, offset
       Response: { items: [...], total }
```

#### Search Endpoint
```
GET    /api/v1/search
       Query: q, type (optional: announcement|event|transport)
       Response: { 
           announcements: [...],
           events: [...],
           transport: [...]
       }
```

#### Admin Endpoints
```
GET    /api/v1/admin/dashboard
       Headers: Authorization
       Response: { 
           total_users, 
           total_announcements, 
           engagement_rate,
           recent_activity: [...]
       }

GET    /api/v1/admin/announcements/pending
       Headers: Authorization
       Response: { items: [...] }

PATCH  /api/v1/admin/announcements/{id}/approve
       Headers: Authorization
       Response: { id, status: "approved" }

PATCH  /api/v1/admin/announcements/{id}/reject
       Headers: Authorization
       Request: { reason }
       Response: { id, status: "rejected" }

GET    /api/v1/admin/analytics
       Headers: Authorization
       Query: from_date, to_date
       Response: { 
           views_by_day: [],
           engagement_by_category: {},
           top_announcements: []
       }

GET    /api/v1/admin/audit-logs
       Headers: Authorization
       Query: limit, offset
       Response: { items: [...], total }
```

#### File Upload Endpoint
```
POST   /api/v1/upload
       Headers: Authorization, Content-Type: multipart/form-data
       Request: { file }
       Response: { 
           file_id,
           url: "/storage/announcements/file-id.jpg",
           size,
           mime_type
       }
```

### 5.4 Authentication & Security

#### JWT Token Structure
```python
{
    "sub": "admin_user_id",           # Subject (user ID)
    "email": "admin@sorotiu.ac.ug",
    "role": "publisher",               # super_admin, moderator, publisher
    "department": "academic",
    "exp": 1234567890,                # Expiration
    "iat": 1234567800,                # Issued at
    "jti": "unique-token-id"          # Token ID (for revocation)
}
```

#### Request/Response Format
```python
# Request with Bearer Token
GET /api/v1/admin/dashboard
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...

# Response with Status Code
{
    "success": true,
    "data": { ... },
    "message": "Operation successful"
}

# Error Response
{
    "success": false,
    "error": {
        "code": "UNAUTHORIZED",
        "message": "Invalid or expired token",
        "details": "..."
    }
}
```

#### Security Features
- **Password Hashing:** bcrypt with salt rounds = 12
- **Token Expiry:** Access token = 24 hours, Refresh token = 30 days
- **Rate Limiting:** 100 requests/minute per IP (configurable)
- **Input Validation:** Pydantic for all inputs
- **CORS:** Configured for specific frontend origins
- **HTTPS:** Required for all production requests
- **SQL Injection Protection:** SQLAlchemy ORM prevents SQL injection

### 5.5 Database Connection & ORM

```python
# config.py
DATABASE_URL = "postgresql://user:password@localhost:5432/mysun_db"

# database.py
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, Session

engine = create_engine(
    DATABASE_URL,
    echo=False,
    pool_size=20,
    max_overflow=40,
    pool_pre_ping=True  # Verify connections
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db() -> Session:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
```

### 5.6 Service Layer Example

```python
# services/announcement_service.py
from typing import List, Optional
from sqlalchemy.orm import Session
from app.models.announcement import Announcement
from app.schemas.announcement import AnnouncementCreate, AnnouncementUpdate
from app.crud.announcement import crud_announcement

class AnnouncementService:
    def __init__(self, db: Session):
        self.db = db
        self.crud = crud_announcement

    async def get_announcements(
        self, 
        category: Optional[str] = None,
        limit: int = 20,
        offset: int = 0
    ) -> List[Announcement]:
        query = self.db.query(Announcement).filter(
            Announcement.status == "published"
        )
        
        if category:
            query = query.filter(Announcement.category == category)
        
        return query.order_by(
            Announcement.published_at.desc()
        ).limit(limit).offset(offset).all()

    async def create_announcement(
        self,
        admin_id: str,
        data: AnnouncementCreate
    ) -> Announcement:
        db_announcement = Announcement(
            title=data.title,
            description=data.description,
            category=data.category,
            publisher_id=admin_id,
            status="pending_review"  # Requires moderation
        )
        self.db.add(db_announcement)
        self.db.commit()
        self.db.refresh(db_announcement)
        return db_announcement

    async def approve_announcement(
        self,
        announcement_id: str,
        admin_id: str
    ) -> Announcement:
        announcement = self.db.query(Announcement).filter(
            Announcement.id == announcement_id
        ).first()
        
        if not announcement:
            raise ValueError("Announcement not found")
        
        announcement.status = "approved"
        announcement.published_at = datetime.utcnow()
        self.db.commit()
        
        # Log audit action
        self._log_audit("approve_announcement", announcement_id, admin_id)
        
        return announcement
```

### 5.7 Error Handling

```python
# errors/exceptions.py
class MySunException(Exception):
    """Base exception"""
    def __init__(self, message: str, code: str = "INTERNAL_ERROR"):
        self.message = message
        self.code = code

class ResourceNotFound(MySunException):
    def __init__(self, resource: str):
        super().__init__(f"{resource} not found", "NOT_FOUND")

class UnauthorizedError(MySunException):
    def __init__(self):
        super().__init__("Unauthorized access", "UNAUTHORIZED")

class ValidationError(MySunException):
    def __init__(self, message: str):
        super().__init__(message, "VALIDATION_ERROR")

# middleware/error_handler.py
@app.exception_handler(MySunException)
async def mysun_exception_handler(request: Request, exc: MySunException):
    return JSONResponse(
        status_code=status.HTTP_400_BAD_REQUEST,
        content={
            "success": False,
            "error": {
                "code": exc.code,
                "message": exc.message
            }
        }
    )
```

---

## 6. FRONTEND SPECIFICATION

### 6.1 Student App (Flutter Mobile)

#### Technology
- **Framework:** Flutter 3.x
- **Language:** Dart 3.x
- **State Management:** Riverpod 2.x
- **Navigation:** go_router 10.x
- **UI:** Material Design 3
- **Local Storage:** Hive + SharedPreferences
- **HTTP Client:** Dio 5.x

#### Key Screens

1. **Splash Screen**
   - App logo and branding
   - Loading animation
   - Check onboarding completion

2. **Home Feed**
   - Personalized greeting
   - Quick status (next event, unread count, bus time)
   - Category filters (chips)
   - Announcement feed (infinite scroll)
   - Pull-to-refresh

3. **Announcement Detail**
   - Full content with image
   - Category and publisher info
   - Date and timestamp
   - Bookmark button
   - Share button

4. **Events Discovery**
   - Search by name, organizer, venue
   - Category filters
   - Date filters (Today, Tomorrow, This Week)
   - Event cards with countdown
   - Sort options

5. **Event Detail**
   - Large event image
   - Full details (date, time, venue, organizer)
   - Countdown timer
   - "Add to Calendar" button
   - Reminder settings
   - Location (placeholder for map)
   - Description

6. **Transport Directory**
   - Next bus departure card
   - Transport provider list
   - Rating display
   - Verification badge
   - Call button (UI only)
   - Sort and filter options

7. **Bus Schedule**
   - All departures for the day
   - Date filter (Today, Tomorrow, etc)
   - Route search
   - Sort by time
   - Time, route, destination, status

8. **Saved Items**
   - Two tabs: News, Events
   - Bookmarked announcements
   - Bookmarked events
   - Empty state
   - Remove functionality

9. **Notifications**
   - All notifications list
   - Read/unread indicators
   - Type icons
   - Timestamps
   - Mark as read
   - Dismiss functionality

10. **Profile & Settings**
    - User profile section (name, email, faculty)
    - Theme toggle (Light/Dark/System)
    - Notification preferences
    - Category preferences
    - About section
    - Links to Privacy, Terms, Help

11. **Search**
    - Global search across announcements, events, transport
    - Search suggestions
    - Results grouped by type
    - No-results state

#### Local Storage Strategy

```dart
// Hive Boxes
- bookmarks_box      // User's bookmarked announcements/events
- announcements_box  // Cached announcements
- events_box         // Cached events

// SharedPreferences
- user_name
- theme_mode
- notifications_enabled
- event_reminders_enabled
- selected_categories (JSON array)
- onboarding_completed
- last_sync_time
- user_id (temporary until auth)
```

#### State Management (Riverpod)

```dart
// Providers for data
final announcementsProvider = FutureProvider<List<Announcement>>((ref) async {
    final repository = ref.watch(announcementRepositoryProvider);
    return repository.getAnnouncements();
});

// Providers for UI state
final selectedCategoryProvider = StateProvider<String>((ref) => 'All');

// Providers for mutations
final bookmarkAnnouncementProvider = FutureProvider.autoDispose<void>(
    (ref) async {
        // Implementation
    }
);
```

### 6.2 Admin Portal (Flutter Web)

#### Technology
- Same as student app (Flutter Web)
- Responsive layout for desktop/tablet
- Sidebar navigation
- Admin-specific widgets

#### Key Sections

1. **Login Page**
   - Email and password fields
   - Remember me option
   - Forgot password link
   - Error messages

2. **Dashboard**
   - Key metrics cards (users, announcements, engagement)
   - Charts (announcements over time, category breakdown)
   - Recent activity feed
   - Upcoming events

3. **Content Management**
   - Announcements list with status
   - Create/edit announcement form
   - Preview before publishing
   - Schedule publishing
   - Bulk import (CSV)

4. **Events Management**
   - Events list
   - Create/edit event form
   - Rich editor for description
   - Image upload
   - Capacity and registration
   - Recurring event setup

5. **Moderation Queue**
   - Pending content list
   - Review interface
   - Approve/reject buttons
   - Add feedback/notes
   - Policy checker

6. **Analytics Dashboard**
   - Engagement metrics
   - Views over time
   - Top performing content
   - User demographics
   - Download reports (PDF/CSV)

7. **Settings**
   - Manage categories
   - Transport provider management
   - Bus schedule management
   - System settings
   - Email configuration

8. **User Management** (Super Admin)
   - List all admin users
   - Create new admin
   - Assign roles
   - Reset passwords
   - View login history
   - Disable users

9. **Audit Logs**
   - Filter by user, action, date
   - View what changed
   - Revert capability (future)
   - Export logs

---

## 7. ADMIN PORTAL

### 7.1 User Roles & Permissions

| Role | Permission Level | Capabilities |
|------|------------------|--------------|
| **Super Admin** | Full | All operations, user management, system settings |
| **Content Moderator** | High | Approve/reject content, view analytics, manage users |
| **Department Admin** | Medium | Create announcements for own department, view own analytics |
| **Event Organizer** | Low | Create events, manage own events |
| **Transport Admin** | Low | Manage transport providers, update schedules |

### 7.2 Content Publishing Workflow

```
1. CREATE
   Publisher writes announcement/event
   Saves as DRAFT

2. SUBMIT
   Publisher submits for review
   Status: PENDING_REVIEW

3. AUTOMATIC CHECKS
   System validates:
   - Title length
   - Image format/size
   - Required fields
   - Policy keywords

4. MANUAL REVIEW (if enabled)
   Moderator reviews content
   Adds feedback if needed
   
5. DECISION
   If approved: Status = APPROVED
   If rejected: Status = REJECTED + reason

6. PUBLISH
   Moderator publishes immediately
   Or: Publisher scheduled publish for later
   Notification sent to users

7. LIVE
   Appears in student app feed
   Analytics tracking starts
```

### 7.3 Admin Panel Features

#### Content Management
- Easy form-based creation
- Rich text editor (future)
- Image upload and preview
- Schedule for future publication
- Edit and republish
- Delete with confirmation
- Bulk actions (import from CSV)
- Version history

#### Moderation
- Queue of pending items
- Clear review interface
- Policy checklist
- Feedback/comments
- Approve/reject with reasons
- Assign to specific moderator
- Audit trail

#### Analytics
- Real-time metrics
- Views per announcement/event
- Engagement rate
- Click-through rate
- User demographics (future)
- Reports export
- Trend analysis

#### User Management
- Create/edit/delete admin users
- Assign roles and permissions
- Manage departments
- Reset passwords
- View login history
- Activity logs per user
- Suspend/reactivate accounts

---

## 8. SECURITY & ACCESS CONTROL

### 8.1 Authentication

```
Login Flow:
1. User enters email + password
2. Backend validates credentials (bcrypt comparison)
3. Backend generates JWT token (access + refresh)
4. Frontend stores token securely
5. Frontend sends token in Authorization header for all requests

Token Expiry:
- Access Token: 24 hours
- Refresh Token: 30 days
- On token expiry, frontend uses refresh token to get new access token
- If refresh token expired, user must login again
```

### 8.2 Authorization (RBAC)

```
Role-Based Access Control:

super_admin
  └─ Can access everything
  └─ Can create/manage users
  └─ Can configure system settings

moderator
  └─ Can review and approve content
  └─ Can view analytics
  └─ Cannot create announcements

department_admin
  └─ Can create announcements for own department
  └─ Cannot see other departments' analytics
  └─ Cannot approve content

event_organizer
  └─ Can create events
  └─ Can manage own events
  └─ Cannot manage announcements

transport_admin
  └─ Can manage transport providers
  └─ Can update bus schedules
  └─ Cannot modify other content

student (app user)
  └─ Can read announcements/events
  └─ Can bookmark items
  └─ Can set reminders
  └─ Cannot publish content
```

### 8.3 Data Protection

**In Transit:**
- HTTPS/TLS 1.3 for all connections
- Certificate management via Let's Encrypt

**At Rest:**
- Database: Encryption at rest (optional PostgreSQL)
- Files: Stored on secure filesystem
- Credentials: Never logged, hashed with bcrypt

**Privacy:**
- No unnecessary data collection
- User data isolated by user ID
- Audit logs for compliance
- Privacy policy included in app

### 8.4 Secure Coding Practices

- SQL Injection: Prevented by ORM (SQLAlchemy)
- XSS: Prevented by Flutter framework
- CSRF: Handled by same-origin policy + CORS
- Input Validation: Pydantic on backend
- Error Messages: Generic messages in production, detailed in logs
- Logging: Never log sensitive data (passwords, tokens)

---

## 9. AUTHENTICATION & LOGIN SYSTEM

### 9.1 Student Authentication (App Users)

#### 9.1.1 Student Signup Flow

**Scenario:** New student wants to use MySun app

```
Step 1: Student Opens App
  ↓
Step 2: Sign Up Screen
  - Enter: Email address
  - Enter: Name
  - Enter: Student ID (optional, for future verification)
  - Enter: Password (min 8 chars)
  - Accept: Terms & Privacy
  ↓
Step 3: Validation (Backend)
  - Email format valid?
  - Email not already registered?
  - Password strength check
  - Rate limiting check
  ↓
Step 4: Send Verification Email
  - Generate 6-digit OTP or verification link
  - Send to student email
  - Store OTP with expiry (15 minutes)
  ↓
Step 5: Student Verifies Email
  - Enter OTP in app
  - Or click link in email
  ↓
Step 6: Account Created
  - User marked as verified
  - Create user preferences record
  - Redirect to onboarding or home screen
  ↓
Step 7: Session Started
  - Generate JWT tokens
  - Store in secure storage
  - Student can now use app
```

#### 9.1.2 Student Login Flow

**Scenario:** Returning student logs in

```
POST /api/v1/auth/login
Request: {
    "email": "student@sorotiu.ac.ug",
    "password": "SecurePass123!"
}

Backend Process:
1. Find user by email
2. Compare password hash with bcrypt
3. Check if account is active (not suspended)
4. Check if account is verified
5. Generate tokens:
   - access_token (expires in 24 hours)
   - refresh_token (expires in 30 days)
6. Update last_login timestamp
7. Log login event to audit trail

Response: {
    "success": true,
    "access_token": "eyJhbGciOiJIUzI1NiIs...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIs...",
    "user": {
        "id": "user-uuid",
        "email": "student@sorotiu.ac.ug",
        "name": "John Doe",
        "student_id": "ST-2024-001",
        "verified": true
    }
}
```

#### 9.1.3 Student Password Reset

**Scenario:** Student forgot password

```
POST /api/v1/auth/forgot-password
Request: { "email": "student@sorotiu.ac.ug" }

Backend:
1. Find user by email
2. Generate reset token (unique, expires in 1 hour)
3. Send reset link via email: 
   mysun.sorotiu.ac.ug/reset-password?token=xyz123
4. Store reset token in database
5. Return success message (don't reveal if email exists)

---

Student clicks email link:
1. Extracts token from URL
2. Verifies token is valid and not expired
3. Shows new password form
4. Student enters new password
5. Frontend sends:

POST /api/v1/auth/reset-password
Request: {
    "token": "xyz123",
    "new_password": "NewSecurePass456!"
}

Backend:
1. Verify token is valid
2. Hash new password with bcrypt
3. Update password in database
4. Invalidate all existing sessions (logout everywhere)
5. Delete reset token
6. Send confirmation email
7. Redirect to login screen
```

#### 9.1.4 Student Session Management

**Token Refresh Flow:**

When access token expires (24 hours):

```
POST /api/v1/auth/refresh
Request: { "refresh_token": "eyJhbGciOiJIUzI1NiIs..." }

Backend:
1. Verify refresh token is valid and not expired
2. Check if user still exists and is active
3. Generate new access_token
4. Optionally generate new refresh_token

Response: {
    "access_token": "new-token-xyz",
    "refresh_token": "new-refresh-token-abc"
}

Frontend:
1. Automatically stores new tokens
2. Continues operation
3. User doesn't see any interruption
```

**Logout Flow:**

```
POST /api/v1/auth/logout
Headers: { "Authorization": "Bearer access_token" }

Backend:
1. Extract user ID from token
2. Optionally: Invalidate refresh tokens (revocation list)
3. Log logout event to audit trail
4. Return success

Frontend:
1. Clear stored tokens
2. Clear user data from storage
3. Redirect to login screen
```

#### 9.1.5 Student Database Schema Addition

```sql
-- Add these columns to users table
ALTER TABLE users ADD COLUMN (
    password_hash VARCHAR(500) NOT NULL,
    email_verified BOOLEAN DEFAULT false,
    email_verified_at TIMESTAMP,
    is_active BOOLEAN DEFAULT true,
    last_login TIMESTAMP,
    login_count INTEGER DEFAULT 0,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP
);

-- Create password reset tokens table
CREATE TABLE password_reset_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    token_hash VARCHAR(500) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    used_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create login audit table
CREATE TABLE login_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    email VARCHAR(255),
    login_type VARCHAR(50), -- 'success', 'failed', 'password_reset'
    ip_address VARCHAR(50),
    user_agent VARCHAR(500),
    device_type VARCHAR(50), -- 'iOS', 'Android', 'Web'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indices
CREATE INDEX idx_password_reset_tokens_user ON password_reset_tokens(user_id);
CREATE INDEX idx_login_audit_user ON login_audit(user_id);
CREATE INDEX idx_login_audit_timestamp ON login_audit(created_at DESC);
```

---

### 9.2 Admin Authentication (Staff Users)

#### 9.2.1 Admin User Creation (Super Admin Only)

**Scenario:** Super Admin creates new admin user

```
POST /api/v1/admin/users
Headers: { "Authorization": "Bearer admin_token" }
Request: {
    "email": "dept_admin@sorotiu.ac.ug",
    "name": "Dr. Jane Smith",
    "role": "publisher", -- 'super_admin', 'moderator', 'publisher', 'transport_admin'
    "department": "Academic Affairs", -- Required for department admins
    "initial_password": "TempPassword123!" -- System generated
}

Backend:
1. Verify requester is super_admin
2. Validate email not already registered
3. Hash initial password
4. Create admin_user record
5. Generate temporary access token (expires in 24 hours)
6. Send email with:
   - Login instructions
   - Temporary password
   - Link to change password
   - Admin portal URL

Response: {
    "id": "admin-uuid",
    "email": "dept_admin@sorotiu.ac.ug",
    "role": "publisher",
    "temporary_password": "TempPassword123!",
    "password_expires_in_hours": 24
}
```

#### 9.2.2 Admin First-Time Login

**Scenario:** Admin logs in for first time with temporary password

```
POST /api/v1/admin/auth/login
Request: {
    "email": "dept_admin@sorotiu.ac.ug",
    "password": "TempPassword123!"
}

Backend:
1. Verify credentials
2. Check if password is temporary
3. If temporary, return special response:

Response: {
    "success": true,
    "requires_password_change": true,
    "access_token": "short-lived-token-xyz",
    "message": "You must change your password before continuing"
}

Frontend:
1. Redirects to force password change screen
2. User enters new password
3. Sends:

POST /api/v1/admin/auth/change-password
Request: {
    "current_password": "TempPassword123!",
    "new_password": "MyNewSecurePass456!",
    "confirm_password": "MyNewSecurePass456!"
}

Backend:
1. Verify current password
2. Mark password as permanent
3. Update password_changed_at timestamp
4. Generate full access and refresh tokens

Response: {
    "success": true,
    "access_token": "new-full-token-abc",
    "refresh_token": "refresh-token-def",
    "admin": { admin_user object }
}
```

#### 9.2.3 Admin Regular Login

**Scenario:** Admin logs in with permanent password

```
POST /api/v1/admin/auth/login
Request: {
    "email": "dept_admin@sorotiu.ac.ug",
    "password": "MyNewSecurePass456!"
}

Backend Process:
1. Find admin_user by email
2. Verify password hash with bcrypt
3. Check if account is active
4. Check if password is not expired (require change every 90 days)
5. Check if account is not locked (after 5 failed attempts)
6. Generate access_token and refresh_token
7. Update last_login and increment login_count
8. Create login audit log with IP address and user agent

Response: {
    "success": true,
    "access_token": "jwt-token...",
    "refresh_token": "jwt-token...",
    "admin": {
        "id": "admin-uuid",
        "email": "dept_admin@sorotiu.ac.ug",
        "name": "Dr. Jane Smith",
        "role": "publisher",
        "department": "Academic Affairs",
        "permissions": ["create_announcements", "edit_own_announcements"]
    }
}
```

#### 9.2.4 Admin Session Management

**Token Refresh:**

```
POST /api/v1/admin/auth/refresh
Request: { "refresh_token": "..." }

Same as student, but:
- Verify admin_user exists and is active
- Check admin role still has permissions
- Generate new tokens
```

**Logout:**

```
POST /api/v1/admin/auth/logout
Headers: { "Authorization": "Bearer admin_token" }

Backend:
1. Verify token
2. Optionally add token to revocation list
3. Log logout event with timestamp and duration
4. Return success
```

#### 9.2.5 Admin Password Security

**Password Requirements:**
- Minimum 12 characters (strict for admin accounts)
- Must contain: uppercase, lowercase, numbers, special characters
- Cannot contain email or username
- Cannot reuse last 5 passwords
- Must be changed every 90 days
- History tracked for audit

**Password Change Flow:**

```
POST /api/v1/admin/auth/change-password
Headers: { "Authorization": "Bearer admin_token" }
Request: {
    "current_password": "...",
    "new_password": "...",
    "confirm_password": "..."
}

Validations:
1. Current password matches
2. New password is strong enough
3. New password is different from current
4. Not in password history
5. Confirm password matches

Backend:
1. Update password_hash
2. Update password_changed_at
3. Clear failed_login_attempts
4. Log password change to audit trail
5. Send confirmation email
```

#### 9.2.6 Admin Account Lockout

**After 5 failed login attempts:**

```
Backend Logic:
1. Increment failed_login_attempts counter
2. If failed_login_attempts >= 5:
   - Set account_locked_until = now + 30 minutes
   - Send email: "Your account is temporarily locked"
   - Return 429 (Too Many Requests)
3. User sees: "Too many failed attempts. Try again in 30 minutes."

Recovery:
- Super admin can manually unlock
- Or wait 30 minutes for auto-unlock
- System sends unlock confirmation email
- failed_login_attempts counter resets
```

#### 9.2.7 Admin Database Schema Addition

```sql
-- Expand admin_users table
ALTER TABLE admin_users ADD COLUMN (
    password_hash VARCHAR(500) NOT NULL,
    is_temporary_password BOOLEAN DEFAULT true,
    password_changed_at TIMESTAMP,
    password_expires_at TIMESTAMP,
    last_login TIMESTAMP,
    login_count INTEGER DEFAULT 0,
    failed_login_attempts INTEGER DEFAULT 0,
    account_locked_until TIMESTAMP,
    requires_password_change BOOLEAN DEFAULT true
);

-- Create admin password history table
CREATE TABLE admin_password_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES admin_users(id),
    password_hash VARCHAR(500) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create admin session table
CREATE TABLE admin_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID NOT NULL REFERENCES admin_users(id),
    access_token_hash VARCHAR(500),
    refresh_token_hash VARCHAR(500),
    ip_address VARCHAR(50),
    user_agent VARCHAR(500),
    device_type VARCHAR(50),
    last_activity TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create admin login audit table
CREATE TABLE admin_login_audit (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_user_id UUID REFERENCES admin_users(id),
    email VARCHAR(255),
    login_type VARCHAR(50), -- 'success', 'failed', 'lockout', 'password_reset'
    failure_reason VARCHAR(200),
    ip_address VARCHAR(50),
    user_agent VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indices
CREATE INDEX idx_admin_password_history_user ON admin_password_history(admin_user_id);
CREATE INDEX idx_admin_sessions_user ON admin_sessions(admin_user_id);
CREATE INDEX idx_admin_sessions_expiry ON admin_sessions(expires_at);
CREATE INDEX idx_admin_login_audit_user ON admin_login_audit(admin_user_id);
CREATE INDEX idx_admin_login_audit_timestamp ON admin_login_audit(created_at DESC);
```

---

### 9.3 Two-Factor Authentication (Phase 2)

**For Phase 1: Prepared but not implemented**

```
POST /api/v1/admin/auth/2fa/setup
Headers: { "Authorization": "Bearer admin_token" }

Frontend flow:
1. Admin requests 2FA setup
2. Backend generates QR code (TOTP secret)
3. Admin scans with authenticator app (Google Authenticator, Authy, etc.)
4. Admin enters 6-digit code to verify
5. Backend generates backup codes (10 one-time codes)
6. Admin saves backup codes somewhere safe
7. 2FA enabled on next login

Login with 2FA:
1. Enter email + password
2. Backend returns: "2FA required"
3. User enters 6-digit code from authenticator app
4. Backend verifies TOTP code is valid
5. Issue tokens

Backup codes used if phone is lost
```

---

### 9.4 University SSO Integration (Phase 2)

**Planned for future enhancement:**

```
Current (Phase 1):
- Email/password authentication

Phase 2 Options:
1. LDAP Integration (connects to university directory)
   - Login with university credentials
   - Automatic department assignment
   - Sync user roles from LDAP

2. Shibboleth Integration
   - University's existing SSO
   - Redirect to university login page
   - Auto-populate user data

3. OAuth2/OIDC Integration
   - Google Workspace (if university uses)
   - Microsoft Azure AD (if university uses)
   - Custom university provider

Architecture prepared:
- Abstract authentication layer
- Can swap providers without frontend changes
- User data mapped from SSO attributes
```

---

### 9.5 Security Best Practices for Authentication

#### Session Hijacking Prevention
```python
# Backend: Validate every token
def verify_token(token: str):
    try:
        payload = jwt.decode(
            token, 
            SECRET_KEY, 
            algorithms=["HS256"]
        )
        # Verify token hasn't been revoked
        if is_token_revoked(payload.get("jti")):
            raise InvalidCredentialsException()
        
        # Verify device fingerprint matches
        if payload.get("device_fp") != get_device_fingerprint():
            raise InvalidCredentialsException()
        
        return payload
    except JWTError:
        raise InvalidCredentialsException()
```

#### Brute Force Protection
```python
# Rate limiting on login endpoint
@app.post("/api/v1/auth/login")
@rate_limit(max_requests=5, window=900)  # 5 attempts per 15 minutes
async def login(credentials: LoginRequest):
    # Check account lockout
    if is_account_locked(credentials.email):
        raise AccountLockedException()
    
    # Validate credentials
    if not validate_password(credentials):
        increment_failed_attempts(credentials.email)
        raise InvalidCredentialsException()
    
    # Success: reset counter
    reset_failed_attempts(credentials.email)
    return tokens
```

#### Token Storage (Frontend)
```dart
// Flutter - Secure storage
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _secureStorage = FlutterSecureStorage();

Future<void> saveTokens(String accessToken, String refreshToken) async {
  await _secureStorage.write(key: 'access_token', value: accessToken);
  await _secureStorage.write(key: 'refresh_token', value: refreshToken);
}

Future<String?> getAccessToken() async {
  return await _secureStorage.read(key: 'access_token');
}

Future<void> clearTokens() async {
  await _secureStorage.delete(key: 'access_token');
  await _secureStorage.delete(key: 'refresh_token');
}

// NEVER store in SharedPreferences (not secure)
// NEVER store in plain text
// NEVER log tokens
```

#### Token Revocation
```python
# Maintain revocation list (Phase 2 with Redis)
# When user logs out or admin disables account
revoked_tokens = set()

def revoke_token(jti: str):
    revoked_tokens.add(jti)

def is_token_revoked(jti: str):
    return jti in revoked_tokens

# Clean up expired tokens periodically
def cleanup_revoked_tokens():
    current_time = datetime.utcnow()
    revoked_tokens = [
        jti for jti in revoked_tokens 
        if get_token_expiry(jti) > current_time
    ]
```

---

### 9.6 Authentication API Endpoints

#### Student Auth Endpoints

```
POST   /api/v1/auth/signup
       Request: { email, name, password, terms_accepted }
       Response: { user_id, verification_sent: true }

POST   /api/v1/auth/verify-email
       Request: { email, otp }
       Response: { success: true, user: {...} }

POST   /api/v1/auth/login
       Request: { email, password }
       Response: { access_token, refresh_token, user: {...} }

POST   /api/v1/auth/refresh
       Request: { refresh_token }
       Response: { access_token, refresh_token }

POST   /api/v1/auth/logout
       Request: {}
       Response: { success: true }

POST   /api/v1/auth/forgot-password
       Request: { email }
       Response: { success: true, message: "Check your email" }

POST   /api/v1/auth/reset-password
       Request: { token, new_password }
       Response: { success: true }

GET    /api/v1/auth/me
       Headers: Authorization
       Response: { user: {...} }
```

#### Admin Auth Endpoints

```
POST   /api/v1/admin/auth/login
       Request: { email, password }
       Response: { access_token, refresh_token, requires_password_change?, admin: {...} }

POST   /api/v1/admin/auth/refresh
       Request: { refresh_token }
       Response: { access_token, refresh_token }

POST   /api/v1/admin/auth/logout
       Request: {}
       Response: { success: true }

POST   /api/v1/admin/auth/change-password
       Headers: Authorization
       Request: { current_password, new_password, confirm_password }
       Response: { success: true }

POST   /api/v1/admin/auth/forgot-password
       Request: { email }
       Response: { success: true }

POST   /api/v1/admin/auth/reset-password
       Request: { token, new_password }
       Response: { success: true }

POST   /api/v1/admin/auth/2fa/setup
       Headers: Authorization
       Response: { qr_code, backup_codes: [...] }

POST   /api/v1/admin/auth/2fa/verify
       Headers: Authorization
       Request: { code }
       Response: { success: true }

GET    /api/v1/admin/auth/me
       Headers: Authorization
       Response: { admin: {...}, permissions: [...] }
```

---

### 9.7 Authentication Checklist for Development

**Backend:**
- [ ] Password hashing (bcrypt with rounds=12)
- [ ] JWT token generation and validation
- [ ] Email verification system
- [ ] Password reset flow
- [ ] Token refresh mechanism
- [ ] Session management
- [ ] Account lockout after failed attempts
- [ ] Audit logging
- [ ] Rate limiting
- [ ] CORS configuration
- [ ] Password strength validation
- [ ] Admin password requirements (strict)

**Frontend - Student App:**
- [ ] Sign up screen with validation
- [ ] Email verification screen
- [ ] Login screen
- [ ] Forgot password screen
- [ ] Password reset screen
- [ ] Secure token storage (SecureStorage)
- [ ] Automatic token refresh
- [ ] Logout functionality
- [ ] Session timeout handling
- [ ] Biometric authentication preparation (future)

**Frontend - Admin Portal:**
- [ ] Admin login screen
- [ ] Force password change screen
- [ ] Change password screen
- [ ] Forgot password screen
- [ ] 2FA setup screen (Phase 2)
- [ ] Admin session management
- [ ] Automatic logout on inactivity

**Testing:**
- [ ] Test valid login
- [ ] Test invalid credentials
- [ ] Test account lockout
- [ ] Test token expiry and refresh
- [ ] Test password reset flow
- [ ] Test email verification
- [ ] Test concurrent sessions (same user, different devices)
- [ ] Test admin password requirements
- [ ] Test rate limiting
- [ ] Security penetration testing (before production)

---

## 10. DEPLOYMENT & HOSTING

### 9.1 Hosting Architecture

```
Soroti University On-Premises Servers

┌──────────────────────────────────────────────┐
│         Nginx Reverse Proxy                   │
│  - SSL/TLS termination                        │
│  - Load balancing                             │
│  - Static file serving                        │
└──────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────┐
│    Docker Container (Backend API)             │
│  - Python 3.11                                │
│  - FastAPI application                        │
│  - Running on :8000                           │
└──────────────────────────────────────────────┘
          ↓
┌──────────────────────────────────────────────┐
│      PostgreSQL Database                      │
│  - Port 5432                                  │
│  - Data persistence                           │
│  - Regular backups                            │
└──────────────────────────────────────────────┘

Local Filesystem Storage:
/var/mysun/storage/
├── announcements/
├── events/
├── avatars/
└── uploads/

SSL Certificates:
/etc/letsencrypt/live/mysun.sorotiu.ac.ug/
```

### 9.2 Deployment Process

#### Prerequisites
- Ubuntu 20.04 or 22.04 server
- Python 3.11+
- PostgreSQL 14+
- Docker & Docker Compose
- Nginx
- Git

#### Initial Setup

```bash
# 1. Clone repository
git clone https://github.com/sorotiu/mysun-backend.git
cd mysun-backend

# 2. Create .env file
cp .env.example .env
# Edit .env with your configuration

# 3. Create directory structure
mkdir -p /var/mysun/storage/{announcements,events,avatars,uploads}
mkdir -p /var/mysun/logs

# 4. Build Docker image
docker build -t mysun-api:latest .

# 5. Run database migrations
docker run --rm \
  --env-file .env \
  -v $(pwd)/migrations:/app/migrations \
  mysun-api:latest \
  alembic upgrade head

# 6. Start services
docker-compose up -d
```

#### Docker Compose Configuration

```yaml
version: '3.8'

services:
  db:
    image: postgres:15
    container_name: mysun_db
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    ports:
      - "5432:5432"
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5

  api:
    build: .
    container_name: mysun_api
    environment:
      - DATABASE_URL=postgresql://${DB_USER}:${DB_PASSWORD}@db:5432/${DB_NAME}
      - JWT_SECRET=${JWT_SECRET}
      - API_ENV=production
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - /var/mysun/storage:/app/storage
      - /var/mysun/logs:/app/logs
    ports:
      - "8000:8000"
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  nginx:
    image: nginx:alpine
    container_name: mysun_nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - /etc/letsencrypt:/etc/letsencrypt:ro
      - /var/mysun/storage:/usr/share/nginx/html/storage:ro
    depends_on:
      - api
    restart: unless-stopped

volumes:
  postgres_data:
```

#### Nginx Configuration

```nginx
# /etc/nginx/sites-available/mysun

upstream backend {
    server api:8000;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name mysun.sorotiu.ac.ug;
    
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }
    
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS
server {
    listen 443 ssl http2;
    server_name mysun.sorotiu.ac.ug;
    
    ssl_certificate /etc/letsencrypt/live/mysun.sorotiu.ac.ug/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/mysun.sorotiu.ac.ug/privkey.pem;
    
    # Security headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # API proxy
    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static file serving
    location /storage/ {
        alias /usr/share/nginx/html/storage/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # Admin portal (if using separate domain or path)
    location /admin/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
    }
}
```

### 9.3 SSL/TLS Certificate Setup

```bash
# Install certbot
sudo apt-get install certbot python3-certbot-nginx

# Generate certificate (Let's Encrypt - free)
sudo certbot certonly --standalone \
  -d mysun.sorotiu.ac.ug \
  --agree-tos \
  --email admin@sorotiu.ac.ug

# Auto-renewal (runs daily)
sudo systemctl enable certbot.timer
```

### 9.4 Backup Strategy

```bash
# Daily database backup (cron job)
0 2 * * * docker exec mysun_db pg_dump -U $DB_USER $DB_NAME | gzip > /backups/mysun_$(date +\%Y\%m\%d).sql.gz

# Weekly storage backup
0 3 * * 0 tar -czf /backups/storage_$(date +\%Y\%m\%d).tar.gz /var/mysun/storage

# Keep 30 days of backups
find /backups -name "mysun_*.sql.gz" -mtime +30 -delete
```

### 9.5 Monitoring & Logging

```python
# FastAPI logging configuration
import logging

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/mysun/logs/mysun.log'),
        logging.StreamHandler()
    ]
)

logger = logging.getLogger(__name__)
```

---

## 10. IMPLEMENTATION ROADMAP

### Phase 1: MVP (Weeks 1-4)
**Backend Development (2 weeks)**
- [ ] Project setup and configuration
- [ ] Database schema creation and migration
- [ ] Authentication system (login, JWT)
- [ ] Core services (announcements, events, transport)
- [ ] API endpoints (GET, POST, PATCH, DELETE)
- [ ] File upload service
- [ ] Error handling and logging
- [ ] Basic documentation
- [ ] Docker setup

**Frontend Development (3 weeks)**
- [ ] Project setup and theme
- [ ] Navigation and routing
- [ ] Reusable components
- [ ] Home feed screen
- [ ] Event discovery and detail
- [ ] Transport directory
- [ ] Bookmarks and saved items
- [ ] Profile and settings
- [ ] Local storage integration
- [ ] Mock data and API integration preparation

**Deployment (1 week)**
- [ ] Server setup
- [ ] Database setup
- [ ] SSL certificates
- [ ] Docker deployment
- [ ] Testing on devices
- [ ] Documentation

**Phase 1 Deliverables:**
- ✅ Functional student app (iOS + Android)
- ✅ Working backend API
- ✅ Basic admin interface
- ✅ Self-hosted infrastructure
- ✅ Real-time announcement publishing

### Phase 2: Enhancement (Weeks 5-8)
**Backend:**
- [ ] Push notification system (Firebase Cloud Messaging)
- [ ] Advanced search with full-text indexing
- [ ] Real-time updates (WebSocket)
- [ ] Moderation workflow
- [ ] Analytics engine
- [ ] Email notifications
- [ ] Performance optimization
- [ ] Caching (Redis)

**Frontend:**
- [ ] Push notification handling
- [ ] Advanced filters
- [ ] Real-time feed updates
- [ ] Offline support
- [ ] Analytics dashboard (admin)
- [ ] Content moderation interface
- [ ] Enhanced search
- [ ] Performance optimization

**Deployment:**
- [ ] Production hardening
- [ ] Performance monitoring
- [ ] Automated backups
- [ ] Load testing

**Phase 2 Deliverables:**
- ✅ Push notifications
- ✅ Advanced search
- ✅ Real-time updates
- ✅ Moderation workflow
- ✅ Analytics dashboard

### Phase 3: Production Ready (Weeks 9-12)
**Backend:**
- [ ] Rate limiting
- [ ] API versioning
- [ ] Comprehensive testing (80%+ coverage)
- [ ] Security audit
- [ ] Performance tuning
- [ ] Disaster recovery plan

**Frontend:**
- [ ] Accessibility audit (WCAG 2.1 AA)
- [ ] Comprehensive testing
- [ ] App Store optimization
- [ ] Performance optimization
- [ ] Final UX/UI refinements

**Deployment & Operations:**
- [ ] CI/CD pipeline (GitHub Actions)
- [ ] Automated testing
- [ ] Staging environment
- [ ] User acceptance testing
- [ ] Documentation finalization
- [ ] Staff training

**Phase 3 Deliverables:**
- ✅ Production-ready system
- ✅ App Store & Play Store releases
- ✅ Complete documentation
- ✅ Staff training materials
- ✅ Operations manual

---

## 11. API REFERENCE

### 11.1 Complete Endpoint List

#### Students App Endpoints

```
GET    /api/v1/announcements
GET    /api/v1/announcements/{id}
POST   /api/v1/announcements/{id}/views        # Track views

GET    /api/v1/events
GET    /api/v1/events/{id}

GET    /api/v1/transport
GET    /api/v1/transport/{id}

GET    /api/v1/bus-schedules

GET    /api/v1/notifications
PATCH  /api/v1/notifications/{id}/read
DELETE /api/v1/notifications/{id}

POST   /api/v1/bookmarks
DELETE /api/v1/bookmarks/{id}
GET    /api/v1/bookmarks

GET    /api/v1/search

POST   /api/v1/auth/login
POST   /api/v1/auth/refresh
POST   /api/v1/auth/logout

POST   /api/v1/upload              # File upload
GET    /api/v1/health              # Health check
```

#### Admin Endpoints

```
POST   /api/v1/admin/auth/login
POST   /api/v1/admin/auth/logout
POST   /api/v1/admin/auth/refresh

GET    /api/v1/admin/dashboard
GET    /api/v1/admin/analytics

POST   /api/v1/admin/announcements
GET    /api/v1/admin/announcements
GET    /api/v1/admin/announcements/pending
PATCH  /api/v1/admin/announcements/{id}
PATCH  /api/v1/admin/announcements/{id}/approve
PATCH  /api/v1/admin/announcements/{id}/reject
DELETE /api/v1/admin/announcements/{id}

POST   /api/v1/admin/events
GET    /api/v1/admin/events
PATCH  /api/v1/admin/events/{id}
DELETE /api/v1/admin/events/{id}

GET    /api/v1/admin/transport
POST   /api/v1/admin/transport
PATCH  /api/v1/admin/transport/{id}

GET    /api/v1/admin/bus-schedules
POST   /api/v1/admin/bus-schedules
PATCH  /api/v1/admin/bus-schedules/{id}

GET    /api/v1/admin/users
POST   /api/v1/admin/users
PATCH  /api/v1/admin/users/{id}
DELETE /api/v1/admin/users/{id}

GET    /api/v1/admin/audit-logs
GET    /api/v1/admin/audit-logs/{id}

POST   /api/v1/admin/bulk/import-events
POST   /api/v1/admin/bulk/import-schedules
```

### 11.2 Response Format

```json
{
    "success": true,
    "data": {
        "id": "uuid",
        "title": "...",
        "created_at": "2024-01-15T10:30:00Z"
    },
    "meta": {
        "pagination": {
            "total": 150,
            "limit": 20,
            "offset": 0,
            "has_more": true
        },
        "timestamp": "2024-01-15T10:30:00Z"
    }
}
```

---

## 12. DEVELOPMENT GUIDELINES

### 12.1 Code Organization

**Backend:**
- One model per file
- Services contain business logic
- CRUD operations in separate files
- API routes are thin (delegate to services)
- Logging at service boundaries

**Frontend:**
- Small, focused widgets (< 300 lines)
- One page per feature
- State in providers, not widgets
- Reusable components in common/widgets
- Consistent naming convention

### 12.2 Git Workflow

```
Main branches:
  main           # Production-ready code
  develop        # Integration branch

Feature branches:
  feature/announcements-list
  feature/event-detail-page
  feature/moderation-queue

Bug branches:
  bugfix/search-filter-issue

Release branches:
  release/v1.0.0
```

### 12.3 Testing Strategy

**Backend:**
- Unit tests for services (pytest)
- Integration tests for APIs
- Database tests with fixtures
- Target: 80% code coverage

**Frontend:**
- Unit tests for business logic
- Widget tests for key screens
- Integration tests for navigation
- Target: 70% code coverage

### 12.4 Documentation

**Code:**
- Docstrings on all functions
- Comments on complex logic
- Type hints everywhere
- Example usage for public APIs

**User Docs:**
- README with setup instructions
- API documentation (auto-generated by FastAPI)
- Architecture diagrams
- Database schema documentation

### 12.5 Performance Targets

- API response time: < 500ms p95
- App startup: < 2 seconds
- List scrolling: 60 FPS
- Search results: < 1 second
- Database queries: < 200ms

---

## SUMMARY: What You Get

### Backend (Python FastAPI)
✅ RESTful API with all required endpoints  
✅ PostgreSQL database with optimized schema  
✅ JWT authentication and RBAC  
✅ File upload and image management  
✅ Real-time WebSocket support (Phase 2)  
✅ Error handling and logging  
✅ Docker deployment ready  
✅ API documentation (Swagger UI)  

### Frontend (Flutter)
✅ Cross-platform app (iOS/Android/Web)  
✅ All required screens implemented  
✅ Offline support ready  
✅ Dark mode support  
✅ Responsive design  
✅ State management with Riverpod  
✅ Local storage  
✅ Performance optimized  

### Admin Portal (Flutter Web)
✅ Content management interface  
✅ Role-based access control  
✅ Moderation workflow  
✅ Analytics dashboard  
✅ User management  
✅ Audit logging  

### Infrastructure
✅ Self-hosted on university servers  
✅ PostgreSQL database  
✅ Docker containerization  
✅ Nginx reverse proxy  
✅ SSL/TLS security  
✅ Backup strategy  
✅ Monitoring and logging  

### Documentation
✅ Complete API reference  
✅ Database schema  
✅ Architecture overview  
✅ Deployment guide  
✅ Development workflow  
✅ Implementation roadmap  

---

**Document Status:** Ready for Development  
**Prepared by:** Software Engineering Team  
**Date:** September 2026  
**Institution:** Soroti University

**Next Step:** Review this document with stakeholders, then proceed to Phase 1 implementation.

