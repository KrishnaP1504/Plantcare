import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../config/theme.dart';
import '../widgets/custom_bottom_nav.dart';

class MyPlantsScreen extends StatelessWidget {
  const MyPlantsScreen({super.key});

  void _deletePlant(String plantId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('my_plants')
          .doc(plantId)
          .delete();
    }
  }

  Widget _buildPlantImage(String? imageStr) {
    if (imageStr == null || imageStr.isEmpty) {
      return const Center(child: Icon(LucideIcons.sprout, color: Colors.green, size: 40));
    }
    try {
      if (imageStr.startsWith('data:image')) {
        final base64Data = imageStr.split(',')[1];
        return Image.memory(base64Decode(base64Data), fit: BoxFit.cover, width: double.infinity);
      }
      return CachedNetworkImage(
        imageUrl: imageStr,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (context, url) => Container(color: Colors.grey.shade100),
        errorWidget: (context, url, error) => const Center(child: Icon(LucideIcons.image, color: Colors.grey)),
      );
    } catch (e) {
      return const Center(child: Icon(LucideIcons.alertTriangle, color: Colors.red, size: 40));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        const Text("My Plants", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                        const SizedBox(width: 12),
                        StreamBuilder<QuerySnapshot>(
                           stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('my_plants').snapshots(),
                           builder: (context, snapshot) {
                             final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                             return Container(
                               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                               decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(12)),
                               child: Text("$count", style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary)),
                             );
                           }
                        )
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('my_plants').orderBy('timestamp', descending: true).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs;
                        
                        if (docs.isEmpty) {
                          return const Center(child: Text("No plants yet."));
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.8,
                          ),
                          itemCount: docs.length,
                          itemBuilder: (context, index) {
                            final docSnap = docs[index];
                            final data = docSnap.data() as Map<String, dynamic>;
                            return GestureDetector(
                              onTap: () => Navigator.pushNamed(context, '/details', arguments: data),
                              child: Stack(
                                children: [
                                  // Card Background
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Image Area
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade100,
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: _buildPlantImage(data['image'])
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(data['name'] ?? 'Plant', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text(data['scientific_name'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  // Delete Button
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: GestureDetector(
                                      onTap: () => _deletePlant(docSnap.id),
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]
                                        ),
                                        child: const Icon(LucideIcons.trash2, size: 18, color: Colors.redAccent),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
          const CustomBottomNav(active: 1),
        ],
      ),
    );
  }
}