import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/navigation_provider.dart';
import '../../widgets/custom_bottom_nav_bar.dart';

/// Dashboard shell screen wrapping child routes with the bottom nav bar.
///
/// Uses GoRouter ShellRoute — the [child] is the currently active tab screen.
/// The bottom nav bar is persistent across all tabs.
class DashboardScreen extends StatelessWidget {
  final Widget child;

  const DashboardScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      extendBody: true,
      bottomNavigationBar: Consumer<NavigationProvider>(
        builder: (context, navProvider, _) {
          return CustomBottomNavBar(
            currentIndex: navProvider.currentIndex,
            onTap: (index) {
              navProvider.setIndex(index);
              switch (index) {
                case 0:
                  context.go('/dashboard/home');
                  break;
                case 1:
                  context.go('/dashboard/garden');
                  break;
                case 2:
                  context.go('/dashboard/schedule');
                  break;
                case 3:
                  context.go('/dashboard/encyclopedia');
                  break;
              }
            },
            onCameraTap: () {
              context.push('/camera');
            },
          );
        },
      ),
    );
  }
}
