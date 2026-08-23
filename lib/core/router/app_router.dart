import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/auth/forgot_password_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/garden/garden_screen.dart';
import '../../screens/schedule/schedule_screen.dart';
import '../../screens/encyclopedia/encyclopedia_screen.dart';
import '../../screens/camera/camera_screen.dart';
import '../../screens/scan_result/scan_result_screen.dart';
import '../../screens/plant_detail/plant_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/account_settings_screen.dart';
import '../../services/onboarding_service.dart';
import '../../services/scan_service.dart';

/// GoRouter configuration with auth & onboarding redirect guard.
class AppRouter {
  final AuthProvider authProvider;

  AppRouter({required this.authProvider});

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: authProvider,
    redirect: _redirect,
    routes: [
      // ── Splash ──
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ──
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth ──
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── Dashboard (Shell) ──
      ShellRoute(
        builder: (context, state, child) => DashboardScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard/garden',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: GardenScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard/schedule',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScheduleScreen(),
            ),
          ),
          GoRoute(
            path: '/dashboard/encyclopedia',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: EncyclopediaScreen(),
            ),
          ),
        ],
      ),

      // ── Camera (full-screen, no nav bar) ──
      GoRoute(
        path: '/camera',
        builder: (context, state) {
          final modeParam = state.uri.queryParameters['mode'];
          final plantId = state.uri.queryParameters['plantId'];
          final mode = modeParam == 'diagnose'
              ? ScanMode.diagnose
              : ScanMode.identify;
          return CameraScreen(scanMode: mode, plantId: plantId);
        },
      ),

      // ── Scan Result ──
      GoRoute(
        path: '/scan-result',
        builder: (context, state) => const ScanResultScreen(),
      ),

      // ── Plant Detail ──
      GoRoute(
        path: '/plant/:id',
        builder: (context, state) {
          final plantId = state.pathParameters['id']!;
          final isGlobal = state.uri.queryParameters['isGlobal'] == 'true';
          return PlantDetailScreen(
            plantId: plantId,
            isGlobalSearch: isGlobal,
          );
        },
      ),

      // ── Profile & Account Settings ──
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/account-settings',
        builder: (context, state) => const AccountSettingsScreen(),
      ),
    ],
  );

  /// Auth & onboarding redirect guard.
  String? _redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = authProvider.isAuthenticated;
    final isInitializing = authProvider.isInitializing;
    final location = state.matchedLocation;

    final isOnAuthRoute = location.startsWith('/login') ||
        location.startsWith('/register') ||
        location.startsWith('/forgot-password');
    final isSplash = location == '/splash';
    final isOnboarding = location == '/onboarding';

    // Still initializing — stay on splash
    if (isInitializing && isSplash) return null;

    final onboardingService = context.read<OnboardingService>();
    final hasSeenOnboarding = onboardingService.hasSeenOnboarding;

    // Handle splash exit once initialization finishes
    if (isSplash) {
      if (!hasSeenOnboarding) return '/onboarding';
      return isLoggedIn ? '/dashboard/home' : '/login';
    }

    // First launch — force onboarding if not seen
    if (!hasSeenOnboarding && !isOnboarding) {
      return '/onboarding';
    }

    // Not logged in and not on auth/onboarding route — redirect to login
    if (!isLoggedIn && !isOnAuthRoute && !isOnboarding) {
      return '/login';
    }

    // Logged in but on auth/onboarding route — redirect to dashboard
    if (isLoggedIn && (isOnAuthRoute || isOnboarding)) {
      return '/dashboard/home';
    }

    return null; // no redirect
  }
}
