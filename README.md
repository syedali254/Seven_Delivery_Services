
# Seven Delivery Service

An admin-facing delivery management system built with Flutter and Supabase. Handles rider management, order tracking, QR-based delivery verification, and real-time dashboard insights.

## Features

- **Authentication** — Admin login via Supabase Auth
- **Dashboard** — Overview of orders, riders, and delivery stats
- **Order Management** — Create, assign, track, and update delivery orders
- **Rider Management** — Register riders, manage availability and assignments
- **QR Scanner** — Scan-based delivery verification using device camera
- **Rider Registration** — Onboard new riders with profile details
- **Cross-platform** — Runs on Android, iOS, Web, Windows, macOS, and Linux

## Tech Stack

| Layer      | Tech                        |
|------------|-----------------------------|
| Framework  | Flutter (Dart)              |
| Backend    | Supabase (Auth, Database, RLS) |
| Database   | PostgreSQL (via Supabase)   |
| QR Scanning| mobile_scanner              |
| HTTP       | http package                |
| Fonts      | Google Fonts                |

## Prerequisites

- Flutter SDK `>=3.11.5`
- Dart SDK (bundled with Flutter)
- A Supabase project with the schema applied (see `database_schema.sql`)

## Setup

1. **Clone the repo**
   ```bash
   git clone https://github.com/syedali254/seven_delivery_service.git
   cd seven_delivery_service
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase credentials**

   Create `lib/core/config/secrets.dart`:
   ```dart
   class AppSecrets {
     static const String supabaseServiceKey = 'YOUR_SERVICE_ROLE_KEY';
   }
   ```

   Update `lib/core/services/supabase_service.dart` with your Supabase project URL and anon key.

4. **Set up the database**

   Run `database_schema.sql` in your Supabase SQL editor to create the required tables and RLS policies.

5. **Run the app**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── main.dart
├── core/
│   ├── config/          # App secrets and configuration
│   ├── models/          # Data models
│   ├── services/        # Supabase and API services
│   ├── theme/           # App theme and styling
│   └── widgets/         # Shared widgets
└── features/
    ├── auth/            # Login and authentication
    ├── dashboard/       # Admin dashboard
    ├── orders/          # Order management
    ├── rider_management/# Rider CRUD operations
    ├── rider_registration/ # New rider onboarding
    ├── qr_scanner/      # QR code scanning
    ├── profile/         # User profile
    └── navigation/      # Bottom nav and routing
```

## Database Schema

The app uses four main tables:

- **admins** — Linked to Supabase Auth, controls admin access
- **riders** — Rider profiles with status tracking (available/busy/offline)
- **orders** — Delivery orders with status flow (pending → processing → out for delivery → delivered)
- **logs** — Activity logs for auditing

Row Level Security is enabled on all tables. See `database_schema.sql` for the full schema.

## Build

```bash
# Android APK
flutter build apk --release

# Web
flutter build web

# iOS
flutter build ios --release
```

## License

This project is proprietary. All rights reserved.
```
