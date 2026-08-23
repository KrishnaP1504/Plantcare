# Plantcare - AI-Powered Botanical Health & Garden Management

**Plantcare** is a modern, production-grade Flutter application designed for real-time plant identification, disease pathology diagnosis, personalized plant care scheduling, and garden management. Powered by advanced artificial intelligence (Plant.id v3 by Kindwise & Pl@ntNet API v2), Firebase Authentication, Cloud Firestore, and custom computer vision algorithms, Plantcare provides plant enthusiasts with accurate botanical identification and actionable treatment plans for agricultural and houseplant diseases.

---

## Table of Contents
1. [Tech Stack & Dependencies](#tech-stack--dependencies)
2. [Project Architecture & Design Patterns](#project-architecture--design-patterns)
3. [Directory & File Structure](#directory--file-structure)
4. [Authentication & Database System](#authentication--database-system)
5. [API Integrations & Pathology Engine](#api-integrations--pathology-engine)
6. [Design System, Theme & Color Palette](#design-system-theme--color-palette)
7. [App Walkthrough & Screen-by-Screen Flow](#app-walkthrough--screen-by-screen-flow)
8. [Technical Challenges Faced & Solutions Implemented](#technical-challenges-faced--solutions-implemented)
9. [Installation & Setup Guide](#installation--setup-guide)

---

## Tech Stack & Dependencies

### Core Framework & State Management
* **Flutter SDK**: 3.x+ (Dart 3.x)
* **State Management**: `provider` (MultiProvider pattern with `ChangeNotifier`)
* **Navigation & Routing**: `go_router` (Declarative URL-based routing with query parameters)
* **Environment Configuration**: `flutter_dotenv` (`.env` file key management)

### Backend & Cloud Infrastructure
* **Firebase Core**: `firebase_core`
* **Authentication**: `firebase_auth`, `google_sign_in`
* **Cloud Database**: `cloud_firestore` (NoSQL Document Store)
* **Secure Storage**: `flutter_secure_storage` (Hardware-encrypted storage for tokens)

### AI, Computer Vision & Media
* **Plant.id (Kindwise) API v3**: Botanical classification & health assessment endpoint
* **Pl@ntNet API v2**: Fallback species identification engine
* **Image Processing**: `image` (For EXIF metadata stripping and pixel-level pathology color ratio analysis)
* **Camera & Device Sensors**: `camera`, `image_picker`, `permission_handler`

---

## Project Architecture & Design Patterns

Plantcare follows a clean, modular **Layered Provider Architecture**:

```
 ┌─────────────────────────────────────────────────────────┐
 │                       UI Layer                          │
 │      (Screens, Custom Widgets, Modals, Animations)      │
 └───────────────────────────┬─────────────────────────────┘
                             │ Consumer / context.watch
 ┌───────────────────────────▼─────────────────────────────┐
 │                    Provider Layer                       │
 │ (AuthProvider, PlantProvider, ScanProvider, NavProvider)│
 └───────────────────────────┬─────────────────────────────┘
                             │ Service calls
 ┌───────────────────────────▼─────────────────────────────┐
 │                     Service Layer                       │
 │(AuthService, PlantService, ScanService, StorageService) │
 └───────────────────────────┬─────────────────────────────┘
                             │ API Requests & Firestore SDK
 ┌───────────────────────────▼─────────────────────────────┐
 │                External Data Sources                    │
 │  (Plant.id v3 API, Pl@ntNet API, Firebase Auth/Store)   │
 └─────────────────────────────────────────────────────────┘
```

### Core Architectural Concepts:
1. **Unidirectional Data Flow**: UI widgets trigger actions in Providers -> Providers delegate business logic to Services -> Services mutate Firestore or request APIs -> Providers notify listeners -> UI rebuilds.
2. **Declarative Deep-Linking Router (`go_router`)**: Supports nested navigation, query parameters (e.g., `/plant/:id?isGlobal=true`), and dynamic route guards based on authentication state.
3. **Isolate-Based Heavy Processing**: Image processing (such as stripping EXIF location metadata) is offloaded to a background Dart isolate using `compute(...)` to preserve 60 FPS UI performance.

---

## Directory & File Structure

```
Plantcare/
├── .env                         # Environment variables (API keys & endpoints)
├── pubspec.yaml                 # Package dependencies and asset manifests
├── ABOUT_PROJECT.md             # Comprehensive project documentation
├── assets/
│   ├── images/                  # Botanical illustrations, logos, and UI graphics
│   └── icons/                   # Custom vector icons
└── lib/
    ├── main.dart                # Application entry point, Firebase init & dotenv load
    ├── app.dart                 # MaterialApp wrapper with GoRouter configuration
    ├── firebase_options.dart    # Firebase configuration for Web, Android, and iOS
    │
    ├── core/
    │   ├── constants/
    │   │   ├── app_colors.dart  # Global design system palette tokens
    │   │   └── app_styles.dart  # Global typography and card decoration styles
    │   └── router/
    │       └── app_router.dart  # GoRouter definitions and route parameter parsing
    │
    ├── models/
    │   ├── user_model.dart      # User profile entity schema
    │   ├── plant_model.dart     # Plant entity schema (Garden & Global search)
    │   └── diagnosis_model.dart # Pathology diagnosis & disease result data model
    │
    ├── providers/
    │   ├── auth_provider.dart   # Authentication state & profile mutation provider
    │   ├── plant_provider.dart  # My Garden list & global search cache provider
    │   ├── scan_provider.dart   # Camera scan execution & diagnosis state provider
    │   └── navigation_provider.dart # Bottom navigation bar index provider
    │
    ├── services/
    │   ├── auth_service.dart    # Firebase Auth & Firestore User CRUD operations
    │   ├── plant_service.dart   # Firestore Garden plants CRUD operations
    │   ├── scan_service.dart    # Plant.id / Pl@ntNet API client & Vision pathology engine
    │   ├── storage_service.dart # Secure token storage helper
    │   ├── onboarding_service.dart # First-launch flag persistent manager
    │   └── permission_service.dart # Camera & photo library permission handler
    │
    ├── widgets/
    │   ├── custom_button.dart   # Primary & secondary rounded button widgets
    │   ├── custom_text_field.dart # Form input fields with error states & password toggles
    │   ├── plant_card.dart      # Reusable garden plant display card widget
    │   └── custom_bottom_bar.dart # Floating glassmorphic bottom navigation widget
    │
    └── screens/
        ├── splash/
        │   └── splash_screen.dart      # Animated brand entry screen
        ├── onboarding/
        │   └── onboarding_screen.dart  # Interactive 3-step feature introduction
        ├── auth/
        │   ├── login_screen.dart       # Email & Google OAuth login screen
        │   └── register_screen.dart    # New user registration screen
        ├── dashboard/
        │   └── dashboard_screen.dart   # Main shell wrapping home, garden, schedule, profile
        ├── home/
        │   └── home_screen.dart        # Dashboard overview, global search & diagnose cards
        ├── garden/
        │   └── my_garden_screen.dart   # Full garden collection & plant sorting view
        ├── schedule/
        │   └── schedule_screen.dart    # Watering & fertilizer task reminder timeline
        ├── camera/
        │   └── camera_screen.dart      # Live camera viewfinder & gallery picker
        ├── scan_result/
        │   └── scan_result_screen.dart # Pathology report, disease warnings & action plan
        ├── plant_detail/
        │   └── plant_detail_screen.dart# Botanical overview, care tips & disease history
        ├── profile/
        │   ├── profile_screen.dart     # User profile dashboard & settings options
        │   ├── account_settings_screen.dart # Edit profile picture, name, username, bio
        │   └── garden_settings_screen.dart  # Edit garden name, default garden, sorting
        └── encyclopedia/
            └── encyclopedia_screen.dart # Botanical plant knowledge library
```

---

## Authentication & Database System

### 1. Firebase Authentication (`AuthService`)
* **Email & Password Authentication**: Enables secure registration and login with input validation.
* **Google OAuth Sign-In**: Integrated via `google_sign_in` for one-tap authentication.
* **Session Persistence**: User sessions are automatically remembered using `FirebaseAuth.instance.authStateChanges()`. User access tokens and local preferences are encrypted via `flutter_secure_storage`.

### 2. Cloud Firestore Database Architecture
All application data is synced in real-time with Google Cloud Firestore:

#### **Collection: `users/{userId}`**
```json
{
  "uid": "USER_UID_STRING",
  "email": "user@example.com",
  "displayName": "Alex Gardener",
  "username": "alex_plants",
  "photoUrl": "https://firestore.storage/profile.jpg",
  "bio": "Urban jungle collector and indoor plant lover",
  "gardenName": "Alex's Urban Oasis",
  "defaultGarden": "Indoor Living Room",
  "plantSorting": "Recently Added",
  "createdAt": "2026-08-21T10:00:00Z"
}
```

#### **Collection: `users/{userId}/plants/{plantId}`**
```json
{
  "id": "plant_101",
  "name": "Tulsi (Holy Basil)",
  "scientificName": "Ocimum tenuiflorum",
  "imageUrl": "https://images.unsplash.com/photo-tulsi.jpg",
  "description": "Tulasi, also known as Holy basil or Sacred basil, is a sacred and aromatic plant widely grown for its medicinal and spiritual benefits.",
  "category": "Herb / Outdoor",
  "waterNeed": "Moderate",
  "sunlight": "Direct Sun",
  "careIntervalDays": 2,
  "lastWatered": "2026-08-20T08:00:00Z",
  "healthStatus": "Healthy",
  "addedAt": "2026-08-15T12:00:00Z"
}
```

---

## API Integrations & Pathology Engine

### 1. External APIs Used (Placeholders)
The application connects to external botanical intelligence endpoints configured in `.env`:

```env
# Plantnet API Endpoint
PLANTNET_API_KEY=<YOUR_PLANTNET_API_KEY>
PLANTNET_API_URL=https://my-api.plantnet.org/v2/identify/all

# Plant.id (Kindwise) API v3 Endpoint
PLANTID_API_KEY=<YOUR_PLANTID_API_KEY>
PLANTID_API_URL=https://api.plant.id/v3/identification
```

> **Security Note**: Real API keys are strictly excluded from repository commits and stored in `.env`.

### 2. Multi-Tier AI Pathology & Diagnosis Engine Flow
When a user takes or uploads a photo via `CameraScreen`:

```
 [User Captures Photo]
           │
           ▼
 [Offload to Isolate: Strip EXIF Location Metadata]
           │
           ▼
 [Tier 1: Plant.id API v3 Request]
 POST /v3/identification?details=description,treatment,common_names,scientific_name
 Headers: Api-Key: <YOUR_PLANTID_API_KEY>
 Payload: { "images": [rawBase64String], "health": "all" }
           │
     ┌─────┴────────────────────────┐
     │ Is Valid Plant?              │
     ├──────────────────────────────┤
     │ YES: Extract Species & Health│
     │ NO:  Throw NotAPlantException │
     └─────┬────────────────────────┘
           │
     ┌─────┴──────────────────────────────────────────────────────┐
     │ Health Probability Check                                   │
     ├────────────────────────────────────────────────────────────┤
     │ is_healthy.probability < 0.60                              │
     │ -> Parse Real Diseases, Pathogen About Text & Action Plan  │
     │ is_healthy.probability >= 0.60                             │
     │ -> Return Healthy Status ("No Diseases Detected")          │
     └────────────────────────────────────────────────────────────┘
```

### 3. Detected Diseases Supported by Engine:
* **Downy Mildew** (*Plasmopara viticola*)
* **Powdery Mildew** (*Erysiphe spp.*)
* **Black Spot / Septoria Leaf Spot** (*Diplocarpon rosae*)
* **Rust Disease** (*Puccinia spp.*)
* **Bacterial Blight** (*Xanthomonas / Pseudomonas*)
* **Root Rot** (*Pythium / Phytophthora*)
* **Chlorosis (Nutrient Deficiency)**
* **Spider Mite Damage**
* **Anthracnose** (*Colletotrichum spp.*)

---

## Design System, Theme & Color Palette

Plantcare follows a modern, botanical-inspired **Dark Emerald & Cream Design System** featuring subtle glassmorphic elements and curated color tokens:

### Brand Color Palette Code Reference:

| Token Name | Hex Code | Flutter Color Object | Usage / Application |
| :--- | :--- | :--- | :--- |
| **Primary Deep Emerald** | `#1B4D3E` | `Color(0xFF1B4D3E)` | Primary buttons, headers, active nav items, brand branding |
| **Soft Sage Background** | `#FAFBF8` | `Color(0xFFFAFBF8)` | Global scaffold screen background |
| **Light Sage Card Fill** | `#EAF2EC` | `Color(0xFFEAF2EC)` | Search bars, secondary input fields, light containers |
| **Warning Red (Disease)**| `#DC2626` | `Color(0xFFDC2626)` | Pathology warning pill badges, alert icons, danger buttons |
| **Light Red Card Fill** | `#FEF2F2` | `Color(0xFFFEF2F2)` | Disease warning container background card |
| **Light Red Border** | `#FECACA` | `Color(0xFFFECACA)` | Pathology card outer stroke border |
| **Healthy Green** | `#16A34A` | `Color(0xFF16A34A)` | Healthy status badge, success indicators |
| **Healthy Light Card** | `#F0FDF4` | `Color(0xFFF0FDF4)` | Healthy plant verification card background |
| **Accent Gold / Amber** | `#F59E0B` | `Color(0xFFF59E0B)` | Care schedule icons, warning stars, probability tags |
| **Dark Slate Text** | `#1F2937` | `Color(0xFF1F2937)` | Main title headings, primary body prose text |
| **Muted Grey Text** | `#6B7280` | `Color(0xFF6B7280)` | Subtitles, captions, metadata labels |

---

## App Walkthrough & Screen-by-Screen Flow

### 1. Splash & Onboarding (`/splash`, `/onboarding`)
* **Splash Screen**: Animated logo reveal with smooth transition checking auth status.
* **Onboarding**: 3-step interactive feature carousel demonstrating plant identification, disease diagnosis, and watering reminders.

### 2. Authentication (`/login`, `/register`)
* Botanical leaf artwork overlays with glassmorphic cards.
* Form validation for email/password and single-tap Google OAuth sign-in.

### 3. Dashboard / Home (`/dashboard`, `/home`)
* **Small Greeting**: Displays compact welcome message with the user's `@username` (e.g., *"Hello, @alex_plants"*).
* **Global Plant Search Bar**: Allows searching any plant species in the world. Clicking the **Go button** fetches real-time data and opens `PlantDetailScreen` with `isGlobal=true` (hiding "Add to Garden" and "Diagnose" action buttons).
* **My Garden Preview**: Shows 3 featured user plants with direct links to full garden management.
* **Diagnose Card**: Quick entry point to scan leaves for diseases.

### 4. Camera Viewfinder & Non-Plant Detection (`/camera`)
* Full-screen live camera preview with flash toggle and photo gallery import.
* **Non-Plant Validation**: If a user uploads an image of something other than a plant (e.g., shoes, car, furniture), the app triggers a friendly modal popup: *"Please click a picture of a plant"*.

### 5. Pathology Scan Result (`/scan-result`)
* Displays identified plant species name, scientific name, and species confidence match.
* **Disease Detected State**: Renders a red pathology warning card (`#FEF2F2`) with a flexible warning pill badge (`#DC2626`) showing title-cased disease name (e.g. `Nutrient Deficiency Detected • 88% Match`), **About Pathogen** explanation, and bulleted **Treatment & Action Plan**.
* **Healthy State**: Renders a green verification card (`#F0FDF4`) displaying **No Diseases Detected**.

### 6. My Garden (`/garden`)
* Grid/List view of all user's saved plants with category filters and sorting options.

### 7. Profile & Account Settings (`/profile`, `/account-settings`, `/garden-settings`)
* **Profile Overview**: Displays user profile avatar, username, and garden statistics.
* **Account Settings (`/account-settings`)**: Allows editing Name, Username, Profile Picture, and Personal Bio.
* **Garden Settings (`/garden-settings`)**: Allows editing Garden Name, Default Garden Location, and Plant Sorting preferences.

---

## Technical Challenges Faced & Solutions Implemented

### 1. Challenge: Plant.id v3 returning `Unknown Plant` with `95% Confidence`
* **Root Cause**: The API payload missing explicit `details` query parameters caused the classification object to return without common names, defaulting to `Unknown Plant` while hardcoding a high confidence score.
* **Solution**: Updated API URL to `$plantIdUrl?details=description,treatment,common_names,scientific_name` and calculated species confidence dynamically (`speciesConfidence = topSuggestion['probability']`). If a species cannot be recognized, the service throws `NotAPlantException` prompting the user for a clearer leaf photo.

### 2. Challenge: UI Right Overflow Strip on Red Disease Warning Badges
* **Root Cause**: The red warning pill badge used a rigid `Row` without wrapping the text widget, causing long disease names (like `Chlorosis (Nutrient Deficiency)`) to overflow the container by 25 pixels (`RIGHT OVERFLOWED BY 25 PIXELS`).
* **Solution**: Wrapped the text widget inside `Flexible(child: Text(...))` and converted disease names to Title Case (`_toTitleCase(...)`), ensuring 100% responsive text wrapping on all mobile screens.

### 3. Challenge: EXIF Metadata & Location Privacy Leak
* **Root Cause**: Photos taken directly from phone cameras contain GPS metadata which increases payload size and exposes user location to external API endpoints.
* **Solution**: Implemented `_stripExifIsolate(...)` offloaded to a secondary thread via Flutter's `compute(...)` function, stripping EXIF headers safely without blocking the UI thread.

### 4. Challenge: Non-Plant Image Scans
* **Root Cause**: Users taking photos of non-botanical items could trigger confusing fallback responses.
* **Solution**: Evaluated `is_plant.binary` and `is_plant.probability` from the API response payload. If probability $< 0.10$, `NotAPlantException` is thrown, triggering the popup: *"Please click a picture of a plant"*.

---

## Installation & Setup Guide

### Prerequisites
* Flutter SDK (v3.19.0 or higher)
* Android Studio / Xcode (for emulator or physical device testing)

### Step 1: Clone the Repository
```bash
git clone https://github.com/KrishnaP1504/Plantcare.git
cd Plantcare
```

### Step 2: Configure Environment Variables
Create a `.env` file in the root directory:
```env
PLANTNET_API_KEY=<YOUR_PLANTNET_API_KEY>
PLANTNET_API_URL=https://my-api.plantnet.org/v2/identify/all
PLANTID_API_KEY=<YOUR_PLANTID_API_KEY>
PLANTID_API_URL=https://api.plant.id/v3/identification
```

### Step 3: Install Dependencies
```bash
flutter pub get
```

### Step 4: Run Static Analysis & Unit Tests
```bash
flutter analyze
flutter test
```

### Step 5: Launch the Application
```bash
flutter run
```

---
*Created for botanical enthusiasts and plant lovers worldwide.*
