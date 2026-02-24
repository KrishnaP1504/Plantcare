import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Small delay for logo + to give Firebase time
    await Future.delayed(const Duration(seconds: 2));

    // Read the cached Firebase user directly.
    // On Android/iOS this is persisted between app launches.
    final user = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (!mounted) return;

        if (doc.exists) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          Navigator.pushReplacementNamed(
            context,
            '/signup',
            arguments: user.phoneNumber ?? "",
          );
        }
      } catch (e) {
        // If Firestore fails (offline / rules), still let user in.
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      // No saved session – go to welcome/login.
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))
                ]
              ),
              child: const Icon(LucideIcons.leaf, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(color: AppTheme.primary),
            const SizedBox(height: 16),
            const Text("Loading Garden...", style: TextStyle(color: AppTheme.textLight))
          ],
        ),
      ),
    );
  }
}