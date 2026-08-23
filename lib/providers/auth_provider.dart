import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../core/constants/app_constants.dart';

/// Auth state management provider.
///
/// Delegates all I/O to [AuthService]. Exposes loading, error, and
/// authenticated states for the UI and GoRouter redirect guard.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthProvider({required AuthService authService}) : _authService = authService;

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitializing = true;
  String? _error;

  // ── Getters ──

  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  String? get error => _error;

  // ── Auth Actions ──

  /// Try to restore session from stored token on cold start.
  /// Has a timeout to prevent indefinite splash screen.
  Future<void> tryAutoLogin() async {
    _isInitializing = true;
    notifyListeners();

    try {
      _currentUser = await _authService
          .tryAutoLogin()
          .timeout(AppConstants.splashTimeout);
    } on TimeoutException {
      // Network dead or token validation hung — fall through to login
      _currentUser = null;
    } catch (e) {
      _currentUser = null;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  /// Force unauthenticated state (e.g., on splash timeout).
  void forceUnauthenticated() {
    _currentUser = null;
    _isInitializing = false;
    notifyListeners();
  }

  /// Login with email and password.
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.login(
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Register a new account.
  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.register(
        fullName: fullName,
        username: username,
        email: email,
        password: password,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Google.
  Future<bool> googleSignIn() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authService.googleSignIn();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Send password reset email.
  Future<bool> forgotPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.forgotPassword(email: email);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout and clear stored tokens.
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  /// Update current user profile fields (name, username, email, avatar).
  void updateProfile({
    String? fullName,
    String? username,
    String? email,
    String? avatarUrl,
  }) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        fullName: fullName ?? _currentUser!.fullName,
        username: username ?? _currentUser!.username,
        email: email ?? _currentUser!.email,
        avatarUrl: avatarUrl ?? _currentUser!.avatarUrl,
      );
      notifyListeners();
    }
  }

  /// Clear any displayed error.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
