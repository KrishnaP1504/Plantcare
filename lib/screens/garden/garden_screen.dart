import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/plant_provider.dart';
import '../../widgets/plant_card.dart';

/// Redesigned Garden Screen with "Plant Care Overview" dashboard & User Photo Gallery.
class GardenScreen extends StatelessWidget {
  const GardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 130),
        child: Consumer<PlantProvider>(
          builder: (context, plantProvider, _) {
            final plants = plantProvider.plants;
            final allPlantsCount = plants.length;
            final needWaterCount = plants.where((p) => p.needsWater).length;
            final doingGreatCount =
                plants.where((p) => p.diseases.isEmpty).length;
            final reminderCount = plants.isEmpty ? 0 : 1;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Title ──
                const Text(
                  'My Garden',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C3B30),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'All your plants & care status in one place',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6A7E73),
                  ),
                ),

                const SizedBox(height: 24),

                // ── "Plant Care Overview" Section ──
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
                      'Plant Care Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C3B30),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // 2x2 Overview Cards Grid
                Row(
                  children: [
                    // Card 1: All Plants
                    Expanded(
                      child: _buildOverviewCard(
                        title: 'All Plants',
                        subtitle: '$allPlantsCount Plants in garden',
                        count: '$allPlantsCount',
                        icon: Icons.eco_outlined,
                        iconBgColor: const Color(0xFFEBF5ED),
                        iconColor: const Color(0xFF1B4D3E),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Card 2: Need Water
                    Expanded(
                      child: _buildOverviewCard(
                        title: 'Need Water',
                        subtitle: '$needWaterCount Plants need water',
                        count: '$needWaterCount',
                        icon: Icons.water_drop_outlined,
                        iconBgColor: const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    // Card 3: Doing Great
                    Expanded(
                      child: _buildOverviewCard(
                        title: 'Doing Great',
                        subtitle: '$doingGreatCount Healthy plants',
                        count: '$doingGreatCount',
                        icon: Icons.sentiment_very_satisfied_outlined,
                        iconBgColor: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF15803D),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Card 4: Reminder
                    Expanded(
                      child: _buildOverviewCard(
                        title: 'Reminder',
                        subtitle: '$reminderCount Tasks today',
                        count: '$reminderCount',
                        icon: Icons.notifications_none_outlined,
                        iconBgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── "My Plants" Section Header ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Plants',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1C3B30),
                      ),
                    ),
                    Text(
                      '$allPlantsCount Total',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF6A7E73),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Plant Grid List ──
                if (plantProvider.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40.0),
                      child: CircularProgressIndicator(
                          color: Color(0xFF1B4D3E)),
                    ),
                  )
                else if (plants.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 36, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8F0EA)),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.center_focus_weak_rounded,
                            size: 42,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No plants in your garden yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1C3B30),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Scan a plant with your camera to add it to your garden',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6A7E73),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: plants.length,
                    itemBuilder: (context, index) {
                      final plant = plants[index];
                      return PlantCard(
                        plant: plant,
                        onTap: () => context.push('/plant/${plant.id}'),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Helper widget to build individual Plant Care Overview metric cards.
  Widget _buildOverviewCard({
    required String title,
    required String subtitle,
    required String count,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8F0EA)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: iconColor,
                ),
              ),
              Text(
                count,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1C3B30),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6A7E73),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
