# HolyNikah - Flutter Application

A modern Flutter matrimonial and lifestyle application featuring VIP and Normal matchmaking, customizable profile templates, interactive video reels, and an Astrolabe-inspired media and advertisement hub.

---

## 🌟 Key Features

### 1. 💍 Matrimonial & Matchmaking
- **VIP & Normal Registers**: Distinct onboarding, tier selection, and profile browsing workflows.
- **Interactive Partner Profiles**: Rich partner discovery cards with contact request / phone access approval workflows.
- **Customizable Profile Templates**: Dynamic Islamic template renderer supporting bespoke wedding bio themes (Emerald, Rose Gold, Midnight Royale, etc.).
- **Smart Category Filtering**: Multi-category support for normal users and tier-based single-category selection for VIP users.

### 2. 🌌 Astrolabe Ads & Media Hub
- **Celestial Orbital Navigation**: Astrolabe-themed interactive hub with animated rotating brass rings and trigonometric orbital positioning.
- **Vertical Fullscreen Feeds**: TikTok / Instagram Reels-style smooth vertical swipe player for images and video reels.
- **Content Channels**:
  - **Prayers**: Dedicated prayer cards and spiritual content feed.
  - **Antiaging**: Skincare and wellness video/image feed (`/api/antiaging`).
  - **Aura**: Lifestyle and personality feed (`/api/aura`).
  - **Replenish Except His Own**: Wellness channel (`/api/replenish-except-his-own`).
  - **Shadi Vibes**: Wedding inspiration & stories (`/api/shadi-vibes`).
  - **Space Advertisements 1 & 2**: In-menu partner advertisements (`/api/advertisement1`, `/api/advertisement2`).
- **View Analytics Tracking**: Automatic in-flight view recording with client-side deduplication.

### 3. 👤 Dynamic Profile Management
- **Animated Lattice Canvas**: Fluid, low-power procedural lattice background animation on the profile screen.
- **Profile Customization**: In-place editing of personal details, matrimonial preferences, partner expectations, and category subscriptions.
- **Security & Privacy**: Verified mobile numbers, phone visibility gating, and OTP-based authentication.

---

## 🏗️ Architecture & Project Structure

The project follows a modular, layered architecture (UI, Logic, and Data) powered by `Provider` for state management and `auto_route` for declarative routing.

```
lib/
├── core/                               # Core application foundation
│   ├── api/                            # ApiClient, ApiResponse & interceptors
│   ├── constants/                      # App-wide constants & keys
│   ├── provider/                       # Global root providers
│   ├── router/                         # Auto Route declarations & guards
│   ├── services/                       # Firebase Auth, storage & notifications
│   ├── theme/                          # AppColors, AppTypography, AppTheme
│   ├── utils/                          # AppLogger, media helpers, date formatters
│   └── widgets/                        # Reusable core widgets (buttons, inputs, snackbars)
├── models/                             # Shared data models (User, Prayer, Video, etc.)
├── modules/                            # Domain-driven feature modules
│   ├── ads/                            # Astrolabe navigation & common ad feeds
│   │   ├── screens/                    # AdsScreen, CommonAdFeedScreen
│   │   └── services/                   # CommonAdFeedService & analytics
│   ├── category/                       # Category selection & tier cards
│   ├── donaters/                       # Donation & community support
│   ├── home/                           # Main navigation tabs & dashboard
│   ├── login/                          # Mobile & Google OTP authentication
│   ├── myprofile/                      # Profile view, editing & lattice animation
│   ├── partner/                        # Match browsing, search & partner detail views
│   ├── reels/                          # Video reels player & feed
│   ├── registration/                   # Multi-step user registration wizard
│   ├── template/                       # Profile template selection & renderer
│   └── splash/                         # Initial launch & session bootstrap
├── application.dart                    # MaterialApp & global styling setup
├── main.dart                           # Entrypoint & Firebase initialization
└── multi_provider.dart                 # Dependency injection provider tree
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK**: `>=3.10.0`
- **Dart SDK**: `>=3.0.0`
- **Laravel Backend**: Active instance running (e.g. `php artisan serve --port 8000`)
- **Firebase Project**: Configured for Android and iOS authentication

### Installation

1. **Clone the Repository**:
   ```bash
   git clone <repository_url>
   cd holynikkah
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Code & Routes**:
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Configure Environment & Endpoints**:
   Update `lib/core/utils/constants.dart` with your local or production backend IP:
   ```dart
   static const String defaultLocalIp = '192.168.1.X'; // Or your machine's IP
   ```

5. **Run the Application**:
   ```bash
   flutter run
   ```

---

## 📡 API Specifications & Integrations

### Backend Endpoints Overview

| Category / Feature | Feed Route (GET) | View Tracking Route (POST) |
|---|---|---|
| **Antiaging** | `/api/antiaging` | `/api/antiaging/{id}/views` |
| **Aura** | `/api/aura` | `/api/aura/{id}/views` |
| **Replenish** | `/api/replenish-except-his-own` | `/api/replenish-except-his-own/{id}/views` |
| **Shadi Vibes** | `/api/shadi-vibes` | `/api/shadi-vibes/{id}/views` |
| **Advertisement 1** | `/api/advertisement1` | `/api/advertisement1/{id}/views` |
| **Advertisement 2** | `/api/advertisement2` | `/api/advertisement2/{id}/views` |
| **Prayers** | `/api/prayers/feed` | `/api/prayers/{id}/views` |

---

## 🛠️ Code Generation & Build Commands

```bash
# Generate routes & json serializable classes
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes during active development
flutter pub run build_runner watch --delete-conflicting-outputs

# Clean generated artifacts
flutter pub run build_runner clean

# Run static analysis
flutter analyze

# Execute test suite
flutter test
```

---

## 📦 Key Dependencies

| Package | Purpose |
|---|---|
| [`provider`](https://pub.dev/packages/provider) | Reactive State Management |
| [`auto_route`](https://pub.dev/packages/auto_route) | Strongly-typed Navigation & Deep Linking |
| [`cached_network_image`](https://pub.dev/packages/cached_network_image) | High-performance image caching |
| [`video_player`](https://pub.dev/packages/video_player) | Fullscreen and in-feed video playback |
| [`flutter_screenutil`](https://pub.dev/packages/flutter_screenutil) | Responsive UI scaling across devices |
| [`firebase_auth`](https://pub.dev/packages/firebase_auth) | Phone & Google Authentication |
| [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Encrypted token storage |
| [`shimmer`](https://pub.dev/packages/shimmer) | Polished loading placeholders |
