import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../providers/auth_provider.dart';
import '../../services/onboarding_service.dart';

/// Splash screen shown on cold start.
///
/// Calls [AuthProvider.tryAutoLogin] with an 8-second timeout.
/// GoRouter redirect guard handles navigation after initialization completes.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    final onboardingService = context.read<OnboardingService>();

    // Wait for auth to try auto-login (has built-in timeout)
    await authProvider.tryAutoLogin();

    if (!mounted) return;

    // Navigate explicitly based on state
    if (!onboardingService.hasSeenOnboarding) {
      context.go('/onboarding');
    } else if (authProvider.isAuthenticated) {
      context.go('/dashboard/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.eco,
                size: 40,
                color: AppColors.textOnPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Text('Plantcare', style: AppTextStyles.h2),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
