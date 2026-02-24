import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import '../config/theme.dart';
import '../widgets/custom_bottom_nav.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final Set<String> _processingTasks = {}; 

  void _completeTask(String taskId, String plantId, String plantName, int frequency) async {
    if (_processingTasks.contains(taskId)) return;

    setState(() => _processingTasks.add(taskId));
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final batch = FirebaseFirestore.instance.batch();
      final plantRef = FirebaseFirestore.instance.collection('users').doc(user.uid).collection('my_plants').doc(plantId);
      
      // Calculate Next Water Date (Reschedule)
      final DateTime newDate = DateTime.now().add(Duration(days: frequency));

      batch.update(plantRef, {
        'lastWatered': FieldValue.serverTimestamp(),
        'nextWaterDate': Timestamp.fromDate(newDate), // Move task to future
      });

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'xp': FieldValue.increment(10),
      });

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.trophy, color: Colors.yellow, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text("Watered $plantName! Next: ${newDate.day}/${newDate.month}")),
              ],
            ),
            backgroundColor: AppTheme.primary,
            behavior: SnackBarBehavior.floating,
          )
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _processingTasks.remove(taskId));
    }
  }

  String _formatTaskDate(dynamic timestamp) {
    if (timestamp == null) return "Upcoming";
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
      return "Water on ${date.day} ${months[date.month - 1]}";
    }
    return "Upcoming";
  }

  Widget _buildPlantImage(String? imageStr) {
    if (imageStr == null || imageStr.isEmpty) {
      return const Icon(LucideIcons.sprout, color: Colors.green, size: 24);
    }
    try {
      if (imageStr.startsWith('data:image')) {
        final base64Data = imageStr.split(',')[1];
        return Image.memory(base64Decode(base64Data), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      }
      return CachedNetworkImage(
        imageUrl: imageStr,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(color: Colors.grey.shade100),
        errorWidget: (context, url, error) => const Icon(LucideIcons.image, color: Colors.grey),
      );
    } catch (e) {
      return const Icon(LucideIcons.leaf, color: Colors.green, size: 24);
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
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                      builder: (context, snapshot) {
                        String name = "Gardener";
                        int xp = 0;
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          name = data['displayName'] ?? "Gardener";
                          xp = data['xp'] ?? 0;
                        }
                        
                        final int level = (xp / 100).floor() + 1;
                        final int nextLevelXp = level * 100; 
                        final double progress = (xp % 100) / 100;

                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF4CAF50)]),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))]
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.white24,
                                child: Text("$level", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Hello, $name!", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text("$xp XP", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                        Text("Goal: $nextLevelXp XP", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.black12,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        minHeight: 6,
                                      ),
                                    )
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    const Text("Tasks Due", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 16),
                    
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).collection('my_plants').orderBy('nextWaterDate').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                        final docs = snapshot.data!.docs;

                        if (docs.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text("No plants need care right now.")),
                          );
                        }

                        return Column(
                          children: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final plantId = doc.id;
                            final plantName = data['name'] ?? 'Plant';
                            final dateString = _formatTaskDate(data['nextWaterDate']);
                            final int frequency = data['waterFrequency'] ?? 7;
                            final taskId = "water_$plantId"; 
                            
                            // Check if task is scheduled for TODAY
                            bool isToday = false;
                            if (data['nextWaterDate'] != null && data['nextWaterDate'] is Timestamp) {
                              final date = (data['nextWaterDate'] as Timestamp).toDate();
                              final now = DateTime.now();
                              isToday = date.year == now.year && date.month == now.month && date.day == now.day;
                            }

                            final bool isProcessing = _processingTasks.contains(taskId);

                            return _buildTaskCard(
                              plantName: plantName,
                              amount: dateString,
                              image: data['image'],
                              isProcessing: isProcessing,
                              isToday: isToday, // Pass the status
                              onTap: () {
                                if (isToday) {
                                  _completeTask(taskId, plantId, plantName, frequency);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("You can only complete this task on the scheduled day!"),
                                      duration: Duration(seconds: 1),
                                    )
                                  );
                                }
                              },
                            );
                          }).toList(),
                        );
                      }
                    ),
                  ]),
                ),
              ),
            ],
          ),
          const CustomBottomNav(active: 2),
        ],
      ),
    );
  }

  Widget _buildTaskCard({
    required String plantName,
    required String amount,
    required String? image,
    required bool isProcessing,
    required bool isToday,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Action Button
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 80,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
                color: Colors.transparent
              ),
              child: Center(
                child: isProcessing
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                  : Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isToday ? AppTheme.primary : Colors.grey.shade300, 
                          width: 2
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isToday ? Colors.white : Colors.grey.shade100,
                      ),
                      child: isToday ? null : const Icon(LucideIcons.lock, size: 14, color: Colors.grey),
                    ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          plantName, 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 16, 
                            color: isToday ? AppTheme.textDark : Colors.grey
                          ), 
                          maxLines: 1
                        ),
                        const SizedBox(height: 4),
                        Text(amount, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                    clipBehavior: Clip.hardEdge,
                    child: _buildPlantImage(image),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}