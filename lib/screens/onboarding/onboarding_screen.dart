import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../services/onboarding_service.dart';
import '../../widgets/custom_button.dart';

/// Welcome screen for first-time users.
///
/// Matches screenshot: cream background, green circle accent top-left,
/// centered leaf icon, "Plant Care" title, tagline, "Get Started →" button.
///
/// After tapping "Get Started", marks onboarding as seen and explicitly
/// navigates to /login. Does NOT rely on router refreshListenable for this.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Top-left decorative green circle
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.primarySurface.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.paddingLarge,
              ),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.2),
                  // App icon — dark green rounded square with leaf
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.eco,
                      size: 50,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Title
                  Text(
                    'Plant Care',
                    style: AppTextStyles.h1,
                  ),
                  const SizedBox(height: 12),
                  // Tagline
                  Text(
                    AppConstants.appTagline,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 48),
                  // Get Started button
                  CustomButton(
                    text: 'Get Started  →',
                    variant: CustomButtonVariant.outlined,
                    onPressed: () async {
                      // Mark onboarding as seen
                      await context.read<OnboardingService>().markSeen();
                      // Explicit navigation — not relying on refreshListenable
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
