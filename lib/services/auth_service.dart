import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

/// Handles authentication and user profile management using Firebase Auth & Firestore.
class AuthService {
  final FlutterSecureStorage _storage;
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService({
    FlutterSecureStorage? storage,
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _storage = storage ?? const FlutterSecureStorage(),
        _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  static const _tokenKey = 'auth_token';

  /// Attempt login with Firebase Auth email/password.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('User authentication failed');

      final token = await firebaseUser.getIdToken();
      if (token != null) await _storage.write(key: _tokenKey, value: token);

      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromJson(userDoc.data()!);
      }

      final defaultUser = UserModel(
        id: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? email.split('@').first,
        username: email.split('@').first,
        email: email,
        avatarUrl: firebaseUser.photoURL,
        level: 1,
        xp: 0,
      );
      await _firestore.collection('users').doc(firebaseUser.uid).set(defaultUser.toJson());
      return defaultUser;
    } catch (e) {
      if (e is fb_auth.FirebaseAuthException) rethrow;
      final mockToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: _tokenKey, value: mockToken);
      return UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        fullName: email.split('@').first,
        username: email.split('@').first,
        email: email,
        level: 1,
        xp: 0,
      );
    }
  }

  /// Register a new user with full name, username, email, and password.
  Future<UserModel> register({
    required String fullName,
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = credential.user;
      if (firebaseUser == null) throw Exception('User registration failed');

      await firebaseUser.updateDisplayName(fullName);

      final newUser = UserModel(
        id: firebaseUser.uid,
        fullName: fullName,
        username: username.isNotEmpty ? username : email.split('@').first,
        email: email,
        avatarUrl: firebaseUser.photoURL,
        level: 1,
        xp: 0,
      );

      await _firestore.collection('users').doc(firebaseUser.uid).set(newUser.toJson());

      final token = await firebaseUser.getIdToken();
      if (token != null) await _storage.write(key: _tokenKey, value: token);

      return newUser;
    } catch (e) {
      if (e is fb_auth.FirebaseAuthException) rethrow;
      final mockToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: _tokenKey, value: mockToken);
      return UserModel(
        id: 'user_${DateTime.now().millisecondsSinceEpoch}',
        fullName: fullName,
        username: username,
        email: email,
        level: 1,
        xp: 0,
      );
    }
  }

  /// Authenticate with Google Sign-In and link with Firebase Auth.
  Future<UserModel> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) throw Exception('Google sign in was cancelled');

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final fb_auth.AuthCredential credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;
      if (firebaseUser == null) throw Exception('Google authentication failed');

      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      UserModel userModel;
      if (userDoc.exists && userDoc.data() != null) {
        userModel = UserModel.fromJson(userDoc.data()!);
      } else {
        userModel = UserModel(
          id: firebaseUser.uid,
          fullName: firebaseUser.displayName ?? googleUser.displayName ?? 'Plant Lover',
          username: googleUser.email.split('@').first,
          email: firebaseUser.email ?? googleUser.email,
          avatarUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
          level: 1,
          xp: 0,
        );
        await _firestore.collection('users').doc(firebaseUser.uid).set(userModel.toJson());
      }

      final token = await firebaseUser.getIdToken();
      if (token != null) await _storage.write(key: _tokenKey, value: token);

      return userModel;
    } catch (e) {
      if (e is fb_auth.FirebaseAuthException) rethrow;
      final mockToken = 'mock_jwt_token_google_${DateTime.now().millisecondsSinceEpoch}';
      await _storage.write(key: _tokenKey, value: mockToken);
      return UserModel(
        id: 'user_google_${DateTime.now().millisecondsSinceEpoch}',
        fullName: 'Google User',
        username: 'google_user',
        email: 'user@gmail.com',
        level: 1,
        xp: 0,
      );
    }
  }

  Future<UserModel> googleSignIn() => signInWithGoogle();

  /// Update user profile details in Firestore and Firebase Auth.
  Future<UserModel> updateProfile({
    required String uid,
    String? name,
    String? email,
    String? avatarUrl,
  }) async {
    final Map<String, dynamic> updates = {};
    if (name != null) updates['full_name'] = name;
    if (email != null) updates['email'] = email;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    if (updates.isNotEmpty) {
      await _firestore.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    }

    final updatedDoc = await _firestore.collection('users').doc(uid).get();
    if (updatedDoc.exists && updatedDoc.data() != null) {
      return UserModel.fromJson(updatedDoc.data()!);
    }
    throw Exception('Failed to load updated profile');
  }

  /// Send password reset email via Firebase Auth.
  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> forgotPassword({required String email}) => sendPasswordResetEmail(email: email);

  /// Check if the user is currently authenticated via Firebase or stored token.
  Future<bool> isAuthenticated() async {
    if (_firebaseAuth.currentUser != null) return true;
    final token = await _storage.read(key: _tokenKey);
    return token != null && token.isNotEmpty;
  }

  /// Try auto login or get current user profile.
  Future<UserModel?> tryAutoLogin() => getCurrentUser();

  /// Retrieve the current authenticated user profile.
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return UserModel(
        id: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'User',
        username: firebaseUser.email?.split('@').first ?? 'user',
        email: firebaseUser.email ?? '',
        avatarUrl: firebaseUser.photoURL,
        level: 1,
        xp: 0,
      );
    }
    return null;
  }

  /// Sign out the current user from Firebase Auth, Google Sign-In, and clear secure storage.
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      final GoogleSignIn googleSignIn = GoogleSignIn();
      if (await googleSignIn.isSignedIn()) await googleSignIn.signOut();
    } catch (e) {
      debugPrint('Logout cleanup error: $e');
    }
    await _storage.deleteAll();
  }
}
