import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';

/// Wrapper around flutter_secure_storage for auth tokens.
///
/// Uses Keychain on iOS and Keystore on Android — encrypted at rest.
/// NEVER use shared_preferences for tokens; it's plaintext on disk.
class StorageService {
  final FlutterSecureStorage _storage;

  StorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  // ── Auth Token ──

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.authTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.authTokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: AppConstants.authTokenKey);
  }

  // ── Refresh Token ──

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: AppConstants.refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: AppConstants.refreshTokenKey);
  }

  Future<void> deleteRefreshToken() async {
    await _storage.delete(key: AppConstants.refreshTokenKey);
  }

  // ── Clear All ──

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
