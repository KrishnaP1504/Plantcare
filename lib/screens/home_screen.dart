import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../config/theme.dart';
import '../services/gemini_service.dart';
import '../widgets/custom_bottom_nav.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleGlobalSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final result = await GeminiService.searchPlant(query);
      result['image'] = "https://source.unsplash.com/featured/?${Uri.encodeComponent(query)},plant";
      if (mounted) Navigator.pushNamed(context, '/details', arguments: result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Search failed: $e")));
    } finally {
      if (mounted) setState(() => _isSearching = false);
      _searchController.clear();
    }
  }
  
  Widget _buildAvatar(String? photoUrl) {
    if (photoUrl != null && photoUrl.isNotEmpty) {
      try {
        if (photoUrl.startsWith('data:image')) {
             return Image.memory(base64Decode(photoUrl.split(',')[1]), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
        }
        return CachedNetworkImage(
          imageUrl: photoUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
          placeholder: (c, u) => Container(color: Colors.grey.shade200),
          errorWidget: (c, u, e) => const Icon(LucideIcons.user),
        );
      } catch (e) { return const Icon(LucideIcons.user, color: AppTheme.primary); }
    }
    return const Icon(LucideIcons.user, color: AppTheme.primary);
  }

  Widget _buildPlantImage(String? imageStr) {
     if (imageStr != null && imageStr.startsWith('data:image')) {
        try {
           return Image.memory(base64Decode(imageStr.split(',')[1]), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
        } catch(e) { return const Icon(LucideIcons.leaf, color: Colors.green); }
     }
     if (imageStr == null || imageStr.isEmpty) return const Icon(LucideIcons.leaf, color: Colors.green);
     return CachedNetworkImage(
       imageUrl: imageStr, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
       placeholder: (c, u) => Container(color: Colors.grey.shade200),
       errorWidget: (c, u, e) => const Icon(LucideIcons.leaf, color: Colors.green),
     );
  }

  Widget _buildMiniStat(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color.withValues(alpha: 0.3), width: 2)),
          child: Center(child: Icon(icon, size: 14, color: color)),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500)),
      ],
    );
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
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                        builder: (context, snapshot) {
                          // ERROR HANDLING FOR PROFILE
                          if (snapshot.hasError) {
                             return Text("Error loading profile: ${snapshot.error}", style: const TextStyle(color: Colors.red));
                          }

                          String displayName = "Gardener";
                          String? photoUrl;
                          int xp = 0;
                          
                          if (snapshot.hasData && snapshot.data!.exists) {
                            final data = snapshot.data!.data() as Map<String, dynamic>;
                            displayName = data['displayName'] ?? "Gardener";
                            photoUrl = data['photoUrl'];
                            xp = data['xp'] ?? 0;
                          }
                          
                          final int level = (xp / 100).floor() + 1;
                          final String levelTitle = level == 1 ? "Novice" : (level < 5 ? "Green Thumb" : "Plant Whisperer");

                          return Row(
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: const Color(0xFFC8E6C9),
                                child: ClipOval(child: SizedBox(width: 52, height: 52, child: _buildAvatar(photoUrl)))
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Hello, $displayName", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 2),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      children: [
                                        const Icon(LucideIcons.crown, size: 12, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text("Lvl $level • $levelTitle", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white, borderRadius: BorderRadius.circular(16), 
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]
                      ),
                      child: TextField(
                        controller: _searchController,
                        onSubmitted: _handleGlobalSearch,
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          icon: _isSearching ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(LucideIcons.search, color: Colors.grey),
                          hintText: "Search for plants...",
                          border: InputBorder.none,
                          suffixIcon: IconButton(icon: const Icon(LucideIcons.arrowRight), onPressed: () => _handleGlobalSearch(_searchController.text))
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    Container(
                      height: 180,
                      decoration: BoxDecoration(color: const Color(0xFFD6E8D8), borderRadius: BorderRadius.circular(24)),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 24, left: 24,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Succulent", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1B4B27))),
                                const SizedBox(height: 4),
                                const Text("12 days ago planted", style: TextStyle(color: Color(0xFF3E6847))),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(12)),
                                  child: const Row(children: [Icon(LucideIcons.thermometer, size: 16, color: AppTheme.primary), SizedBox(width: 4), Text("24°C", style: TextStyle(fontWeight: FontWeight.bold))]),
                                )
                              ],
                            ),
                          ),
                          Positioned(right: -20, bottom: -20, child: CircleAvatar(radius: 60, backgroundColor: Colors.green.shade300))
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("My Garden", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        GestureDetector(onTap: () => Navigator.pushReplacementNamed(context, '/my_plants'), child: const Text("View All", style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ]),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('my_plants').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  // ERROR HANDLING FOR GARDEN
                  if (snapshot.hasError) {
                    return SliverToBoxAdapter(
                      child: Center(child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)))
                    );
                  }
                  
                  if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                  
                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) return SliverToBoxAdapter(child: Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: const Center(child: Text("No plants yet."))));

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          return GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/details', arguments: data),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10)]),
                              child: Row(
                                children: [
                                  Container(width: 80, height: 80, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: _buildPlantImage(data['image']))),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data['name'] ?? 'Plant', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text(data['scientific_name'] ?? 'Species', style: const TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                                        const SizedBox(height: 12),
                                        Row(children: [_buildMiniStat(LucideIcons.sun, "Light", Colors.orange), const SizedBox(width: 20), _buildMiniStat(LucideIcons.droplets, "Water", Colors.blue), const SizedBox(width: 20), _buildMiniStat(LucideIcons.smile, "Happy", Colors.green)])
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: docs.length,
                      ),
                    ),
                  );
                },
              ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          ),
          const CustomBottomNav(active: 0),
        ],
      ),
    );
  }
}