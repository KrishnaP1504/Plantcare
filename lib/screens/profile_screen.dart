import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  // FIX: Robust Avatar Builder with Online Fallback
  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (photoUrl.startsWith('data:image')) {
        try {
           final base64Data = photoUrl.split(',')[1];
           return Image.memory(base64Decode(base64Data), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
        } catch (e) {
           // Fallback to online image
           return Image.network("https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200", fit: BoxFit.cover);
        }
      }
      return CachedNetworkImage(
        imageUrl: photoUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorWidget: (context, url, error) => const Icon(LucideIcons.user, color: AppTheme.primary),
      );
    }
    return const Icon(LucideIcons.user, size: 40, color: AppTheme.primary);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(40), bottomRight: Radius.circular(40))
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text("My Profile", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 40) // Balance
                  ],
                ),
                const SizedBox(height: 24),
                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.exists) {
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      return Row(
                        children: [
                          CircleAvatar(
                            radius: 40, 
                            backgroundColor: Colors.white, 
                            child: ClipOval(
                                child: SizedBox(
                                    width: 80, 
                                    height: 80, 
                                    child: _buildAvatar(data['photoUrl'])
                                )
                            )
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['displayName'] ?? "Gardener", 
                                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis, 
                                ),
                                Text(
                                  data['phoneNumber'] ?? "", 
                                  style: TextStyle(color: Colors.green.shade100, fontSize: 14),
                                  overflow: TextOverflow.ellipsis, 
                                ),
                              ],
                            ),
                          )
                        ],
                      );
                    }
                    return const CircularProgressIndicator(color: Colors.white);
                  },
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/account_settings'),
                    child: _buildMenuItem("Account Settings", LucideIcons.user, Colors.blue)
                ),
                GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/notification_settings'),
                    child: _buildMenuItem("Notifications", LucideIcons.bell, Colors.purple)
                ),
                _buildMenuItem("Privacy Policy", LucideIcons.shield, Colors.orange),
                _buildMenuItem("Help & Support", LucideIcons.helpCircle, Colors.teal),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: _signOut,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: const Row(
                      children: [
                        CircleAvatar(radius: 20, backgroundColor: Colors.redAccent, child: Icon(LucideIcons.logOut, color: Colors.white, size: 20)),
                        SizedBox(width: 16),
                        Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          CircleAvatar(radius: 20, backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          const Icon(LucideIcons.chevronRight, color: Colors.grey)
        ],
      ),
    );
  }
}