import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/plant_model.dart';
import '../../providers/plant_provider.dart';
import '../../providers/scan_provider.dart';

/// Redesigned Scan Result Screen matching the exact design screenshot.
///
/// Features:
/// - Circular back button & top-right leafy branch background artwork
/// - Hero Result Card with vertical Monstera photo, square leaf badge & 95% Confidence pill
/// - Description section with white card container
/// - Recommendations section with structured Water, Light & Humidity items with icons
/// - Dark green "Add to Garden" button with leaf watermark accent
/// - Outlined "Scan Again" button
/// - Pl@ntNet API attribution footer
class ScanResultScreen extends StatelessWidget {
  const ScanResultScreen({super.key});

  String _toTitleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<ScanProvider>(
      builder: (context, scanProvider, _) {
        final diagnosis = scanProvider.diagnosis;

        if (diagnosis == null) {
          return Scaffold(
            backgroundColor: const Color(0xFFFAFBF8),
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.eco_outlined, size: 60, color: Color(0xFF1B4D3E)),
                    const SizedBox(height: 16),
                    const Text(
                      'No scan result available.',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1C3B30),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4D3E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text('Back to Home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFFAFBF8),
          body: Stack(
            children: [
              // ── Layer 1: Top-Right Leafy Branch Artwork ──
              Positioned(
                top: -10,
                right: -10,
                width: size.width * 0.55,
                height: size.height * 0.35,
                child: Opacity(
                  opacity: 0.9,
                  child: Image.asset(
                    'assets/images/register_leaf_bg.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),

              // ── Layer 2: Bottom Organic Wave Decoration ──
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 90,
                child: CustomPaint(
                  painter: ResultBottomWavePainter(),
                ),
              ),

              // ── Layer 3: Screen Content ──
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // ── Top Header Row (Back Button & Title) ──
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              scanProvider.reset();
                              context.pop();
                            },
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEBF5ED),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                size: 28,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Scan Result',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1C3B30),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 44), // Balances the back button
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── 1. Hero Plant Result Card ──
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF7F1),
                          borderRadius: BorderRadius.circular(28),
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
                            // Left: User Captured Photo Thumbnail
                            ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: (diagnosis.imagePath != null &&
                                      File(diagnosis.imagePath!).existsSync())
                                  ? Image.file(
                                      File(diagnosis.imagePath!),
                                      width: 145,
                                      height: 175,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/images/monstera.jpg',
                                      width: 145,
                                      height: 175,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        width: 145,
                                        height: 175,
                                        color: const Color(0xFFD5E8DC),
                                        child: const Icon(
                                          Icons.eco,
                                          size: 60,
                                          color: Color(0xFF1B4D3E),
                                        ),
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 16),

                            // Right: Badge, Name, Scientific Name & Confidence
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Square Leaf Badge
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2C553C),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.eco,
                                      size: 24,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Plant Name
                                  Text(
                                    diagnosis.plantName,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1C3B30),
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),

                                  // Scientific Name
                                  if (diagnosis.scientificName != null)
                                    Text(
                                      diagnosis.scientificName!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        color: Color(0xFF6A7E73),
                                      ),
                                    ),
                                  const SizedBox(height: 12),

                                  // Confidence Badge Pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD8EFE0),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.verified_user_outlined,
                                          size: 15,
                                          color: Color(0xFF2C553C),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${(diagnosis.confidence * 100).toStringAsFixed(0)}% Confidence',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2C553C),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 2. Description Section ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F3EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 16,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C3B30),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B4D3E).withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          diagnosis.description ??
                              '${diagnosis.plantName}${diagnosis.scientificName != null ? ' (${diagnosis.scientificName})' : ''} is a vibrant plant species widely grown for its attractive foliage and natural benefits.',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF4A6054),
                            height: 1.55,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── 3. Plant Diseases & Diagnosis Section ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: diagnosis.diseases.isNotEmpty
                                  ? const Color(0xFFFEE2E2)
                                  : const Color(0xFFE8F3EB),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              diagnosis.diseases.isNotEmpty
                                  ? Icons.coronavirus_outlined
                                  : Icons.verified_rounded,
                              size: 18,
                              color: diagnosis.diseases.isNotEmpty
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            diagnosis.diseases.isNotEmpty
                                ? 'Plant Diseases & Diagnosis'
                                : 'Plant Health Status',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C3B30),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (diagnosis.diseases.isNotEmpty)
                        ...diagnosis.diseases.map((disease) {
                          return Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: const Color(0xFFFECACA), width: 1.2),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFDC2626)
                                      .withValues(alpha: 0.05),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Warning Header Pill Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          '${_toTitleCase(disease.name)} Detected • ${(disease.probability * 100).toStringAsFixed(0)}% Match',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // About Disease Section
                                Text(
                                  'About ${disease.name}:',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  disease.description ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF7F1D1D),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                const Divider(
                                    color: Color(0xFFFECACA), height: 1),
                                const SizedBox(height: 16),

                                // Treatment & Action Plan Section
                                const Text(
                                  'Treatment & Action Plan:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF991B1B),
                                  ),
                                ),
                                const SizedBox(height: 10),

                                ...disease.treatments.map((treatment) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 10.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          margin:
                                              const EdgeInsets.only(top: 3),
                                          padding: const EdgeInsets.all(3),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFDC2626),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.check,
                                            size: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            treatment,
                                            style: const TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w500,
                                              color: Color(0xFF7F1D1D),
                                              height: 1.45,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        })
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F9F5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: const Color(0xFFE8F0EA), width: 1.2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F3EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.eco_rounded,
                                  size: 24,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No Diseases Detected 🌱',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF1C3B30),
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Your plant foliage appears healthy with no visible signs of fungal, bacterial, or pest infections.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF556B60),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 24),

                      // ── 3. Recommendations Section ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F3EB),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.eco,
                              size: 16,
                              color: Color(0xFF1B4D3E),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Recommendations',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1C3B30),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1B4D3E).withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Item 1: Water
                            _buildRecommendationItem(
                              icon: Icons.water_drop_outlined,
                              title: 'Water',
                              subtitle: diagnosis.recommendations.isNotEmpty
                                  ? diagnosis.recommendations[0]
                                  : 'Water when top inch of soil is dry',
                            ),
                            const Divider(color: Color(0xFFF0F4F1), height: 24),

                            // Item 2: Light
                            _buildRecommendationItem(
                              icon: Icons.wb_sunny_outlined,
                              title: 'Light',
                              subtitle: diagnosis.recommendations.length > 1
                                  ? diagnosis.recommendations[1]
                                  : 'Provide bright, indirect light',
                            ),
                            const Divider(color: Color(0xFFF0F4F1), height: 24),

                            // Item 3: Humidity
                            _buildRecommendationItem(
                              icon: Icons.opacity_outlined,
                              title: 'Humidity',
                              subtitle: diagnosis.recommendations.length > 2
                                  ? diagnosis.recommendations[2]
                                  : 'Mist leaves regularly for humidity',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── 4. Action Buttons ──
                      // Add to Garden Button
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: () async {
                                final plantProvider = context.read<PlantProvider>();
                                final plant = PlantModel(
                                  id: 'plant_${DateTime.now().millisecondsSinceEpoch}',
                                  name: diagnosis.plantName,
                                  scientificName: diagnosis.scientificName,
                                  description: diagnosis.description,
                                  imagePath: diagnosis.imagePath,
                                  imageUrl: diagnosis.imageUrl,
                                  confidence: diagnosis.confidence,
                                  recommendations: diagnosis.recommendations,
                                  diseases: diagnosis.diseases
                                      .map((d) => d.name)
                                      .toList(),
                                  treatments: diagnosis.diseases
                                      .expand((d) => d.treatments)
                                      .toList(),
                                  plantedDate: DateTime.now(),
                                  isInGarden: true,
                                );
                                await plantProvider.addPlant(plant);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${diagnosis.plantName} added to your garden!'),
                                      backgroundColor: AppColors.success,
                                    ),
                                  );
                                  scanProvider.reset();
                                  context.go('/dashboard/home');
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1B4D3E),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(
                                    Icons.add_circle_outline_rounded,
                                    size: 22,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    'Add to Garden',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Leaf Watermark Graphic on Right of Add Button
                          Positioned(
                            right: 16,
                            top: 6,
                            bottom: 6,
                            child: Opacity(
                              opacity: 0.35,
                              child: Transform.rotate(
                                angle: 0.3,
                                child: const Icon(
                                  Icons.eco,
                                  size: 38,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Scan Again Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: () {
                            scanProvider.reset();
                            context.pop();
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1B4D3E),
                            side: const BorderSide(
                                color: Color(0xFF1B4D3E), width: 1.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(
                                Icons.camera_alt_outlined,
                                size: 22,
                                color: Color(0xFF1B4D3E),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Scan Again',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Pl@ntNet Attribution ──
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('🌱 ', style: TextStyle(fontSize: 12)),
                            Text(
                              'Powered by Pl@ntNet API',
                              style: TextStyle(
                                color: Color(0xFF6A7E73),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper widget for recommendation list items.
  Widget _buildRecommendationItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3B30),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF556B60),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Custom painter for organic green wave pattern at bottom of Scan Result screen.
class ResultBottomWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF90B59E).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.2,
        size.width * 0.5,
        size.height * 0.45,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.7,
        size.width,
        size.height * 0.3,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
