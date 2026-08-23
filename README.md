<div align="center">

  # 🌿 Plantcare
  ### AI-Powered Botanical Health, Disease Pathology & Garden Care Application

  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Auth%20%26%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
  [![Plant.id API](https://img.shields.io/badge/AI--Engine-Plant.id%20v3-10B981)](https://kindwise.com)
  [![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

  *Discover plant species instantly, diagnose agricultural and houseplant diseases with real-time AI pathology, and build your personalized urban garden.*

</div>

---

## 📖 About Plantcare

**Plantcare** is a modern, production-ready Flutter mobile application designed to simplify plant ownership and agricultural plant protection. Utilizing advanced computer vision artificial intelligence (Plant.id v3 by Kindwise and Pl@ntNet API v2), Firebase Authentication, and Cloud Firestore NoSQL database, Plantcare allows users to scan plant leaves, identify species, diagnose diseases, obtain actionable treatment plans, and track watering schedules.

> For a complete architectural breakdown, database schemas, color palettes, and deep technical details, see [**ABOUT_PROJECT.md**](ABOUT_PROJECT.md).

---

## ✨ Key Features

* 🔍 **Instant AI Plant Identification**: Identify houseplants, trees, herbs, succulents, and crops from a single leaf photo.
* 🩺 **Real Pathology & Disease Diagnosis Engine**: Accurately diagnoses fungal, bacterial, and pest diseases (Downy Mildew, Powdery Mildew, Black Spot, Rust, Anthracnose, Bacterial Blight, Root Rot, Chlorosis, Spider Mites) with step-by-step treatment action plans.
* 🛡️ **Non-Plant Image Filter**: Automatically validates captured photos and prompts users (*"Please click a picture of a plant"*) if a non-plant object is scanned.
* 🌐 **Global Plant Search**: Search any botanical species across the world from the dashboard and view detailed care requirements.
* 🪴 **My Garden Collection**: Manage your personal indoor/outdoor garden synced in real-time to Firebase Cloud Firestore.
* ⏰ **Smart Care Scheduling**: Track watering and fertilizer schedules to keep plants thriving.
* 👤 **Account & Garden Customization**: Edit profile picture, display name, username, bio, garden name, and sorting options.

---

## 🎨 Design System & Color Palette

Plantcare features a botanical-inspired **Dark Emerald & Cream** aesthetic with glassmorphic accents:

| Token Name | Hex Code | Purpose |
| :--- | :--- | :--- |
| 🟢 **Primary Emerald** | `#1B4D3E` | Brand buttons, active tabs, header icons |
| 🍦 **Soft Sage Cream** | `#FAFBF8` | Global background canvas |
| 🌿 **Light Sage Fill** | `#EAF2EC` | Input fields, card backgrounds |
| 🔴 **Pathology Warning Red** | `#DC2626` | Disease warning badges & alerts |
| 🌸 **Warning Card Fill** | `#FEF2F2` | Pathology report card background |
| ❇️ **Healthy Green** | `#16A34A` | Healthy status verification badge |
| 🟡 **Amber Gold** | `#F59E0B` | Care task icons & match probability tags |

---

## 🛠 Tech Stack

* **Frontend Framework**: Flutter (Dart 3.x)
* **State Management**: `provider` (MultiProvider architecture)
* **Navigation & Routing**: `go_router` (Declarative deep linking)
* **Backend Cloud**: Firebase Authentication & Cloud Firestore Database
* **AI & Pathology APIs**: Plant.id (Kindwise) API v3 & Pl@ntNet API v2
* **Image Isolate Processing**: `image` package (Stripping EXIF location metadata in background isolate)
* **Storage**: `flutter_secure_storage` & `flutter_dotenv`

---

## 📁 Repository Structure

```
Plantcare/
├── .env.example                 # Environment variables template
├── ABOUT_PROJECT.md             # Full architecture & technical documentation
├── README.md                    # Project landing overview
├── pubspec.yaml                 # Flutter package manifest
├── assets/
│   └── images/                  # Botanical graphics & UI assets
└── lib/
    ├── main.dart                # Main entry point & Firebase initialization
    ├── app.dart                 # MaterialApp & GoRouter route definition
    ├── core/                    # Theme, constants, & route definitions
    ├── models/                  # User, Plant, & Diagnosis data schemas
    ├── providers/               # AuthProvider, PlantProvider, ScanProvider
    ├── services/                # AuthService, PlantService, ScanService
    ├── widgets/                 # Reusable UI cards, inputs, & glassmorphic nav bar
    └── screens/                 # Splash, Auth, Home, Camera, ScanResult, Garden, Profile
```

---

## 🚀 Quick Setup & Installation

### Prerequisites
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.19.0 or higher)
* Android Studio / VS Code with Flutter extension
* Android Emulator or physical device

### 1. Clone the Repository
```bash
git clone https://github.com/KrishnaP1504/Plantcare.git
cd Plantcare
```

### 2. Configure Environment Variables
Copy `.env.example` to `.env` in the root directory:
```bash
cp .env.example .env
```
Update `.env` with your API keys:
```env
PLANTNET_API_KEY=YOUR_PLANTNET_API_KEY
PLANTNET_API_URL=https://my-api.plantnet.org/v2/identify/all
PLANTID_API_KEY=YOUR_PLANTID_API_KEY
PLANTID_API_URL=https://api.plant.id/v3/identification
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run Analysis & Unit Tests
```bash
flutter analyze
flutter test
```

### 5. Launch Application
```bash
flutter run
```

---

## 📄 License
This project is open-source and available under the [MIT License](LICENSE).

---

<div align="center">
  <sub>Built with ❤️ for plant lovers and agricultural tech worldwide.</sub>
</div>
