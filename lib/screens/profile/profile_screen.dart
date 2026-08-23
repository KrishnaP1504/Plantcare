import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';

/// Redesigned Profile Screen matching the exact design screenshot.
///
/// Features:
/// - Top bar with circular back button, "My Profile 🍃" title, and circular logout button
/// - Avatar with framing leaf foliage artwork & edit pencil badge
/// - User name (krishna) and handle (@krishna)
/// - Level 1 XP progress card with leaf sprout badge
/// - "Keep Growing!" motivation card with potted sprout & star badge
/// - 4 white navigation cards (Notifications, Account Settings, Help & Support, Privacy Policy)
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    final displayName = user?.fullName ?? user?.username ?? 'krishna';
    final handle = user?.username ?? 'krishna';

    return Scaffold(
      backgroundColor: const Color(0xFFFAFBF8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            children: [
              // ── 1. Top Bar ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        size: 28,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),

                  // Title: My Profile 🍃
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'My Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1C3B30),
                        ),
                      ),
                      SizedBox(width: 6),
                      Text('🍃', style: TextStyle(fontSize: 18)),
                    ],
                  ),

                  // Logout Button
                  GestureDetector(
                    onTap: () async {
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        size: 22,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── 2. Avatar & Foliage Framing ──
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Left Foliage Leaf Accent
                  Positioned(
                    left: 20,
                    top: 10,
                    child: Transform.rotate(
                      angle: -0.4,
                      child: const Icon(
                        Icons.eco,
                        size: 36,
                        color: Color(0xFFB5D4BF),
                      ),
                    ),
                  ),

                  // Right Foliage Leaf Accent
                  Positioned(
                    right: 20,
                    top: 10,
                    child: Transform.rotate(
                      angle: 0.4,
                      child: const Icon(
                        Icons.eco,
                        size: 36,
                        color: Color(0xFFB5D4BF),
                      ),
                    ),
                  ),

                  // Main Avatar Circle with Edit Pencil Badge
                  Stack(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F3EB),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 48,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C553C),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Name & Handle ──
              Text(
                displayName.toLowerCase(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1C3B30),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@$handle',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6A7E73),
                ),
              ),

              const SizedBox(height: 28),

              // ── 3. Level 1 XP Progress Card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1B4D3E).withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Level Badge Circle
                    Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            color: Color(0xFF2C553C),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${user?.level ?? 1}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -4,
                          left: -2,
                          child: Transform.rotate(
                            angle: -0.3,
                            child: const Text('🍃', style: TextStyle(fontSize: 14)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Level Info & Progress Bar
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Level ${user?.level ?? 1}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C3B30),
                                ),
                              ),
                              Text(
                                '${user?.xp ?? 0} / ${user?.xpForCurrentLevel ?? 100} XP',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2C553C),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.levelTitle ?? 'Beginner Gardener',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6A7E73),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // XP Progress Indicator Bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: user?.levelProgress ?? 0.0,
                              backgroundColor: const Color(0xFFE8F0EA),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2C553C)),
                              minHeight: 8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── 4. "Keep Growing!" Motivation Card ──
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF4ED),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    // Sprout Icon / Asset
                    const Text('🌱', style: TextStyle(fontSize: 38)),
                    const SizedBox(width: 14),

                    // Title & Description
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keep Growing!',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C3B30),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Complete tasks, earn XP and level up your garden journey.',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF556B60),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // White Star Circle Badge
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        size: 26,
                        color: Color(0xFF90B59E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── 5. Navigation Menu List Cards ──
              // Notifications Card
              _buildMenuCard(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Stay updated with your garden',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notifications are up to date!'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Account Settings Card
              _buildMenuCard(
                icon: Icons.settings_outlined,
                title: 'Account Settings',
                subtitle: 'Manage your account preferences',
                onTap: () {
                  context.push('/account-settings');
                },
              ),

              const SizedBox(height: 12),

              // Help & Support Card
              _buildMenuCard(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'Get help and support',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Contact support@plantcare.com for help'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Privacy Policy Card
              _buildMenuCard(
                icon: Icons.shield_outlined,
                title: 'Privacy Policy',
                subtitle: 'Learn how we protect your data',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy Policy: Your data is secure.'),
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper widget to build menu list item cards matching design screenshot.
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Circular Icon Badge
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEBF5ED),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: const Color(0xFF1B4D3E),
              ),
            ),
            const SizedBox(width: 16),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1C3B30),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6A7E73),
                    ),
                  ),
                ],
              ),
            ),

            // Chevron Arrow Icon
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF1C3B30),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
