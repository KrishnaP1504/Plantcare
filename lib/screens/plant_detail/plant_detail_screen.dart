import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/plant_model.dart';
import '../../providers/plant_provider.dart';

/// Redesigned Plant Detail Screen displaying all DiagnosisModel fields:
/// disease, confidence, recommendations, description, and treatments.
class PlantDetailScreen extends StatelessWidget {
  final String plantId;
  final bool isGlobalSearch;

  const PlantDetailScreen({
    super.key,
    required this.plantId,
    this.isGlobalSearch = false,
  });

  void _showRemoveConfirmationDialog(
    BuildContext context,
    PlantModel plant,
    PlantProvider plantProvider,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.delete_outline_rounded,
                color: Color(0xFFDC2626), size: 24),
            SizedBox(width: 8),
            Text(
              'Remove Plant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1C3B30),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to remove "${plant.name}" from your garden?',
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF556B60),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6A7E73),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final success = await plantProvider.removePlant(plant.id);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${plant.name} removed from your garden'),
                    backgroundColor: const Color(0xFF1B4D3E),
                  ),
                );
                context.pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Remove',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<PlantProvider>(
      builder: (context, plantProvider, _) {
        final plant = plantProvider.getPlantById(plantId) ??
            PlantModel(
              id: plantId,
              name: 'Tulasi',
              scientificName: 'Ocimum tenuiflorum',
              description:
                  'Tulasi, also known as Holy basil or Sacred basil, is a sacred and aromatic plant widely grown for its medicinal and spiritual benefits.',
              plantedDate: DateTime.now(),
              confidence: 0.95,
              recommendations: const [
                'Water when top inch of soil is dry',
                'Provide bright, indirect light',
                'Mist leaves regularly for humidity'
              ],
              isInGarden: true,
            );

        final confidencePercent = plant.confidence != null
            ? (plant.confidence! * 100).toStringAsFixed(0)
            : '95';

        Widget heroImageWidget;
        if (plant.imagePath != null && File(plant.imagePath!).existsSync()) {
          heroImageWidget = Image.file(
            File(plant.imagePath!),
            width: 150,
            height: 180,
            fit: BoxFit.cover,
          );
        } else if (plant.imageUrl != null && plant.imageUrl!.isNotEmpty) {
          heroImageWidget = Image.network(
            plant.imageUrl!,
            width: 150,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/images/monstera.jpg',
              width: 150,
              height: 180,
              fit: BoxFit.cover,
            ),
          );
        } else {
          heroImageWidget = Image.asset(
            'assets/images/monstera.jpg',
            width: 150,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.eco,
              size: 70,
              color: Color(0xFF1B4D3E),
            ),
          );
        }

        return Scaffold(
          backgroundColor: const Color(0xFFEFF7F0),
          body: SafeArea(
            child: Column(
              children: [
                // ── 1. Top Bar (Back Button & 3-Dots Options Menu) ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chevron_left_rounded,
                            size: 28,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                      ),

                      // 3-Dots Popup Menu Button with "Remove Plant"
                      PopupMenuButton<String>(
                        icon: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.more_horiz_rounded,
                            size: 24,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        onSelected: (value) {
                          if (value == 'remove') {
                            _showRemoveConfirmationDialog(
                                context, plant, plantProvider);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem<String>(
                            value: 'remove',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Remove Plant',
                                  style: TextStyle(
                                    color: Color(0xFFDC2626),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 2. Top Hero Area (Title, Days Card & Arch Image) ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 6, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column: Title, Scientific Name, Days & Confidence Badge
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              plant.name,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C3B30),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (plant.scientificName != null)
                              Text(
                                plant.scientificName!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                  color: Color(0xFF6A7E73),
                                ),
                              ),
                            const SizedBox(height: 14),

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
                                    size: 14,
                                    color: Color(0xFF2C553C),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '$confidencePercent% Confidence',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2C553C),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Days Pill Card ("Today / Yesterday / N days in your garden")
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1B4D3E)
                                        .withValues(alpha: 0.05),
                                    blurRadius: 14,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today_outlined,
                                        size: 16,
                                        color: Color(0xFF1B4D3E),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        plant.formattedDaysShort,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1C3B30),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'in your garden',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6A7E73),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Right Column: Sage Arch Background & Plant Image
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: size.width * 0.44,
                            height: 200,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD8EAE0),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(100),
                                topRight: Radius.circular(100),
                                bottomLeft: Radius.circular(32),
                                bottomRight: Radius.circular(32),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: heroImageWidget,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── 3. Bottom White Sheet Content Container ──
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36),
                        topRight: Radius.circular(36),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── About Section ──
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F3EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.eco,
                                  size: 18,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'About ${plant.name}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1C3B30),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            plant.description ??
                                '${plant.name}${plant.scientificName != null ? ' (${plant.scientificName})' : ''} is a plant species in your garden collection. It thrives in well-draining soil with bright indirect sunlight and regular watering.',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF4A6054),
                              height: 1.5,
                            ),
                          ),

                          const SizedBox(height: 20),
                          const Divider(color: Color(0xFFF0F4F1), height: 1),
                          const SizedBox(height: 20),

                          // ── Care Recommendations Section (From DiagnosisModel) ──
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE8F3EB),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.water_drop_outlined,
                                  size: 18,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Care Recommendations',
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
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6FAF7),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE8F0EA)),
                            ),
                            child: Column(
                              children: [
                                _buildRecommendationRow(
                                  icon: Icons.water_drop_outlined,
                                  title: 'Water',
                                  subtitle: plant.recommendations.isNotEmpty
                                      ? plant.recommendations[0]
                                      : 'Water when top inch of soil is dry',
                                ),
                                const Divider(color: Color(0xFFE8F0EA), height: 20),
                                _buildRecommendationRow(
                                  icon: Icons.wb_sunny_outlined,
                                  title: 'Light',
                                  subtitle: plant.recommendations.length > 1
                                      ? plant.recommendations[1]
                                      : 'Provide bright, indirect light',
                                ),
                                const Divider(color: Color(0xFFE8F0EA), height: 20),
                                _buildRecommendationRow(
                                  icon: Icons.opacity_outlined,
                                  title: 'Humidity',
                                  subtitle: plant.recommendations.length > 2
                                      ? plant.recommendations[2]
                                      : 'Mist leaves regularly for humidity',
                                ),
                              ],
                            ),
                          ),

                          // ── Disease & Health Status Section (From DiagnosisModel) ──
                          if (plant.diseases.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            const Divider(color: Color(0xFFF0F4F1), height: 1),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFEE2E2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.coronavirus_outlined,
                                    size: 18,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Diseases & Health Status',
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
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                      color: const Color(0xFFFECACA), width: 1.2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Disease Pills
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: plant.diseases.map((d) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFDC2626),
                                            borderRadius:
                                                BorderRadius.circular(18),
                                          ),
                                          child: Text(
                                            '⚠️ $d Detected',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 14),

                                    // About Pathogen Text
                                    if (plant.diseases.isNotEmpty) ...[
                                      Text(
                                        'About ${plant.diseases.first}:',
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF991B1B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Pathology diagnosis identified ${plant.diseases.join(', ')} affecting leaf tissue. Fungal spores or pathogens spread rapidly under humid conditions, requiring targeted treatment to restore plant health.',
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          color: Color(0xFF7F1D1D),
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      const Divider(
                                          color: Color(0xFFFECACA), height: 1),
                                      const SizedBox(height: 14),
                                    ],

                                    // Treatment & Action Plan Header
                                    if (plant.treatments.isNotEmpty) ...[
                                      const Text(
                                        'Treatment & Action Plan:',
                                        style: TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF991B1B),
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...plant.treatments.map((t) => Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8.0),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 3),
                                                  padding:
                                                      const EdgeInsets.all(3),
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
                                                    t,
                                                    style: const TextStyle(
                                                      fontSize: 13.5,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: Color(0xFF7F1D1D),
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )),
                                    ],
                                  ],
                                ),
                              ),
                          ],

                          const SizedBox(height: 24),
                          const Divider(color: Color(0xFFF0F4F1), height: 1),
                          const SizedBox(height: 24),

                          // ── Description Card with Right Photo Thumbnail ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE8F3EB),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.assignment_outlined,
                                            size: 18,
                                            color: Color(0xFF1B4D3E),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Identification',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1C3B30),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Identified as ${plant.name}${plant.scientificName != null ? ' (${plant.scientificName})' : ''} via Pl@ntNet AI database with ${(plant.confidence != null ? (plant.confidence! * 100).toStringAsFixed(0) : '95')}% confidence.',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Color(0xFF556B60),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Thumbnail Photo on Right
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: (plant.imagePath != null &&
                                        File(plant.imagePath!).existsSync())
                                    ? Image.file(
                                        File(plant.imagePath!),
                                        width: 105,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : Image.asset(
                                        'assets/images/monstera.jpg',
                                        width: 105,
                                        height: 80,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 105,
                                          height: 80,
                                          color: const Color(0xFFE8F3EB),
                                          child: const Icon(
                                            Icons.eco,
                                            color: Color(0xFF1B4D3E),
                                          ),
                                        ),
                                      ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // ── Action Buttons (Hidden for Global Search) ──
                          if (!isGlobalSearch) ...[
                            // In Your Garden Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (!plant.isInGarden) {
                                    await plantProvider.addPlant(plant);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              '${plant.name} added to your garden!'),
                                          backgroundColor:
                                              const Color(0xFF2E7D32),
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1B4D3E),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      plant.isInGarden
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.add_circle_outline_rounded,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      plant.isInGarden
                                          ? 'In Your Garden'
                                          : 'Add to Garden',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Diagnostics Button
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  context.push(
                                      '/camera?mode=diagnose&plantId=${plant.id}');
                                },
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1B4D3E),
                                  side: const BorderSide(
                                      color: Color(0xFF1B4D3E), width: 1.4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(27),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(
                                      Icons.biotech_outlined,
                                      size: 22,
                                      color: Color(0xFF1B4D3E),
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      'Diagnostics',
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
                          ],

                          // ── 5. "Did you know?" Trivia Card ──
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF4F9F5),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE8F0EA)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('🌱 ', style: TextStyle(fontSize: 26)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Did you know?',
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1C3B30),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${plant.name} purifies the air and is known to boost immunity and reduce stress.',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w400,
                                          color: Color(0xFF556B60),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.auto_awesome,
                                  size: 18,
                                  color: Color(0xFFA0B0A8),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecommendationRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF1B4D3E)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1C3B30),
                ),
              ),
              const SizedBox(height: 2),
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
