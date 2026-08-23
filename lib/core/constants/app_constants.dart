/// Non-secret application constants.
///
/// API keys must NEVER be stored here or anywhere in the client binary.
/// Route API calls through your backend proxy. See security section in the
/// implementation plan.
class AppConstants {
  AppConstants._();

  // ── App Info ──
  static const String appName = 'Plantcare';
  static const String appTagline = 'Your AI-powered botanist for a thriving garden.';

  // ── API Base URLs (non-secret) ──
  /// Base URL for the backend proxy that holds the real API keys server-side.
  static const String apiBaseUrl = 'https://api.yourbackend.com/v1';

  // ── API Key Placeholders ──
  // TODO(security): Route plant identification API calls through your own
  // backend endpoint (e.g., POST /api/v1/scan). The real
  // PLANT_IDENTIFICATION_API_KEY must live server-side only.
  // Any value in Dart source or --dart-define is extractable from APK/IPA.

  // Google OAuth client ID is public-facing by design in OAuth flows.
  // The secret stays server-side. Restrict this ID by package name + SHA
  // fingerprint in Google Cloud Console.
  static const String googleAuthClientId = '[GOOGLE_AUTH_CLIENT_ID]';

  // ── Timeouts ──
  static const Duration splashTimeout = Duration(seconds: 8);
  static const Duration apiTimeout = Duration(seconds: 30);

  // ── Dimensions ──
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  static const double borderRadiusPill = 50.0;

  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  static const double iconSizeSmall = 20.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;

  static const double bottomNavBarHeight = 72.0;
  static const double fabSize = 56.0;

  // ── Storage Keys ──
  static const String hasSeenOnboardingKey = 'has_seen_onboarding';
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';

  // ── Gamification ──
  static const int xpPerLevel = 100;

  // TODO(security): When adding Firebase/Supabase, configure per-user
  // Firestore security rules and Storage bucket rules BEFORE any
  // real user data touches production. Never ship with default/open rules.
}
