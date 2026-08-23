import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';

/// Manages onboarding-seen state via shared_preferences.
///
/// This is a non-sensitive boolean flag — safe for shared_preferences.
/// Sensitive data (tokens) must use StorageService (flutter_secure_storage).
class OnboardingService {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get hasSeenOnboarding {
    return _prefs?.getBool(AppConstants.hasSeenOnboardingKey) ?? false;
  }

  Future<void> markSeen() async {
    await _prefs?.setBool(AppConstants.hasSeenOnboardingKey, true);
  }

  /// For testing/debug: reset onboarding state.
  Future<void> reset() async {
    await _prefs?.remove(AppConstants.hasSeenOnboardingKey);
  }
}
