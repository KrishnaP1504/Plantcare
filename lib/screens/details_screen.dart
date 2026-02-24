import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';

class DetailsScreen extends StatefulWidget {
  final Map<String, dynamic> plantData;
  const DetailsScreen({super.key, required this.plantData});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool _isAdding = false;

  void _addToGarden() async {
    setState(() => _isAdding = true);
    final user = FirebaseAuth.instance.currentUser;
    
    if (user != null) {
      try {
        final plantData = widget.plantData;
        plantData['timestamp'] = FieldValue.serverTimestamp();
        // Default frequency if missing
        plantData['waterFrequency'] = plantData['waterFrequency'] ?? 7; 
        
        // Calculate next water date (Today + Frequency)
        final now = DateTime.now();
        final nextWater = now.add(Duration(days: plantData['waterFrequency']));
        plantData['nextWaterDate'] = Timestamp.fromDate(nextWater);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('my_plants')
            .add(plantData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Plant added to garden!")));
          Navigator.pop(context); // Go back
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
    if (mounted) setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final plant = widget.plantData;
    final String image = plant['image'] ?? '';

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Image Header
          Positioned(
            top: 0, left: 0, right: 0,
            height: 350,
            child: image.isNotEmpty 
              ? CachedNetworkImage(
                  imageUrl: image, 
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.grey.shade200),
                  errorWidget: (c, u, e) => Container(color: Colors.grey.shade200, child: const Icon(LucideIcons.image)),
                )
              : Container(color: Colors.green.shade100, child: const Icon(LucideIcons.leaf, size: 64, color: Colors.green)),
          ),
          
          // Back Button
          Positioned(
            top: 50, left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Content Sheet
          Positioned.fill(
            top: 320,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32))
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(plant['name'] ?? 'Unknown Plant', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                            Text(plant['scientific_name'] ?? 'Species', style: const TextStyle(fontSize: 14, color: Colors.grey, fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                        child: Text(plant['difficulty'] ?? 'Easy', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Stats Grid
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat(LucideIcons.droplets, "Water", "Every ${plant['waterFrequency'] ?? 7} days", Colors.blue),
                      _buildStat(LucideIcons.sun, "Light", plant['light'] ?? 'Indirect', Colors.orange),
                      _buildStat(LucideIcons.thermometer, "Temp", plant['temp'] ?? '18-24°C', Colors.red),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        plant['description'] ?? "No description available.",
                        style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 16),
                      ),
                    ),
                  ),
                  
                  // FIX: Visible Button Text
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isAdding ? null : _addToGarden,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white, // Ensures Text is White
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      child: _isAdding 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Add to Garden", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStat(IconData icon, String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)]
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}