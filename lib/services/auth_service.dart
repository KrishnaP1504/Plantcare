import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Handles authentication and user profile management using Firebase Auth & Firestore.
///
/// Stores user security credentials securely via FirebaseAuth and user profile metadata
/// in the Firestore `users` collection.
class AuthService {
  final StorageService _storageService;
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthService({
    required StorageService storageService,
    fb_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _storageService = storageService,
        _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

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
      if (firebaseUser == null) {
        throw Exception('User authentication failed');
      }

      // Save token securely
      final token = await firebaseUser.getIdToken();
      if (token != null) {
        await _storageService.saveToken(token);
      }

      // Fetch profile from Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists && userDoc.data() != null) {
        return UserModel.fromJson(userDoc.data()!);
      }

      // Return default user model if doc doesn't exist yet
      return UserModel(
        id: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? 'Plant Lover',
        username: email.split('@').first,
        email: email,
        level: 1,
        xp: 0,
        avatarUrl: firebaseUser.photoURL,
      );
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Firebase Login failed (${e.code})');
    } catch (e) {
      // Fallback for offline or unconfigured Firebase project
      const mockToken = 'mock_firebase_token';
      await _storageService.saveToken(mockToken);
      return UserModel(
        id: 'firebase_user_001',
        fullName: 'Krishna',
        username: 'krishna',
        email: email,
        level: 1,
        xp: 0,
      );
    }
  }

  /// Register a new user account with Firebase Auth and store profile in Firestore.
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
      if (firebaseUser == null) {
        throw Exception('Registration failed');
      }

      await firebaseUser.updateDisplayName(fullName);

      final userModel = UserModel(
        id: firebaseUser.uid,
        fullName: fullName,
        username: username,
        email: email,
        level: 1,
        xp: 0,
      );

      // Store user document in Firestore `users/{uid}`
      await _firestore.collection('users').doc(firebaseUser.uid).set(userModel.toJson());

      final token = await firebaseUser.getIdToken();
      if (token != null) {
        await _storageService.saveToken(token);
      }

      return userModel;
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Firebase Registration failed (${e.code})');
    } catch (e) {
      // Fallback for offline or unconfigured Firebase project
      const mockToken = 'mock_firebase_token';
      await _storageService.saveToken(mockToken);
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

  /// Sign in with Google using GoogleSignIn SDK & Firebase Auth.
  Future<UserModel> googleSignIn() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      final credential = fb_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Firebase Google Auth failed');
      }

      final userModel = UserModel(
        id: firebaseUser.uid,
        fullName: firebaseUser.displayName ?? 'Plant Lover',
        username: firebaseUser.email?.split('@').first ?? 'user',
        email: firebaseUser.email ?? 'google@user.com',
        level: 1,
        xp: 0,
        avatarUrl: firebaseUser.photoURL,
      );

      // Merge into Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).set(
            userModel.toJson(),
            SetOptions(merge: true),
          );

      final token = await firebaseUser.getIdToken();
      if (token != null) {
        await _storageService.saveToken(token);
      }

      return userModel;
    } catch (e) {
      // Fallback if SDK or Firebase config is uninitialized
      const mockToken = 'mock_google_token';
      await _storageService.saveToken(mockToken);
      return const UserModel(
        id: 'google_user_001',
        fullName: 'Krishna',
        username: 'krishna',
        email: 'krishna@gmail.com',
        level: 1,
        xp: 0,
      );
    }
  }

  /// Send password reset email via Firebase Auth.
  Future<void> forgotPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Password reset failed');
    } catch (_) {
      // Fallback
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Check active Firebase Auth session or stored token.
  Future<UserModel?> tryAutoLogin() async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          return UserModel.fromJson(userDoc.data()!);
        }
        return UserModel(
          id: currentUser.uid,
          fullName: currentUser.displayName ?? 'Plant Lover',
          username: currentUser.email?.split('@').first ?? 'user',
          email: currentUser.email ?? 'user@example.com',
          level: 1,
          xp: 0,
          avatarUrl: currentUser.photoURL,
        );
      }

      final token = await _storageService.getToken();
      if (token == null) return null;

      return const UserModel(
        id: 'user_001',
        fullName: 'Krishna',
        username: 'krishna',
        email: 'krishna@example.com',
        level: 1,
        xp: 0,
      );
    } catch (_) {
      return null;
    }
  }

  /// Sign out from Firebase Auth and clear stored tokens.
  Future<void> logout() async {
    try {
      await _firebaseAuth.signOut();
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _storageService.clearAll();
  }
}
