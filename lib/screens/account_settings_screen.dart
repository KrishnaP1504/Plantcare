import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/theme.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  // Use map for profile data
  Map<String, dynamic> _userData = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _userData = doc.data() ?? {};
          _isLoading = false;
        });
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/welcome', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    // Determine level
    final int xp = _userData['xp'] ?? 0;
    final int level = (xp / 100).floor() + 1;
    final int nextLevelXp = level * 100;
    final double progress = (xp % 100) / 100;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            child: Column(
              children: [
                // 1. Profile Header
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(LucideIcons.arrowLeft), onPressed: () => Navigator.pop(context)),
                          const Text("My Profile", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(LucideIcons.logOut, color: Colors.red), onPressed: _logout),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Avatar
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                        child: const Icon(LucideIcons.user, size: 50, color: AppTheme.primary),
                      ),
                      const SizedBox(height: 16),
                      
                      // Name & Stats
                      Text(_userData['displayName'] ?? 'Gardener', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Text("@${_userData['username'] ?? 'username'}", style: const TextStyle(color: Colors.grey)),
                      
                      const SizedBox(height: 24),
                      
                      // XP Bar
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.background,
                          borderRadius: BorderRadius.circular(16)
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primary,
                              radius: 20,
                              child: Text("$level", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text("Level $level", style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text("$xp / $nextLevelXp XP", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey.shade300,
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 2. Settings Menu
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildMenuItem(LucideIcons.bell, "Notifications", () => Navigator.pushNamed(context, '/notifications')),
                      _buildMenuItem(LucideIcons.settings, "Account Settings", () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Edit Profile feature coming soon!")));
                      }),
                      _buildMenuItem(LucideIcons.helpCircle, "Help & Support", () {}),
                      _buildMenuItem(LucideIcons.lock, "Privacy Policy", () {}),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)]
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.textDark),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16))),
            const Icon(LucideIcons.chevronRight, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}