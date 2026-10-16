# MySun - Integrated Complete Software Specification
## Soroti University Campus Companion Application

**Version:** 5.0 - Production Ready  
**Date:** September 2026  
**Prepared for:** Soroti University  
**Status:** Complete Specification - Ready for Frontend Development

---

## TABLE OF CONTENTS

### PART 1: ARCHITECTURE & OVERVIEW
1. [Executive Summary](#executive-summary)
2. [Critical System Architecture](#critical-system-architecture)
3. [Technology Stack](#technology-stack)

### PART 2: APPLICATION SPECIFICATIONS
4. [Student/Staff App - Complete Specification](#studentstaff-app-complete-specification)
5. [Admin Portal - Complete Specification](#admin-portal-complete-specification)
6. [Services Framework (Extensible)](#services-framework-extensible)

### PART 3: TECHNICAL FOUNDATION
7. [Authentication & Role-Based Access](#authentication--role-based-access)
8. [Database Design](#database-design)
9. [Backend API Specification](#backend-api-specification)

### PART 4: QUALITY & PRODUCTION
10. [Testing Strategy (QA)](#testing-strategy-qa)
11. [Security & Compliance](#security--compliance)
12. [Performance & Monitoring](#performance--monitoring)
13. [Deployment & DevOps](#deployment--devops)
14. [Implementation Roadmap](#implementation-roadmap)
15. [Things You Might Have Missed](#things-you-might-have-missed)

---

# PART 1: ARCHITECTURE & OVERVIEW

## 1. EXECUTIVE SUMMARY

### 1.1 Problem Statement

Soroti University students and staff face three critical challenges:

1. **Information Fragmentation** - Campus updates scattered across WhatsApp, emails, noticeboards, and various portals
2. **Event Forgetfulness** - Students know about events but forget to attend due to lack of centralized reminders
3. **Transport Insecurity** - Difficulty finding trusted, verified transportation options quickly

### 1.2 Solution: MySun

MySun is a comprehensive campus companion system that:
- Centralizes all campus announcements, events, and updates
- Delivers timely reminders for important events
- Provides a verified directory of campus services (transport, accommodation, etc.)
- Connects students and staff with university information in one place
- Enables authorized publishers to share updates directly through the mobile app

### 1.3 System Components (One-App Architecture — see §2.1)

> **Updated:** what shipped is one mobile app with role-gated tabs, not a
> student app plus a separate admin portal. Admin management (item 2
> below) is a tab inside item 1, not its own Flutter Web build.

**1. MySun Student/Staff App** (Flutter — Android + Web now; iOS pending
Mac/Xcode access)
- Campus feed with announcements and events
- Event discovery and calendar integration
- Services hub (Transport — **Boda only for now**; Accommodation — live,
  not Phase 2; Future services)
- Bookmarks and saved items
- Publishing module (for authorized publishers only) — publishes
  immediately, no approval step (§5.1)
- Admin management (for admin/minor_admin accounts only) — content
  moderation (remove-only), user/role management, analytics — same app,
  extra tab, **not** a separate portal
- Dark mode and offline support
- Push notifications

**2. MySun Backend API** (Python FastAPI)
- RESTful API serving the app (`backend/`)
- WebSocket support for real-time updates (Phase 2, not built)
- **Supabase Auth** issues the JWT; the backend verifies it and layers
  role/business logic on top (was: custom JWT-based authorization)
- **Supabase Storage** for file storage (target — not yet wired into any
  endpoint; was: self-hosted local filesystem)
- **Supabase-managed PostgreSQL** (was: self-hosted on university
  servers) — see §3

### 1.4 Key Features by User Type

**For Students/Staff:**
- Smart campus feed with categorized announcements
- Event search, filtering, and calendar integration
- Verified service provider directory
- Bookmarks and saved items
- Notification center with preferences
- Profile management
- Search across all content

**For Publishers:**
- Everything above PLUS:
- Create and submit announcements
- Create and submit events
- Draft auto-save and management
- Submission status tracking
- Performance metrics and analytics
- Scheduled posting

**For Administrators:**
- Super Admin:
  - Full system access and configuration
  - User and role management
  - Create and manage minor admins
  - View comprehensive analytics
  - Audit trail access
  - System health monitoring

- Minor Admin:
  - Content moderation and approval
  - User support and handling
  - Activity monitoring
  - Limited configuration access

**For University:**
- Centralized communication platform
- Reduced communication silos
- Measurable student engagement
- Verified service partnerships
- Self-hosted with full data control
- Cost-effective solution

---

## 2. CRITICAL SYSTEM ARCHITECTURE

### 2.1 One-App Architecture (Admin Embedded) — IMPLEMENTED, SUPERSEDES BELOW

> **Deviation from the original 2-app plan:** Admin (Super Admin and Minor
> Admin) is **not** a separate Flutter Web portal. It is an extra "Admin"
> tab inside the same Student/Staff mobile app, gated by role exactly like
> the Publishing tab is gated for publishers — see
> `student_app/lib/features/shell/main_shell.dart` and
> `student_app/lib/core/router/app_router.dart`. Logging in as an admin no
> longer redirects anywhere; it just reveals the extra tab and screens.
> Every admin screen in §5.3 below (Dashboard, Moderation, User
> Management, Analytics, Minor Admin Management) still exists — it's just
> reached from within the mobile app, not a separate web deployment. A true
> standalone web Admin Portal is not ruled out for later, but is not the
> current build target.

```
MySun System (1 App + Extensible Services)
│
├── 📱 STUDENT/STAFF APP (Mobile: Android — iOS pending Mac/Xcode access;
│    also runs as a Flutter Web build for development)
│   ├── Purpose: Campus information + authorized content creation + admin
│   │            management, all in one app
│   ├── Users: ALL students + staff + publishers + admins
│   ├── Role-gated tabs (see §4.5):
│   │   ├── Everyone: Home, Events, Services, Bookmarks, Profile
│   │   ├── Publishers ALSO see: Publish tab (create + drafts + performance)
│   │   └── Admins ALSO see: Admin tab (dashboard + moderation + users +
│   │       analytics — Minor Admin gets a reduced subset, no separate app)
│   │
│   └── Key: Role-based feature visibility inside one app — this now
│       applies to admins too, not just publishers
│
├── 🔧 BACKEND (Python FastAPI)
│   ├── Single REST API serving the app (`backend/`)
│   ├── Database: **Supabase-hosted PostgreSQL** (was: self-hosted)
│   ├── Auth: **Supabase Auth** issues the JWT; FastAPI verifies it and
│   │   loads the app's `profiles` row for role/faculty/etc.
│   ├── File storage: **Supabase Storage** (was: local filesystem)
│   ├── Services Framework: Extensible architecture
│   │   ├── Transport — **Boda only for now** (taxi/bus/matatu removed;
│   │   │   see §6.1)
│   │   ├── Accommodation — live, not Phase 2 (see §6.1, §8.3)
│   │   └── Future services (plugin-ready)
│   ├── Content moderation: **publish-immediately, remove-only** — there
│   │   is no pre-approval/pending-review gate (see §5.1, §9.4)
│   └── Real-time: WebSocket (Phase 2, unchanged)
│
└── 📦 SERVICES MODULE (Extensible Framework)
    ├── Transport (Boda)
    ├── Accommodation
    └── Future (Expandable)
```

### 2.2 Architecture Layers

**Presentation Layer:**
- Student/Staff App (Flutter — Android + Web today; iOS scaffold pending
  Mac/Xcode access). No separate Admin Portal build.
- Material Design 3 UI
- Riverpod 2.x state management
- go_router 14.x navigation (bumped from 10.x — see §3)

**Application Layer:**
- FastAPI with sync Supabase client calls (the `supabase-py` SDK; no
  SQLAlchemy/asyncpg layer — see §3, §9)
- Dependency injection (FastAPI `Depends`, role-gate dependencies)
- Pydantic validation
- Comprehensive error handling
- Rate limiting (slowapi, on `/auth/*`) & JSON logging with request-ID
  correlation

**Data Layer:**
- **Supabase PostgreSQL** (managed, was self-hosted)
- **Supabase Storage** (managed, was local filesystem)
- ACID compliance
- Full-text search (still planned)
- Row-level security (baseline policies in the migration; primary
  authorization logic lives in the FastAPI layer — see §9)

**Deployment:**
- Database/Auth/Storage: Supabase-managed (no self-hosted Postgres, no
  backup scripts to run — Supabase handles this)
- Backend API: deploys to **Render** (free tier, Blueprint from
  `backend/render.yaml` + `backend/Dockerfile`) — Render terminates
  TLS itself, so no self-hosted Nginx/cert setup needed there; also
  still self-hostable (Docker + Nginx) on any VM for that path
- SSL/TLS encryption (Render-managed on Render; certbot/managed LB if
  self-hosting)

---

## 3. TECHNOLOGY STACK

> **As actually built** (this table replaces the original plan — see
> `backend/README.md` and `student_app/pubspec.yaml` for the source of
> truth going forward):

| Component | Technology | Rationale |
|-----------|-----------|-----------|
| **Frontend (Mobile)** | Flutter 3.x (Android now; iOS pending Mac/Xcode) | Cross-platform, native performance |
| **Frontend (Web)** | Flutter Web | Same codebase, used for fast dev iteration |
| **Backend** | Python 3.11+ | Maintainability, ecosystem |
| **Framework** | FastAPI | Modern, async, auto-documentation |
| **Database** | **Supabase (managed PostgreSQL)** | Was self-hosted PostgreSQL — managed hosting, built-in Auth/Storage, less infra to run |
| **Auth** | **Supabase Auth** | Was custom JWT + OAuth2 — Supabase issues the JWT; FastAPI validates it via Supabase's own `/auth/v1/user` endpoint (no shared secret to configure) and layers role/business logic on top |
| **File Storage** | **Supabase Storage** | Was local filesystem |
| **DB access from FastAPI** | `supabase-py` client (service-role key), not an ORM | Simpler than running SQLAlchemy *and* Supabase side by side; RLS policies exist as a baseline but authorization logic lives in FastAPI (see §9) |
| **State Management** | Riverpod 2.x | Reactive, testable, DI |
| **Navigation** | go_router **14.x** (was 10.x) | Declarative, deep linking |
| **Real-time** | WebSocket | Live updates — still Phase 2, not built |
| **Reverse Proxy** | Nginx | Fast, reliable (self-hosted path only — Render is its own reverse proxy/TLS) |
| **Containerization** | Docker | Deployment consistency (backend only now — no self-hosted DB container needed) |
| **Hosting** | Render (free tier) | `backend/render.yaml` Blueprint + port-agnostic Dockerfile; cold start after ~15 min idle on free tier |

**Python Dependencies** (`backend/requirements.txt`, unpinned `>=` —
this machine runs Python 3.14, too new for some packages' pinned-version
wheels, so versions are left to resolve rather than fixed; installed as
of writing: fastapi 0.141.1, supabase 2.31.0, pydantic 2.13.5):
- fastapi, uvicorn[standard]
- supabase, pydantic[email], pydantic-settings
- python-multipart, python-dotenv

No JWT-decoding library needed — auth tokens are validated by calling
Supabase Auth's own `/auth/v1/user` endpoint
(`admin.auth.get_user(token)`, via the `supabase` package itself) instead
of decoding a shared secret locally. This also means there's no
`SUPABASE_JWT_SECRET` to configure — three Supabase values are needed in
`backend/.env`, not four.

Dropped from the original plan: `sqlalchemy`, `psycopg2-binary`,
`passlib[bcrypt]` (Supabase Auth handles password hashing), `python-jose`
(see above), `Pillow` (no
server-side image processing yet).

**Flutter Dependencies** (`student_app/pubspec.yaml`):
- flutter_riverpod: ^2.6.1, go_router: ^14.6.2, dio: ^5.7.0
- shared_preferences: ^2.3.3, intl: ^0.19.0

Dropped from the original plan: `hive`/`hive_flutter` and
`cached_network_image` — both pull in `path_provider`, which breaks on a
Flutter SDK path containing a space (this dev machine's setup). Bookmarks
and settings use `shared_preferences` only; images use plain
`Image.network`. `web_socket_channel` will be added when Phase 2 real-time
is actually built.

---

# PART 2: APPLICATION SPECIFICATIONS

## 4. STUDENT/STAFF APP - COMPLETE SPECIFICATION

### 4.1 Purpose & Users

- **All Users:** Every student and staff member at Soroti University
- **Feature Access:** Determined by role assigned by admins
  - Regular Students/Staff: View-only access
  - Publishers: View + Create & Submit content
- **Platform:** iOS 14+ (App Store), Android 9+ (Google Play)
- **Target Metrics:** 20%+ DAU, 50%+ MAU within first year

### 4.2 Login & Authentication Flows

**Welcome/Splash Screen:**
```
[MySun Logo - Centered]
Soroti University Campus Companion
[Loading indicator]
"Loading your campus..."
```

**Login Screen:**
```
┌─────────────────────────────────┐
│  MySun                          │
│  Soroti University Campus       │
│  Companion                      │
├─────────────────────────────────┤
│  Email Address                  │
│  [email@sun.ac.ug         ]    │
│                                 │
│  Password                       │
│  [••••••••••••••••      ]       │
│  [ ] Remember me                │
│  [Forgot password?]             │
│                                 │
│  [    Sign In    ]              │
│  Don't have an account?         │
│  [Create Account]               │
│  ─── OR ───                     │
│  [Sign in with University SSO]  │
│                                 │
└─────────────────────────────────┘
```

**After Login - Role Detection:**
```
Backend detects user role and shows:
├── If role = "student" → Regular feed view
├── If role = "publisher" → Feed + Publishing tab (same app)
├── If role = "admin" → Feed + Admin tab, full access (same app)
└── If role = "minor_admin" → Feed + Admin tab, reduced access (same app)
```
> **Implemented differently than originally planned:** admin/minor_admin no
> longer redirect to a separate portal — see §2.1. Auth itself also now
> runs through **Supabase Auth**: the app calls `POST /api/v1/auth/login`,
> which proxies to Supabase and returns its JWT plus the `profiles` row
> (role, faculty, etc.) as one response — see `backend/app/api/v1/auth.py`.

**Sign Up Screen:**
```
┌─────────────────────────────────┐
│  Create Your Account            │
├─────────────────────────────────┤
│  Full Name                      │
│  [John Opiyo            ]       │
│  University Email               │
│  [john.opiyo@sun.ac.ug]        │
│  Program/Faculty                │
│  [Engineering (Dropdown)]       │
│  Year of Study                  │
│  [Year 2 (Dropdown)]            │
│  Password (8+ chars, mix)       │
│  [••••••••••••••••      ]       │
│  [  Create Account  ]           │
│  Already have an account?       │
│  [Sign In]                      │
└─────────────────────────────────┘
```

**Forgot Password Flow:**
- Enter email → Send reset link → Email received → Set new password

### 4.3 Main App Screens (All Users)

**Home Feed:**
```
┌─────────────────────────────────┐
│  MySun                    ☀️    │
├─────────────────────────────────┤
│  [  Search   ] [👤] [🔔(2)]    │
├─────────────────────────────────┤
│  Categories (Horizontal Scroll) │
│  [All] [📢] [📅] [📦] [📌]    │
├─────────────────────────────────┤
│                                 │
│  📢 ANNOUNCEMENT                │
│  Campus Security Notice         │
│  by: Student Affairs            │
│  1 hour ago • 234 views         │
│  [❤️ 45] [💬 12] [🔖]          │
│                                 │
│  📅 EVENT COMING UP             │
│  Campus Orientation Day         │
│  📍 Main Grounds                │
│  📅 Today at 2:00 PM            │
│  [Interested] [Share]           │
│                                 │
│  📦 SERVICES UPDATE             │
│  Matatu Schedule Updated        │
│  Route: Campus-Town             │
│  [View Details]                 │
│                                 │
│  [Load More] ↓                  │
└─────────────────────────────────┘
```

**Events (Calendar View):**
```
┌─────────────────────────────────┐
│  Events                   📅    │
├─────────────────────────────────┤
│  [View: Month] [  ◀ Sep 2026 ▶] │
│                                 │
│  Calendar with event indicators │
│  📍 SEPTEMBER 18 (Today)        │
│  2:00 PM - Campus Ori...        │
│  7:30 PM - Dinner in Hall       │
│                                 │
│  📍 SEPTEMBER 19                │
│  9:00 AM - Sports Fest...       │
│  3:00 PM - Library Review       │
└─────────────────────────────────┘
```

**Services Hub (Extensible):**
```
┌─────────────────────────────────┐
│  Services                 📦    │
├─────────────────────────────────┤
│  [🚌] [🏠] [+ More]             │
│  Transport Accommodation Future │
├─────────────────────────────────┤
│  🚌 TRANSPORT SERVICES          │
│  Available Routes:              │
│  • Campus → Town (6:30-10)      │
│  • Campus → Hospital            │
│  [View Schedules]               │
│                                 │
│  Verified Providers:            │
│  ⭐⭐⭐⭐⭐ Soroti Matatus      │
│  Rating: 4.8/5, 234 rates       │
│  [Call] [Message] [Book]        │
│                                 │
│  🏠 ACCOMMODATION (Coming Soon)  │
│  Find hostels & rentals         │
│  [Notify me]                    │
└─────────────────────────────────┘
```

**Bookmarks:**
```
┌─────────────────────────────────┐
│  Bookmarks              📌      │
├─────────────────────────────────┤
│  [Filter: All] [Sort: Newest]   │
│                                 │
│  📢 Campus Security Notice      │
│  Saved 2 hours ago              │
│  [View] [Remove]                │
│                                 │
│  📅 Campus Orientation Day      │
│  Saved yesterday                │
│  [View] [Add to Calendar]       │
│  [Remove]                       │
└─────────────────────────────────┘
```

**Profile & Settings:**
```
┌─────────────────────────────────┐
│  Profile                  👤    │
├─────────────────────────────────┤
│  [Profile Photo]                │
│  John Opiyo                     │
│  john.opiyo@sun.ac.ug          │
│  Engineering Year 2             │
│                                 │
│  Account Type: Student          │
│  (If Publisher: "Publisher ✓")  │
│                                 │
│  PREFERENCES                    │
│  [🔔] Push Notifications        │
│  [🌙] Dark Mode                 │
│  [🌐] Language: English         │
│                                 │
│  CONTENT INTERESTS              │
│  [✓] Academic News              │
│  [✓] Events                     │
│  [✓] Campus Life                │
│  [✗] Sports                     │
│                                 │
│  APP SETTINGS                   │
│  [About MySun] (v1.0.0)         │
│  [Privacy Policy]               │
│  [Terms of Service]             │
│  [Contact Support]              │
│  [Rate App on Store]            │
│  [Logout]                       │
│  [Delete Account]               │
└─────────────────────────────────┘
```

### 4.4 Publishing Module (Publishers Only - Inside Same App)

**Publisher Dashboard Tab (Only for Publishers):**
```
┌─────────────────────────────────┐
│  Create Content             📝  │
│  (Only visible to publishers)   │
├─────────────────────────────────┤
│  Welcome back, Sarah Akena!     │
│  Publisher - HR Department      │
│                                 │
│  RECENT SUBMISSIONS             │
│  ✓ Live: "Leave Policy"        │
│    2 hours ago                  │
│  ✓ Live: "Open Positions"      │
│    5 hours ago                  │
│  ✗ Removed: "Old Memo"          │
│    Violated guidelines          │
│                                 │
│  QUICK ACTIONS                  │
│  [+] New Announcement           │
│  [+] New Event                  │
│  [+] View Drafts (3)            │
│  [📊] My Performance            │
└─────────────────────────────────┘
```

**Create Announcement (Publisher Only):**
```
┌─────────────────────────────────┐
│  Create Announcement        📢  │
├─────────────────────────────────┤
│  Title *                        │
│  [Leave Policy Update 2026]     │
│  Department *                   │
│  [HR Department ▼]              │
│  Category *                     │
│  [Policy Announcement ▼]        │
│  Content *                      │
│  [WYSIWYG Editor...]            │
│  Add Image                      │
│  [+ Upload Image] or [Camera]   │
│  PUBLICATION SETTINGS           │
│  [○] Save as Draft              │
│  [●] Submit for Review          │
│  Schedule (optional)            │
│  Date: [Sep 20, 2026 ▼]        │
│  Time: [9:00 AM ▼]             │
│  [Save Draft] [Submit]          │
└─────────────────────────────────┘
```

**Create Event (Publisher Only):**
```
┌─────────────────────────────────┐
│  Create Event               📅  │
├─────────────────────────────────┤
│  Event Title *                  │
│  [Campus Event Name]            │
│  Description *                  │
│  [Event details...]             │
│  Start Date: [Sep 18 ▼]        │
│  Start Time: [2:00 PM ▼]       │
│  End Time: [5:00 PM ▼]         │
│  Location *                     │
│  [Main Grounds / Sports Field]  │
│  Organizer *                    │
│  [Student Affairs Office ▼]     │
│  Category *                     │
│  [Academic/Social/Sports ▼]     │
│  Event Image                    │
│  [+ Upload Image]               │
│  [Save Draft] [Submit Review]   │
└─────────────────────────────────┘
```

### 4.5 Role-Based Feature Access

**All Users See:**
- Home Feed (View only)
- Events (View only)
- Services Hub (View only)
- Bookmarks
- Profile & Settings
- Search
- Notifications

**Only Publishers See (Inside Same App):**
- Publishing Tab/Module
- Create Announcement, Create Event, Create Accommodation Listing, Add
  Boda Rider (accommodation and transport were added to the publishing
  surface alongside announcements/events — see §6.1)
- Draft Management (full form data saved, not just a title — a draft can
  be resumed with every field prefilled)
- Submission Status: **Draft / Live / Removed** (was: draft/pending/
  approved/rejected — see §5.1 for why the pending/approved states went
  away)
- Performance Metrics
- **Remove own content** — a publisher can take down their own live boda
  listing themselves (self-service; separate from admin moderation) —
  not originally speced, added because not everything a publisher adds
  should require an admin round-trip to undo

**Only Admins See (Inside Same App, not a separate portal):**
- Admin Tab/Dashboard
- Moderation ("Content Review" — remove-only, see §5.1)
- User Management, Analytics, Minor Admin Management (**Super Admin
  only** — a Minor Admin's Admin tab shows Dashboard + Moderation only)

**Access Control Logic:**
```
Login → Backend checks user role → 
├── role = "student" → Hide publishing features and Admin tab
├── role = "publisher" → Show Publishing tab
├── role = "admin" → Show Admin tab, full access
└── role = "minor_admin" → Show Admin tab, Dashboard + Moderation only
```

---

## 5. ADMIN PORTAL - COMPLETE SPECIFICATION

> **Read this as "Admin tab," not "separate portal":** per §2.1, every
> screen below is implemented inside the Student/Staff mobile app as an
> extra tab shown only to admin/minor_admin accounts — there is no
> standalone Flutter Web Admin Portal build. The screen designs,
> permissions, and role split described below are otherwise accurate to
> what's built.

### 5.1 Purpose & Users

**Super Admin:**
- Full system access
- Create/manage minor admins
- Promote users to publishers
- System configuration
- View all analytics
- Audit trail access

**Minor Admin:**
- Content moderation
- User support
- Activity monitoring
- Limited configuration
- Cannot manage users or create other admins

> **Content moderation is now remove-only, not approve/reject.** There is
> no pre-publication review queue — publishers' content goes live the
> moment they submit it (§4.4, §9.2). "Moderation" for both admin levels
> now means: browse everything currently live, and take down anything that
> breaks the terms of service, with a required reason. See §9.4 and
> `backend/app/api/v1/admin.py`.

### 5.2 Admin Authentication

> **2FA is not implemented.** Admin login currently uses the same
> Supabase-Auth-backed email/password flow as everyone else (§4.2) — the
> 2FA screen below is still the target design for when it's built, not
> what ships today.

**Admin Login Screen:**
```
┌────────────────────────────────────┐
│  MySun Admin Portal            🔐  │
├────────────────────────────────────┤
│  Email Address                     │
│  [admin@sun.ac.ug           ]     │
│  Password (12+ characters)         │
│  [••••••••••••••••••••      ]     │
│  [✓] Remember this device          │
│  [      Sign In      ]             │
│  [Forgot password?]                │
└────────────────────────────────────┘
```

**Two-Factor Authentication (2FA):**
```
┌────────────────────────────────────┐
│  Two-Factor Authentication     🔐  │
├────────────────────────────────────┤
│  Enter 6-digit code from            │
│  authenticator app                 │
│  [_ _ _ _ _ _]                     │
│  [      Verify Code      ]         │
│  Don't have code? [Use backup key] │
└────────────────────────────────────┘
```

### 5.3 Admin Portal Main Screens

**Main Dashboard:**
```
┌────────────────────────────────────┐
│ MySun Admin          Dr. James ▼   │
├────────────────────────────────────┤
│ [Dashboard] [Moderation] [Users]   │
│ [Analytics] [Minor Admins] [...]   │
├────────────────────────────────────┤
│ SYSTEM HEALTH                      │
│ API Status: ✓ Online               │
│ Database: ✓ 98.2%                  │
│ Storage: ✓ 67% used                │
│                                    │
│ KEY METRICS (Last 7 days)          │
│ • DAU: 1,240 (↑ 12.5%)             │
│ • Active Publishers: 45             │
│ • Live Content to Review: 5 items  │
│ • System Status: ✓ All OK          │
│                                    │
│ PENDING ACTIONS                    │
│ • 5 items live from publishers     │
│ • 2 minor admins requesting        │
│ • 1 system alert: Low storage      │
└────────────────────────────────────┘
```
> DAU/Active Publishers/System Health are illustrative until real usage
> tracking exists (`AdminAnalytics.mock` in the Flutter app,
> `app/api/v1/admin.py::analytics` in the backend) — content counts
> (announcements/events published, users, publishers) are real.

**Moderation Queue → "Content Review" (remove-only, no approve step):**
```
┌────────────────────────────────────┐
│ Content Review               ⚖️    │
├────────────────────────────────────┤
│ Everything below is already live.  │
│ Remove anything that doesn't align │
│ with the terms and conditions.     │
├────────────────────────────────────┤
│ 📢 Campus Security Notice          │
│ By: Sarah Akena (HR Dept)          │
│ Live • 2 hours ago                 │
│ [Reject (Remove)]                  │
│                                    │
│ [Load More Items ↓]                │
└────────────────────────────────────┘
```
> Tapping **Reject (Remove)** asks for a reason, then immediately deletes
> the real content (from the feed/events/services list it lives in) and
> records the reason on the publisher's submission history. There is no
> "Approve," "Request Changes," or "Automated Checks" — publishing is
> already immediate by the time anything reaches this screen (§5.1).

**User Management (Super Admin Only):**
```
┌────────────────────────────────────┐
│ User Management             👥     │
├────────────────────────────────────┤
│ [Students] [Publishers] [Admins]   │
│ [Search user...] [Add User] [+]    │
│ [Export CSV]                       │
│                                    │
│ ADMIN MANAGEMENT                   │
│ Dr. Okot | Super Admin | Active    │
│ Sarah A. | Minor Admin | Active    │
│ James M. | Minor Admin | Active    │
│ [+ Add New Minor Admin]            │
│                                    │
│ PUBLISHERS (45 active)             │
│ Sarah A. | HR | Active | 30 mins   │
│ John O. | Engineering | Active     │
│ [Manage Publishers]                │
└────────────────────────────────────┘
```

**Grant Publisher Access (Super Admin):**
```
┌────────────────────────────────────┐
│ Grant Publisher Access         ✨  │
├────────────────────────────────────┤
│ Select User                        │
│ [Search user...        ]           │
│                                    │
│ Selected: John Opiyo               │
│ Department: Engineering            │
│ Email: john.opiyo@sun.ac.ug       │
│ Current Role: Student             │
│                                    │
│ New Role:                          │
│ [●] Publisher                     │
│ [ ] Minor Admin                   │
│ [ ] Super Admin                   │
│                                    │
│ Permissions:                       │
│ ☑ Create Announcements            │
│ ☑ Create Events                   │
│ ☑ Submit for Review               │
│ [Grant Access]                     │
└────────────────────────────────────┘
```

**Analytics Dashboard:**
```
┌────────────────────────────────────┐
│ Analytics               📊         │
├────────────────────────────────────┤
│ [Range: Last 30 days ▼]            │
│ [Export Report]                    │
│                                    │
│ USER METRICS                       │
│ • DAU: 1,240 (↑)                   │
│ • MAU: 3,450 (↑)                   │
│ • Total Users: 3,700               │
│ • Publishers: 45                   │
│                                    │
│ CONTENT METRICS                    │
│ • Announcements: 124 published     │
│ • Events: 31 created               │
│ • Avg engagement: 18.5%            │
│ • Most popular: Events             │
│                                    │
│ [Download Report]                  │
└────────────────────────────────────┘
```

**Minor Admin Management (Super Admin):**
```
┌────────────────────────────────────┐
│ Minor Admin Dashboard          👥  │
│ (For Super Admin to manage)        │
├────────────────────────────────────┤
│ Active Minor Admins: 3             │
│                                    │
│ Sarah Akena                        │
│ ├─ Appointed: Sep 1, 2026         │
│ ├─ Moderation Actions: 247        │
│ ├─ Last Active: 30 mins ago       │
│ ├─ Performance: Excellent          │
│ └─ [View Activity] [Permissions]   │
│                                    │
│ James Mburu                        │
│ ├─ Appointed: Sep 3, 2026         │
│ ├─ Moderation Actions: 156        │
│ ├─ Last Active: 2 hours ago       │
│ ├─ Performance: Good               │
│ └─ [View Activity] [Permissions]   │
│                                    │
│ [+ Add More Minor Admins]          │
└────────────────────────────────────┘
```

---

## 6. SERVICES FRAMEWORK (EXTENSIBLE)

### 6.1 Services Module Architecture

**Goal:** Expandable system that adds new services without code changes

```
Services Framework
│
├── Transport Service (MVP) — BODA ONLY FOR NOW
│   ├── Boda rider directory (name, phone, contact person,
│   │   operating hours, service areas) with search by name or
│   │   place of service
│   ├── Rating system (shown; not yet settable by students)
│   ├── Provider verification (admin-controlled `is_verified` flag —
│   │   new submissions default to unverified)
│   └── ~~Matatu / taxi / bus management~~ — removed for now, not
│       deferred-but-planned; can return as separate service types
│       later without a schema change (`service_type` is still a
│       free-text column)
│
├── Accommodation Service — LIVE, NOT PHASE 2
│   ├── Hostel + independent rental listings
│   ├── Pricing: **hostels bill per semester, rentals per month**
│   │   (`AccommodationType.priceUnit` in the Flutter model) — this
│   │   split was not in the original plan
│   ├── Gazetted vs. non-gazetted status (university-registered or not)
│   ├── Room sharing: shared / private / both
│   ├── Photos (multiple, via Supabase Storage once wired — currently
│   │   `picsum.photos` seed URLs / user-added placeholder URLs)
│   ├── Contact details, availability flag
│   └── Booking system (future) — unchanged, still not built
│
└── Future Services (Expandable)
    ├── Food Services
    ├── Healthcare Services
    ├── IT Support Services
    ├── Library Services
    └── Custom Services
```

Both live services (Transport, Accommodation) follow the same publishing
model as announcements/events: a publisher's submission goes live
immediately, is tracked in `publisher_submissions`, and can be taken down
either by an admin (with a reason, §5.1) or by the publisher themselves
for their own boda listings (§4.5).

### 6.2 Backend Service Plugin Structure

> **Built flatter than originally planned.** There's no `/services/<name>/`
> plugin folder per service yet — each service is one router file under
> `backend/app/api/v1/` (`transport.py`, `accommodation.py`), both using
> the same shared `TableRepo` CRUD helper (`app/services/table_repo.py`)
> and the shared `publisher_service.py` for the publish/remove/draft
> lifecycle. The actual structure today:

```
backend/app/
├── api/v1/
│   ├── transport.py        (routes: list w/ search, get, create, delete)
│   ├── accommodation.py    (routes: list w/ type filter, get, create, delete)
│   └── ... (announcements, events, publisher, admin, auth, etc.)
├── services/
│   ├── table_repo.py        (generic Supabase-table CRUD, shared by all)
│   └── publisher_service.py (submission tracking, self/admin removal,
│                              performance stats — shared by all)
└── schemas/
    └── content.py           (Pydantic models for all four content types)
```

Adding a genuinely new service (e.g. Food) is still just: one migration
table, one schema, one router file reusing `TableRepo` — the plugin-style
folder-per-service structure was a "nice to have" for physical isolation,
not a functional requirement, and wasn't worth the extra boilerplate for
four small, near-identical CRUD surfaces.

### 6.3 Frontend Services Display

**Services Tab in Student/Staff App:**
- Shows available services
- Each service has a card
- Admin can hide/show services
- Easy to add new service UI
- No app update needed for new service

### 6.4 Services Database Structure

> **As actually created** (`backend/supabase/migrations/0001_init.sql`) —
> there is no generic `services` registry table; each service is its own
> table directly, matching the Flutter models field-for-field:

```sql
-- Boda-only for now (service_type stays free-text so taxi/bus/matatu can
-- return later without a migration).
CREATE TABLE transport_providers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  phone_number TEXT NOT NULL,
  service_type TEXT NOT NULL DEFAULT 'boda',
  contact_person TEXT,
  operating_hours TEXT,
  service_areas TEXT[] NOT NULL DEFAULT '{}',
  image_url TEXT,
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  rating NUMERIC(3,1) NOT NULL DEFAULT 0,
  rating_count INT NOT NULL DEFAULT 0
);

CREATE TYPE accommodation_type AS ENUM ('hostel', 'rental');
CREATE TYPE room_sharing_type AS ENUM ('shared', 'private', 'both');

CREATE TABLE accommodation_listings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type accommodation_type NOT NULL,
  location TEXT NOT NULL,
  price INT NOT NULL, -- semester for hostels, month for rentals
  is_gazetted BOOLEAN NOT NULL DEFAULT FALSE,
  room_sharing room_sharing_type NOT NULL DEFAULT 'shared',
  contact_phone TEXT NOT NULL,
  image_urls TEXT[] NOT NULL DEFAULT '{}',
  description TEXT,
  publisher_name TEXT,
  is_available BOOLEAN NOT NULL DEFAULT TRUE
);
```

There's also a read-only `bus_schedules` table (route, departure point,
destination, time, duration, operating days, status/notes) for the
"Next bus" card — unchanged in spirit from the original design, just not
previously written down as its own table.

---

# PART 3: TECHNICAL FOUNDATION

## 7. AUTHENTICATION & ROLE-BASED ACCESS

### 7.1 Role Hierarchy

```
System Roles (Hierarchical)
│
├── Super Admin (Highest)
│   ├── Full system access
│   ├── Create/manage minor admins
│   ├── Remove any live content that breaks the rules (no approve step — §5.1)
│   ├── User management
│   ├── System configuration
│   └── View all analytics
│
├── Minor Admin
│   ├── Content moderation only
│   ├── Cannot manage other admins
│   ├── Cannot access system config
│   ├── Cannot manage users (view only)
│   └── Cannot publish content themselves
│
├── Publisher
│   ├── Create announcements
│   ├── Create events
│   ├── Submit for review
│   ├── Manage own drafts
│   ├── View submission status
│   └── View own performance metrics
│
└── Student (Default)
    ├── View feed only
    ├── View events
    ├── View services
    ├── Bookmark content
    ├── Search
    └── No publishing capabilities
```

### 7.2 Login Flow with Role Detection

**Frontend Logic (as implemented — `app_router.dart`'s `redirect`):**
```
1. User enters email + password
2. Press "Sign In"
3. POST /api/v1/auth/login proxies to Supabase Auth, which validates
   credentials and issues a JWT
4. If valid:
   a. Returns the Supabase JWT (access_token) + refresh_token
   b. Returns the user's `profiles` row (id, name, email, role, faculty,
      program, student_id, image_url) in the same response
5. Frontend checks role — same app for everyone, tabs differ:
   ├── If admin or minor_admin → Admin tab appears (Super Admin: full
   │   access; Minor Admin: Dashboard + Moderation only) — no redirect
   ├── If publisher → Publish tab appears
   └── If student → Neither extra tab appears
```

### 7.3 Role Assignment (Super Admin Only)

**Process (as implemented — `PATCH /api/v1/admin/users/{id}/role`,
`GrantRoleScreen` in the Flutter app):**
```
Super Admin opens User Management → "Grant Access"
→ Searches for and selects any user
→ Picks a new role: Publisher / Minor Admin / Super Admin
→ Confirms — the user's `profiles.role` is updated directly (no invite/
  redirect flow; the promoted user sees the new tab next time they open
  the app)

When promoting to Publisher:
- Student keeps the same app
- Publish tab appears
- Can create & submit content (goes live immediately, §5.1)
- Can see the Publisher Dashboard, drafts, and performance

When promoting to Admin or Minor Admin:
- Same app — no redirect, no separate portal (§2.1)
- Admin tab appears (scoped per §4.5's access table)
```

---

## 8. DATABASE DESIGN

> **As actually created**, on Supabase Postgres —
> `backend/supabase/migrations/0001_init.sql` is the source of truth; this
> section is a summary of it. Two structural changes from the original
> plan, both explained inline below: (1) there's no password/2FA/
> `is_active`/`is_verified` handling in `profiles` — **Supabase Auth's**
> `auth.users` table owns all of that; `profiles` only holds the
> app-specific fields the Flutter app actually shows. (2) content tables
> have **no `status` column** — publishing is immediate (§5.1), so there's
> nothing to be "draft/pending_review/approved/rejected" *in the content
> table itself*; that lifecycle now lives entirely in
> `publisher_submissions` (§8.4), which is new.

### 8.1 Profiles Table (role + app-specific fields only)

```sql
-- auth.users (Supabase Auth) already has id, email, encrypted_password,
-- email_confirmed_at, etc. — this table adds only what the app needs on
-- top, one row per auth user (created by a DB trigger on signup).

CREATE TYPE user_role AS ENUM ('student', 'publisher', 'admin', 'minor_admin');

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  email TEXT NOT NULL,
  role user_role NOT NULL DEFAULT 'student',
  student_id TEXT,
  faculty TEXT,
  program TEXT,
  image_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

2FA (§5.2), account activity flags, and email verification are all
Supabase Auth features, not columns we maintain ourselves — 2FA
specifically is not yet enabled in the project (§5.2 note).

### 8.2 Announcements Table

```sql
CREATE TABLE announcements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  publisher_name TEXT NOT NULL, -- denormalized display name, not a FK
  published_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_important BOOLEAN NOT NULL DEFAULT FALSE,
  image_url TEXT,
  expires_at TIMESTAMPTZ
);
```

No `author_id`, `status`, `rejection_reason`, `scheduled_for`, or
`moderator_id` — who published it and its moderation history live in
`publisher_submissions` (§8.4) instead, keyed by `content_id`. Scheduled
posting is not built.

### 8.3 Events Table

```sql
CREATE TABLE events (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category TEXT NOT NULL,
  organizer_name TEXT NOT NULL,
  date_time TIMESTAMPTZ NOT NULL,
  end_date_time TIMESTAMPTZ,
  venue TEXT NOT NULL,
  image_url TEXT,
  capacity INTEGER,
  registered_count INTEGER NOT NULL DEFAULT 0,
  is_featured BOOLEAN NOT NULL DEFAULT FALSE
);
```

Same deviation as announcements: no `organizer_id`/`status` — see
`publisher_submissions` below.

### 8.4 Publishing & Moderation — `publisher_submissions` (NEW)

> This table didn't exist in the original design. It's the single place
> that tracks *who* published *what*, *when*, and — since publishing is
> immediate — whether it was later **removed** (there is no "approved,"
> because nothing needs approving).

```sql
CREATE TYPE submission_type AS ENUM ('announcement', 'event', 'accommodation', 'transport');
CREATE TYPE submission_status AS ENUM ('draft', 'published', 'removed');

CREATE TABLE publisher_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  publisher_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type submission_type NOT NULL,
  title TEXT NOT NULL,
  status submission_status NOT NULL DEFAULT 'draft',
  content_id UUID, -- row id in announcements/events/accommodation_listings/
                    -- transport_providers; NULL for drafts
  form_data JSONB, -- the Create screen's fields, so a draft can be resumed
                    -- with every field prefilled
  publisher_name TEXT,
  removal_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ON publisher_submissions (publisher_id);
CREATE INDEX ON publisher_submissions (status);
```

### 8.5 Services, Bookmarks & Notifications

```sql
-- No generic `services` registry table (see §6.4) — transport_providers
-- and accommodation_listings (§6.4) are the two live service tables today.

CREATE TABLE bookmarks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  content_type TEXT NOT NULL, -- 'announcement' | 'event'
  content_id UUID NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, content_type, content_id)
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  type TEXT NOT NULL, -- 'announcement' | 'event' | 'reminder' | 'transport' | 'system'
  related_id UUID,
  is_read BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX ON notifications (user_id);
```

Row Level Security is enabled on every table above as a baseline (content
tables publicly readable; bookmarks/notifications/submissions scoped to
`auth.uid()`), but the FastAPI backend uses the service-role key and
enforces the real authorization rules itself — see §9.

---

## 9. BACKEND API SPECIFICATION

> **As actually implemented** in `backend/app/api/v1/` — see
> `backend/README.md` for setup and `http://localhost:8000/docs` (FastAPI's
> auto-generated Swagger UI) for the live, authoritative contract once the
> server is running. The endpoint list below replaces the original plan;
> several endpoints from that plan (2FA, forgot/reset password,
> bookmark-as-a-sub-resource, "interested" on events, promote/demote
> shortcuts, audit logs) were not built — see the notes under each group.

### 9.1 Authentication Endpoints (`auth.py`)

```
POST   /api/v1/auth/signup   — proxies to Supabase Auth; new accounts
                                always start as `student` (§7.3)
POST   /api/v1/auth/login    — proxies to Supabase Auth; returns
                                {access_token, refresh_token, user}
GET    /api/v1/auth/me       — current user's profile (Bearer token)
```

Not built: `logout` (client just discards the token), `forgot-password` /
`reset-password` (Supabase Auth has these built in — the backend would
only need a thin proxy if the Flutter app's existing UI needs it wired
up), `2fa/*` (§5.2 — 2FA isn't implemented anywhere yet).

### 9.2 Content — Announcements, Events, Accommodation, Transport
(All Users - Read, Publishers - Create/Delete-own)

```
GET    /api/v1/announcements?category=
GET    /api/v1/announcements/{id}
POST   /api/v1/announcements        (publisher only — publishes immediately)
DELETE /api/v1/announcements/{id}   (owning publisher only — self-removal)

GET    /api/v1/events?category=
GET    /api/v1/events/{id}
POST   /api/v1/events               (publisher only)
DELETE /api/v1/events/{id}          (owning publisher only)

GET    /api/v1/accommodation?type=hostel|rental
GET    /api/v1/accommodation/{id}
POST   /api/v1/accommodation        (publisher only)
DELETE /api/v1/accommodation/{id}   (owning publisher only)

GET    /api/v1/transport?query=     (name or place-of-service search)
GET    /api/v1/transport/{id}
GET    /api/v1/transport/bus-schedule
POST   /api/v1/transport            (publisher only — boda only, §6.1)
DELETE /api/v1/transport/{id}       (owning publisher only)
```

There is no `PUT` (edit-in-place) for live content — a publisher who
wants to change something removes it and republishes, matching what's
built in the Flutter app today. No `bookmark`/`interested` sub-resources —
see §9.3.

Every `POST` above accepts an optional `draft_id`: when present and it
belongs to the calling publisher, that draft is converted into the new
live record instead of creating a duplicate submission (§9.5).

### 9.3 Bookmarks & Notifications

```
GET    /api/v1/bookmarks
POST   /api/v1/bookmarks/toggle   — body: {content_type, content_id}

GET    /api/v1/notifications
POST   /api/v1/notifications/{id}/read
```

### 9.4 Moderation (Admin Only) — remove-only, no approve step

```
GET    /api/v1/admin/moderation                    — everything currently
                                                       live, newest first
POST   /api/v1/admin/moderation/{submission_id}/remove
                                                     — body: {reason};
                                                       deletes the real
                                                       content row too
```

Replaces the original `approve` / `reject` / `request-changes` triad —
there's nothing to approve since publishing is immediate (§5.1).

### 9.5 Publisher Self-Service (`publisher.py`)

> Not in the original plan as its own section — drafts, submission
> history, and performance metrics turned out to need their own endpoints
> once "publish immediately + resumable drafts" replaced the
> approval-queue model.

```
GET    /api/v1/publisher/submissions   — this publisher's full history
                                          (draft/published/removed)
GET    /api/v1/publisher/drafts
POST   /api/v1/publisher/drafts        — create, or update in place if
                                          {id} matches an existing draft
DELETE /api/v1/publisher/drafts/{id}   — discard a draft
GET    /api/v1/publisher/performance   — real counts + illustrative
                                          views/engagement (§15.4)
```

### 9.6 User Management (Super Admin Only)

```
GET    /api/v1/admin/users?role=
PATCH  /api/v1/admin/users/{id}/role   — body: {new_role}; replaces the
                                          promote-to-X / demote endpoints
                                          from the original plan with one
                                          generic role-set call
```

### 9.7 Analytics (Super Admin Only)

```
GET    /api/v1/admin/analytics
```

One endpoint, not four — returns user/content/engagement/system-health
figures together (matching `AdminAnalytics` in the Flutter app). Content
counts (announcements, events, users, publishers) are computed for real;
DAU/MAU/engagement/system-health are illustrative until real usage
tracking exists. No separate `audit-logs` endpoint yet (§15.10 is still
unbuilt).

---

# PART 4: QUALITY & PRODUCTION

## 10. TESTING STRATEGY (QA)

### 10.1 Testing by App & Role

**Student/Staff App - Regular Student:**
```
✓ Can view feed
✓ Can view events
✓ Can view services
✓ Can bookmark content
✓ Cannot see publishing tab
✓ Cannot create content
✓ Can edit profile
✓ Can search announcements
✓ Can filter by category
```

**Student/Staff App - Publisher:**
```
✓ Can view feed
✓ Can view publishing module
✓ Can create announcement
✓ Can create event
✓ Can submit for review
✓ Can view submission status
✓ Can save drafts
✓ Can view performance metrics
✓ Can schedule posts
```

**Admin Portal - Super Admin:**
```
✓ Can access admin portal
✓ Can moderate content
✓ Can create minor admins
✓ Can view analytics
✓ Can manage all users
✓ Can configure system
✓ Can promote users to publisher
✓ Can view audit logs
```

**Admin Portal - Minor Admin:**
```
✓ Can access admin portal
✓ Can moderate content only
✓ Cannot create other admins
✓ Cannot access system config
✓ Cannot manage users (view only)
✓ Can view activity logs
```

### 10.2 Feature Testing Matrix

| Feature | Student | Publisher | Minor Admin | Super Admin |
|---------|---------|-----------|------------|------------|
| View Feed | ✓ | ✓ | N/A | N/A |
| View Events | ✓ | ✓ | N/A | N/A |
| View Services | ✓ | ✓ | N/A | N/A |
| Create Announcement | ✗ | ✓ | ✗ | ✗ |
| Create Event | ✗ | ✓ | ✗ | ✗ |
| Moderate Content | ✗ | ✗ | ✓ | ✓ |
| Manage Users | ✗ | ✗ | ✗ | ✓ |
| Create Minor Admin | ✗ | ✗ | ✗ | ✓ |
| System Config | ✗ | ✗ | ✗ | ✓ |
| View Analytics | ✗ | ✗ | ✗ | ✓ |

---

## 11. SECURITY & COMPLIANCE

### 11.1 Authentication Security

> **Handled by Supabase Auth**, not custom backend code: password hashing,
> account lockout policy, password-reset emails, and JWT/refresh-token
> issuance are all Supabase features the backend simply consumes (verifies
> the JWT it's handed — `app/core/security.py`). The bullets below are the
> target behavior; anything not explicitly configured in the Supabase
> project's Auth settings is running on Supabase's defaults, not a custom
> value we've set.

**Student/Staff App:**
- Email + password (8+ characters)
- Account lockout after 5 failed attempts
- Password reset via email link (24h expiry)
- Session tokens with refresh mechanism

**Admin accounts (same app, Admin tab — §2.1):**
- Same Supabase Auth flow as everyone else today
- 2FA required (TOTP/backup codes) — **not yet implemented** (§5.2)
- Session timeout: 30 minutes of inactivity
- All logins logged with IP & user-agent
- Password reset requires email verification

### 11.2 Authorization & Access Control

```
Role-based:
├── Student → View-only access
├── Publisher → Create & submit content
├── Minor Admin → Moderate content only
└── Super Admin → Full system access

Feature-level:
├── Who can create (publishers)
├── Who can remove live content (admins — no approve step, §5.1)
├── Who can manage users (super admin)
└── Who can configure (super admin)

Data-level:
├── Everyone sees all live content — there's no "pending" state to hide;
│   publishing is immediate (§5.1, changed from the original "approved
│   content only" model)
├── Publishers see their own drafts + full submission history
├── Admins see all live content (for moderation/removal, not "+ pending" —
│   there's nothing pending)
└── Audit trail for all admin actions — **not yet implemented** (§15.10)
```

### 11.3 Data Protection

- HTTPS/TLS 1.2+ for all communication
- Passwords hashed by **Supabase Auth** (bcrypt under the hood — not our
  code to configure)
- JWT tokens: lifetime set by the Supabase project's Auth settings
- Database backups: **Supabase-managed** (was: self-hosted encrypted daily
  backup scripts — see §15.15)
- File storage: **Supabase Storage**, once wired up (not yet — §3)
- GDPR compliance ready (data export/delete) — not yet implemented (§15.16)

### 11.4 API Security

- Rate limiting: 100 req/min per IP — **not yet implemented**
- Input validation with Pydantic
- CORS configured per environment (`CORS_ORIGINS` in `backend/.env`)
- SQL injection prevention: PostgREST (Supabase's auto-generated API,
  used via the `supabase-py` client) parameterizes every query — there is
  no raw SQL or ORM layer in the backend (was: SQLAlchemy ORM; see §3)
- XSS protection in frontend
- CSRF tokens for sensitive operations — not applicable to a Bearer-token
  API called from a native/Flutter-Web client, not built

---

## 12. PERFORMANCE & MONITORING

### 12.1 Performance Targets

**Mobile App:**
- Startup: < 2 seconds
- Feed load: < 1 second
- Search: < 500ms
- Image load: < 500ms (compressed)
- Crash rate: < 0.1%

**Admin tab (same mobile app, not a separate web portal — §2.1):**
- Dashboard load: < 2 seconds
- Content Review list load: < 1 second
- Remove action: < 500ms (was: "Approve/reject" — remove-only now, §5.1)

**API:**
- Response time: < 500ms (p95)
- Availability: 99.5%
- Error rate: < 1%

### 12.2 Monitoring Alerts

**Critical (Immediate Action):**
- App down or not responding
- Database down
- API error rate > 5%
- Disk space < 5%

**Warning (Within 1 hour):**
- API response > 2 seconds
- Error rate > 1%
- CPU > 80%
- Memory > 85%

### 12.3 Metrics to Track

```
Application:
✓ Daily/Monthly active users
✓ Content performance (views, engagement)
✓ Publisher activity
✓ User growth
✓ Service usage
✓ Traffic patterns

System:
✓ API response times
✓ Database query times
✓ Error rates by endpoint
✓ Server CPU/Memory usage
✓ Disk space usage
✓ Backup success rate

Business:
✓ Announcement publication rate
✓ Event registration rate
✓ Service inquiries
✓ User retention
✓ Platform adoption rate
```

---

## 13. DEPLOYMENT & DEVOPS

### 13.1 Infrastructure Setup

> Updated for Supabase — there's no self-hosted database tier to run,
> replicate, or back up any more (§2.1, §3):

```
Load Balancer (Nginx)
    ↓
App Servers (FastAPI — stateless, scales horizontally)
    ↓
Supabase (managed): PostgreSQL + Auth + Storage — hosted, backed up,
    and replicated by Supabase, not by us
    ↓
Monitoring (Prometheus/Grafana) — still planned, not built
```

### 13.2 Deployment Process

**Release Strategy:** Bi-weekly cycles
- Week 1: New features (Phase 1 development)
- Week 2: Bug fixes & stability (Phase 2 testing)

**Requirements for Release:**
- All tests passing
- Code review approved
- Documentation updated
- Monitoring configured
- Rollback plan ready
- Performance tested

### 13.3 Docker Containerization

> Only the backend needs a container now — no self-hosted Postgres/Nginx-
> for-static-files-plus-DB stack (Supabase owns the data tier, §13.1).

```dockerfile
# backend/Dockerfile — matches the actual module path, app/main.py
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0"]
```

### 13.4 SSL/TLS Configuration

- Nginx reverse proxy with SSL termination
- Let's Encrypt certificates (auto-renewal)
- HSTS headers enabled
- Certificate pinning ready (optional)

---

## 14. IMPLEMENTATION ROADMAP

> **The actual build did not follow this week-by-week plan** — features
> arrived in a different order, driven by iterative requests rather than
> a fixed 12-week schedule. Treat the ✓/✗ marks below as the *original
> scope plan*, not a status tracker; §3, §5, §6, §8, and §9 above are the
> accurate "what's built" reference. A few bullets are corrected inline
> where the plan and the actual architecture now conflict.

### Phase 1: MVP (Weeks 1-4) - Foundation

**Student/Staff App (One App, Role-Based Features):**
- ✓ Login/signup — via Supabase Auth, not custom email verification code
- ✓ Home feed with **live** announcements (was: "approved" — there's no
  approval step, §5.1)
- ✓ Events list and calendar view
- ✓ Services hub (Transport — **Boda only**, §6.1)
- ✓ Bookmarks functionality
- ✓ User profile and settings
- ✓ Basic search and filtering
- ✓ Push notifications setup (basic)
- ✗ Publishing module (Phase 2)
- ✗ Offline support (Phase 2)

**Admin (same app, Admin tab — not a separate portal, §2.1):**
- ✗ 2FA — not implemented (was planned for Phase 1)
- ✓ Basic moderation — **remove-only**, not an approval queue (§5.1)
- ✓ Promote user to publisher (via Grant Access, §7.3)
- ✓ Create minor admin (same Grant Access flow)
- ✓ Basic dashboard with stats
- ✗ Audit logging — not implemented (§15.10)
- ✗ Advanced analytics (Phase 2)
- ✗ Minor admin performance tracking (Phase 2)

**Backend:**
- ✓ FastAPI setup with authentication
- ✓ Database schema (users, announcements, events)
- ✓ Role-based access control
- ✓ JWT token management
- ✓ File upload & image processing
- ✓ API documentation (Swagger)

---

### Phase 2: Beta (Weeks 5-8) - Publishing & Features

**Student/Staff App:**
- ✓ Publishing module (visible to publishers)
- ✓ Create & submit announcements
- ✓ Create & submit events
- ✓ Draft auto-save and management
- ✓ Submission status tracking
- ✓ Publisher performance metrics
- ✓ Push notifications (advanced)
- ✓ Offline support (read-only feed)
- ✓ Dark mode support
- ✓ Deep linking support

**Admin (same app, Admin tab):**
- ✓ Full moderation workflow — remove-with-reason only; there is no
  "reject" or "request changes" step distinct from removal (§5.1)
- ✓ Advanced publisher management
- ✓ Accommodation service setup
- ✓ Analytics dashboard (user growth, engagement)
- ✓ Minor admin performance tracking
- ✓ System configuration panel
- ✓ Backup status monitoring

**Backend:**
- ✓ Services framework (transport + accommodation tables)
- ✓ Enhanced API endpoints for services
- ✓ WebSocket support (real-time notifications)
- ✓ Scheduled posting support
- ✓ Advanced analytics endpoints
- ✓ Batch operations (CSV import)

---

### Phase 3: Production (Weeks 9-12) - Polish & Scale

**All Apps:**
- ✓ UI/UX polish and refinement
- ✓ Performance optimization
- ✓ Accessibility (WCAG AA compliance)
- ✓ Crash reporting integration
- ✓ App store submission (iOS & Android)
- ✓ Full testing & QA pass
- ✓ Documentation complete
- ✓ Support channels setup

**Enhancements:**
- ✓ Advanced search with filters
- ✓ User activity analytics
- ✓ Email digest notifications
- ✓ Mobile app auto-update
- ✓ Content recommendation engine (future)
- ✓ Integration with university SSO (future)

---

## 15. THINGS YOU MIGHT HAVE MISSED

### 15.1 New Publisher Onboarding

**When Super Admin Makes Someone a Publisher:**
```
1. User receives in-app notification
2. Shows "Congratulations! You're now a publisher"
3. Publishing tab appears in app
4. Quick tutorial video on creating content
5. Sample announcement creation walkthrough
6. Access to publisher guidelines
7. Direct support contact provided
```

### 15.2 Publisher Guidelines & Help

**In-App Help for Publishers:**
```
✓ What can I publish?
✓ How does moderation work? (publish-immediately, admin can remove later
  with a reason — §5.1, not an approval queue)
✓ What happens if my content is removed?
✓ How to schedule posts?
✓ Content format requirements
✓ Image specifications
✓ Contact support
✓ FAQ section
```

### 15.3 Minor Admin Experience

**When Super Admin Makes Someone Minor Admin:**
```
1. User receives notification (not yet implemented)
2. Admin tab appears in the same app — no redirect (§2.1)
3. Can only see Dashboard + Moderation ("Content Review")
4. Clear indication: role shows as "Minor Admin" on the Admin tab
5. Content Review always accessible from the Admin tab
6. Can only remove live content, with a reason — no approve/reject (§5.1)
7. Cannot manage users or settings
8. Limited to assigned departments (future)
```

### 15.4 Analytics for Publishers

**In Publisher Dashboard:**
```
✓ Posts published this month: 12
✓ Total views: 3,450
✓ Total interactions: 456
✓ Avg engagement: 18%
✓ Most popular post: "..." (450 views)
✓ Performance trend (chart)
✓ Comparison with other publishers
✓ Content type performance
```

### 15.5 Services Expansion Path

**To Add New Service (e.g., Accommodation in Phase 2):**
```
Backend:
1. Create accommodation service module
2. Add accommodation_listings table
3. Add API endpoints (/api/v1/services/accommodation)

Frontend:
4. Add accommodation card in Services tab
5. Create accommodation details screen

Admin:
6. Add accommodation management interface
7. Add accommodation analytics

Result:
✓ No app update needed for users (plugin architecture)
✓ Existing users see new service automatically
✓ Smooth service rollout
```

### 15.6 Content Moderation for Admins

> **Rewritten for the remove-only model (§5.1):** there is no pending
> queue, approval, rejection-with-resubmission, or change-request flow —
> content is already live by the time an admin sees it.

**Moderators Can (both Super Admin and Minor Admin, as built):**
```
✓ View all live content, newest first ("Content Review")
✓ Remove any of it, with a required reason (deletes the real content row
  too, not just a status flag)
✓ View moderation/removal history (via each submission's stored reason)
✗ Automated validation results — not built
✗ Internal notes / moderator performance tracking — not built
✗ Edit content directly — not built (a publisher republishes instead)

A publisher can also remove their own live boda listings themselves
(§4.5) — this was not originally planned as super-admin-only; it's
scoped per-content-type today (transport only) rather than "super admin
only" as the plan assumed.
```

### 15.7 System Messages & Notifications

**Push Notifications by Role:**

**Student:**
- New announcements in followed categories
- Event reminders (day before, 1 hour before)
- Bookmarked content updated
- Content from favorite publishers

**Publisher:**
- Your content was removed, with the admin's reason (replaces "approved
  (instant)" / "rejected (with reason)" / "changes requested" — there's
  only one outcome to notify about now: removal, since publishing itself
  is instant and needs no notification)
- Comment on your content (Phase 2)

**Minor Admin:**
- ~~New content pending review~~ / ~~high-priority awaiting decision~~ —
  don't apply; nothing is ever "awaiting" anything (§5.1). A "new content
  published" digest could replace these if admins want visibility into
  new listings without opening Content Review each time — not built.
- User reported content
- System alerts (performance issues)

**Super Admin:**
- Critical system alerts (down, errors > 5%)
- Unusual activity detected (spam, volume spikes)
- Backup completed/failed
- New publisher promotion requests (pending)
- Storage capacity warnings

### 15.8 Support Tiers

```
Students: 
- FAQ section in app
- Contact form
- Email support (48h response)

Publishers: 
- Tutorial videos
- Guidelines document
- Contact form (priority)
- Email support (24h response)
- Monthly webinar

Admins: 
- Priority support (4h response)
- Direct chat with support team
- Phone support (critical issues)
- Monthly admin briefing
```

### 15.9 Analytics Dashboard (Super Admin)

**Essential Metrics:**
```
✓ DAU / MAU trends (weekly chart)
✓ Content performance (which announcements viewed most)
✓ Publisher activity (who publishes most, when)
✓ User growth (registration rate, retention)
✓ Service usage (which services used most)
✓ Engagement metrics (likes, comments, shares)
✓ Traffic patterns (peak hours, days)
✓ Error rates and system health
✓ Cache hit rates
✓ API response times
```

### 15.10 Audit Log (All Admin Actions)

> **Not implemented.** `publisher_submissions.removal_reason` (§8.4)
> gives a partial trail for removals specifically, but there's no general
> audit log table or endpoint yet.

**Must Log:**
```
✓ Who promoted someone to publisher (timestamp, IP)
✓ Who created minor admin (timestamp, permissions)
✓ What content was removed and why (timestamp) — was "approved/rejected";
  removal is the only moderation outcome now (§5.1)
✓ When admins accessed system (login/logout)
✓ System configuration changes (before/after)
✓ All content deletions (what, who, when) — self-removal by a publisher
  and admin removal are both worth distinguishing here (§4.5, §5.1)
✓ User role changes
✓ Password resets
✓ 2FA enablement/disablement
✓ Unsuccessful login attempts
✓ Failed moderation actions
```

### 15.11 Email Configuration

**System Emails to Send:**
```
Authentication:
✓ Account activation link
✓ Password reset link (24h expiry)
✓ Login notifications (optional)
✓ 2FA backup codes (when enabled)

Content:
✓ Submission removed, with the admin's reason (replaces "approved" /
  "rejected" / "changes requested" — publishing itself is immediate and
  silent; removal is the only outcome worth emailing about, §5.1)
✓ Publisher onboarding welcome

User Management:
✓ Promoted to publisher (with instructions)
✓ Promoted to minor admin
✓ Removed from admin role
✓ Account deactivation notice

Digest:
✓ Weekly digest (for users, optional)
✓ Monthly analytics (for publishers)
✓ Admin activity report (for super admin)
```

### 15.12 Image Optimization

> **Not implemented yet.** Images today are just stored public URLs
> (mock `picsum.photos` seed data, or whatever a publisher pastes/adds)
> with no server-side processing — `Pillow` was dropped from the backend
> dependencies (§3) since nothing uses it. When real photo uploads are
> built, **Supabase Storage** is the target (replacing "local filesystem"
> below), and it can serve resized/transformed images itself rather than
> the backend pre-generating thumbnails. Everything below is still the
> target design, not current behavior.

**For Performance:**
```
Frontend:
✓ Compress before upload (mobile)
✓ Resize to max 1200px width
✓ Convert to WebP (where supported)
✓ Lazy load feed images

Backend:
✓ Store original + thumbnails (200px, 400px, 800px)
✓ Serve appropriate size based on device
✓ CDN-ready structure (if Cloudflare added later)
✓ Cache headers: 30 days for thumbnails

Sizes:
✓ Announcement thumbnail: 200x200px (5KB max)
✓ Feed preview: 400x300px (15KB max)
✓ Full image: 800x600px (50KB max)
✓ Avatar: 200x200px (5KB max)
```

### 15.13 Error Handling & Recovery

**Frontend Error States:**
```
✓ Network timeout → Retry button + offline indicator
✓ Login failed → Show error message + password reset link
✓ Upload failed → Queue for retry + user notification
✓ Sync conflict → Show merge options to user
✓ App crash → Crash report + auto-recovery

Backend Error Responses:
✓ 400 Bad Request → Validation errors with field details
✓ 401 Unauthorized → Token expired/invalid
✓ 403 Forbidden → Insufficient permissions
✓ 404 Not Found → Resource not found
✓ 429 Too Many Requests → Rate limited + retry after
✓ 500 Server Error → Logged for investigation
✓ 503 Service Unavailable → Maintenance mode
```

### 15.14 Rate Limiting

**API Limits (per IP):**
```
Authentication:
✓ Login attempts: 5 per minute
✓ Password reset: 3 per hour
✓ Account creation: 1 per minute

Content Operations:
✓ Create/update: 10 per minute
✓ Delete: 1 per minute (to prevent accidents)
✓ Moderation actions: 50 per minute

General API:
✓ Read operations: 100 per minute
✓ Search: 30 per minute
```

### 15.15 Backup & Disaster Recovery

> **Now Supabase's responsibility, not ours.** Since the database and
> file storage both moved to Supabase (§2.1, §3), there's no NAS, no
> RAID, no self-managed backup cron jobs to build or run — Supabase
> handles Postgres backups and storage redundancy on its infrastructure.
> What's still on us: knowing Supabase's actual backup/retention terms for
> the plan we're on (free vs. paid tiers differ), and testing that we can
> actually restore from a Supabase backup if needed. The original
> self-hosted plan is kept below for reference only.

**Original self-hosted plan (superseded):**
```
Database:
✓ Full backup: Daily (encrypted)
✓ Incremental: Every 6 hours
✓ Retention: 30 days
✓ Verification: Daily integrity check
✓ Recovery test: Monthly

File Storage:
✓ Copy to NAS: Daily
✓ Off-site copy: Weekly (if available)
✓ Retention: 60 days
✓ Redundancy: RAID 1 (mirrored)

Recovery:
✓ RTO: 4 hours (target recovery time)
✓ RPO: 6 hours (max data loss)
✓ Documented procedures
✓ Tested quarterly
```

### 15.16 GDPR Compliance

**User Rights:**
```
✓ Data export: All personal data in JSON
✓ Data deletion: Complete removal from system
✓ Right to be forgotten: Pseudonymization option
✓ Consent management: Opt-in for non-essential data
✓ Privacy policy: Clear, accessible language
✓ Terms of service: Transparent data usage

Technical Measures:
✓ Data minimization: Collect only necessary
✓ Encryption: In transit and at rest
✓ Access control: Role-based, logged
✓ Data retention: Delete after 2 years (if no activity)
✓ Breach notification: 72 hours to DPA
```

---

## CONCLUSION

**Final Architecture — One App, Not Two (see §2.1 for the full "as-built"
picture):**
- ✅ **One Student/Staff App** (Android + Web today; iOS pending Mac/Xcode
  access, §3) with role-based feature visibility
- ✅ **No separate Admin Portal build** — Super Admin & Minor Admin are an
  extra tab inside the same app, gated exactly like the Publisher tab
- ✅ **Extensible Services Framework:** Transport (**Boda only for now**)
  and Accommodation are both live — Accommodation was not deferred to
  Phase 2 as originally planned
- ✅ **Role Hierarchy:** Student → Publisher → Minor Admin → Super Admin
- ✅ **Smart Feature Access:** Same app, different features per role —
  now true for admins too, not just publishers
- ✅ **Publish-immediately, remove-only moderation** (§5.1) — replaces
  the original pending-review/approve/reject workflow everywhere it
  appeared in this document
- ✅ **Supabase** for Postgres, Auth, and Storage — replaces the
  self-hosted PostgreSQL + custom JWT + local filesystem plan (§3)
- ✅ **Scalable & Maintainable:** one app, one backend, managed data tier

**Status:** Student/Staff App is functional on mock data end-to-end
(auth, publishing, drafts, admin moderation, Boda search, semester
pricing for hostels). The Python/FastAPI/Supabase backend in `backend/`
is scaffolded and running locally against this same contract — wiring
the Flutter app's repositories to it (replacing the `Mock*Repository`
classes with HTTP calls) is the next step, not yet done.

**Immediate next steps:**
1. Create the Supabase project, run `backend/supabase/migrations/0001_init.sql`
2. Fill in `backend/.env` with the project's real keys and confirm
   `uvicorn app.main:app --reload` boots against it
3. Swap each Flutter `Mock*Repository` for an `Http*Repository` hitting
   the endpoints in §9 (the repository interfaces were kept API-shaped
   from the start for exactly this swap)
4. Wire Supabase Storage for real photo uploads (§15.12)
5. iOS build, once Mac/Xcode access exists (§3)

---

**Document prepared by:** Claude Haiku 4.5, updated by Claude Sonnet 5
**Version:** 6.0 - Updated to match the actual implementation (Supabase
backend, one-app admin, publish-immediately moderation, Boda-only
Transport, semester-priced hostels)
**Status:** Living document — frontend mostly built on mock data, backend
scaffolded, integration pending
**Date:** September 2026 (original), updated September 2026
