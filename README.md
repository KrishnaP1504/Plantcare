# 🌱 Plant Care App - AI-Powered Botanist

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Gemini
AI](https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=googlebard&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

An intelligent cross-platform Flutter application that helps users
manage indoor and outdoor plants using AI-powered plant identification
and disease detection.

------------------------------------------------------------------------

## 📥 Download App

[Download APK](https://github.com/KrishnaP1504/Plantcare/releases/)

> Enable "Install from Unknown Sources" in Android settings before
> installing.

------------------------------------------------------------------------

## ✨ Key Features

-   🤖 AI Plant Scanner (Gemini AI integration)
-   📱 Firebase Phone Authentication (OTP-based login)
-   🪴 My Garden Tracking with smart watering schedule
-   📅 Care Calendar with daily task tracking
-   🏆 Gamification with XP & leveling system
-   🔍 Global Smart Plant Search
-   📖 Expert Plant Care Guide
-   ☁️ Real-time Cloud Sync (Firestore)

------------------------------------------------------------------------

## 🛠️ Technology Stack

-   Frontend: Flutter (Dart)
-   Backend: Firebase Firestore
-   Authentication: Firebase Phone Auth
-   AI Integration: Gemini API (gemini-1.5-flash)
-   Key Packages: image_picker, http, cached_network_image

------------------------------------------------------------------------

## 🚀 How to Run Locally

### 1. Clone Repository

``` bash
git clone https://github.com/YOUR_USERNAME/plant_care_app1.git
cd plant_care_app1
```

### 2. Install Dependencies

``` bash
flutter pub get
```

### 3. Setup Firebase

-   Create project in Firebase Console
-   Enable Firestore & Phone Authentication
-   Add android app & download google-services.json
-   Place it inside android/app/

### 4. Add Gemini API Key

Open: lib/services/gemini_service.dart

Replace: static const String \_apiKey = "YOUR_GEMINI_API_KEY_HERE";

### 5. Run App

``` bash
flutter run
```

------------------------------------------------------------------------

## 👨‍💻 Author

Krishnakumar Pipaliya\
Computer Engineering Student

------------------------------------------------------------------------

## 📝 License

Licensed under the MIT License.

