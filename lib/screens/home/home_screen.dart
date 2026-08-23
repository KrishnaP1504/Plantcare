import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plant_provider.dart';
import '../../models/plant_model.dart';

/// Redesigned Home Dashboard Screen displaying user captured plant photos.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PlantProvider>().loadPlants();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _getGlobalPlantImage(String query) {
    final q = query.toLowerCase();
    if (q.contains('tulsi') || q.contains('tulasi') || q.contains('basil')) {
      return 'https://images.unsplash.com/photo-1618164436241-4473940d1f5c?w=800&auto=format&fit=crop';
    } else if (q.contains('monstera')) {
      return 'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?w=800&auto=format&fit=crop';
    } else if (q.contains('rose')) {
      return 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=800&auto=format&fit=crop';
    } else if (q.contains('aloe')) {
      return 'https://images.unsplash.com/photo-1596547609652-9cf5d8d76921?w=800&auto=format&fit=crop';
    } else if (q.contains('snake') || q.contains('sansevieria')) {
      return 'https://images.unsplash.com/photo-1593482892290-f54927ae1bac?w=800&auto=format&fit=crop';
    } else if (q.contains('lily') || q.contains('peace')) {
      return 'https://images.unsplash.com/photo-1593691509543-c55fb32e7355?w=800&auto=format&fit=crop';
    } else if (q.contains('sunflower')) {
      return 'https://images.unsplash.com/photo-1597848212624-a19eb35e2651?w=800&auto=format&fit=crop';
    } else if (q.contains('orchid')) {
      return 'https://images.unsplash.com/photo-1525310072745-f49212b5ac6d?w=800&auto=format&fit=crop';
    } else if (q.contains('fern')) {
      return 'https://images.unsplash.com/photo-1512428559087-560fa5ceab42?w=800&auto=format&fit=crop';
    } else if (q.contains('succulent')) {
      return 'https://images.unsplash.com/photo-1509423350716-97f9360b4e09?w=800&auto=format&fit=crop';
    } else if (q.contains('palm')) {
      return 'https://images.unsplash.com/photo-1592150621744-aca64f48394a?w=800&auto=format&fit=crop';
    } else if (q.contains('cactus')) {
      return 'https://images.unsplash.com/photo-1508615070457-7baeba4003ab?w=800&auto=format&fit=crop';
    } else if (q.contains('bamboo')) {
      return 'https://images.unsplash.com/photo-1567331711402-509a764d84c3?w=800&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1518531933037-91b2f5f229cc?w=800&auto=format&fit=crop';
  }

  void _handleGlobalSearch() {
    final rawQuery = _searchController.text.trim();
    if (rawQuery.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a plant name to search'),
          backgroundColor: Color(0xFF1B4D3E),
        ),
      );
      return;
    }

    final capitalizedQuery =
        rawQuery[0].toUpperCase() + rawQuery.substring(1);
    final searchId = 'global_${DateTime.now().millisecondsSinceEpoch}';
    final imageUrl = _getGlobalPlantImage(rawQuery);

    final searchPlant = PlantModel(
      id: searchId,
      name: capitalizedQuery,
      scientificName: '$capitalizedQuery species',
      description:
          '$capitalizedQuery is a botanical plant species discovered via global search database. It thrives in well-draining soil with bright, indirect sunlight and regular watering.',
      imageUrl: imageUrl,
      confidence: 0.96,
      recommendations: const [
        'Water when top inch of soil feels dry',
        'Provide bright, indirect sunlight',
        'Maintain good drainage & humidity',
      ],
      isInGarden: false,
    );

    context.read<PlantProvider>().addGlobalSearchPlant(searchPlant);
    context.push('/plant/$searchId?isGlobal=true');
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          130, // Space for floating bottom nav
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. Header Row (Avatar, Greeting, Level Badge, Notification Bell) ──
            Row(
              children: [
                // Avatar with Leaf Badge
                GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F3EB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_outline_rounded,
                          size: 30,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: -2,
                        child: Transform.rotate(
                          angle: 0.3,
                          child: const Icon(
                            Icons.eco,
                            size: 18,
                            color: Color(0xFF2C553C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Greeting & Level Badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.username ?? 'krishna'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1C3B30),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8F5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2EBE5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🌱 ', style: TextStyle(fontSize: 12)),
                            Text(
                              'Lvl ${user?.level ?? 1} • ${user?.levelTitle ?? 'Novice'}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFE5A100),
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

            const SizedBox(height: 22),

            // ── 2. Search Bar ──
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1B4D3E).withValues(alpha: 0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.search,
                        color: Color(0xFFA0B0A8),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          cursorColor: const Color(0xFF1B4D3E),
                          onSubmitted: (_) => _handleGlobalSearch(),
                          textInputAction: TextInputAction.search,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1C3B30),
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Search for plants...',
                            hintStyle: TextStyle(
                              color: Color(0xFFA0B0A8),
                              fontSize: 15,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _handleGlobalSearch,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1B4D3E),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Leaf Vine Graphic under Search Bar Right Edge
                Positioned(
                  bottom: -22,
                  right: -10,
                  child: Transform.rotate(
                    angle: 0.2,
                    child: const Icon(
                      Icons.eco,
                      size: 26,
                      color: Color(0xFF4A7C59),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── 3. Featured Plant Hero Banner ──
            Consumer<PlantProvider>(
              builder: (context, plantProvider, _) {
                final plants = plantProvider.plants;
                final featuredPlant = plants.isNotEmpty ? plants.first : null;

                Widget plantImageWidget;
                if (featuredPlant?.imagePath != null &&
                    File(featuredPlant!.imagePath!).existsSync()) {
                  plantImageWidget = Image.file(
                    File(featuredPlant.imagePath!),
                    width: 135,
                    height: 135,
                    fit: BoxFit.cover,
                  );
                } else if (featuredPlant?.imageUrl != null &&
                    featuredPlant!.imageUrl!.isNotEmpty) {
                  plantImageWidget = Image.network(
                    featuredPlant.imageUrl!,
                    width: 135,
                    height: 135,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.eco,
                      size: 60,
                      color: Color(0xFF1B4D3E),
                    ),
                  );
                } else {
                  plantImageWidget = const Icon(
                    Icons.camera_alt_outlined,
                    size: 50,
                    color: Color(0xFF1B4D3E),
                  );
                }

                return Container(
                  width: double.infinity,
                  height: 190,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF4ED),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    children: [
                      // Smooth Arch Background behind Plant Image
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        width: 175,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topRight: Radius.circular(28),
                            bottomRight: Radius.circular(28),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: Color(0xFFD5E8DC),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(100),
                                bottomLeft: Radius.circular(100),
                              ),
                            ),
                            child: Center(
                              child: ClipOval(
                                child: plantImageWidget,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Content Left Column
                      Padding(
                        padding: const EdgeInsets.all(22.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              featuredPlant?.name ?? 'Scan Your Plant',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1C3B30),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              featuredPlant != null
                                  ? featuredPlant.formattedPlantedAgo
                                  : 'Tap camera to identify & save',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6A7E73),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Stats Pill (24°C | 60%)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF1B4D3E)
                                        .withValues(alpha: 0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(
                                    Icons.thermostat_rounded,
                                    size: 18,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '24°C',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1C3B30),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    '|',
                                    style: TextStyle(
                                      color: Color(0xFFD0DDD5),
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Icon(
                                    Icons.water_drop_rounded,
                                    size: 16,
                                    color: Color(0xFF1B4D3E),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '60%',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF1C3B30),
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
                );
              },
            ),

            const SizedBox(height: 28),

            // ── 4. "My Garden" Section Header ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Garden',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1C3B30),
                  ),
                ),
                GestureDetector(
                  onTap: () => context.go('/dashboard/garden'),
                  child: Row(
                    children: const [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B4D3E),
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: Color(0xFF1B4D3E),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 5. User Garden Section (Up to 3 Plants with Diagnosis Status) ──
            Consumer<PlantProvider>(
              builder: (context, plantProvider, _) {
                final plants = plantProvider.plants;

                if (plants.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6FAF7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE8F0EA)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F3EB),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.center_focus_weak_rounded,
                            size: 28,
                            color: Color(0xFF1B4D3E),
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No plants added yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1C3B30),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Click the camera button below to scan your first plant',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6A7E73),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Limit display to max 3 plants on Dashboard
                final displayPlants = plants.take(3).toList();

                return Column(
                  children: [
                    ...displayPlants.map((plant) {
                      Widget thumbnailWidget;
                      if (plant.imagePath != null &&
                          File(plant.imagePath!).existsSync()) {
                        thumbnailWidget = Image.file(
                          File(plant.imagePath!),
                          fit: BoxFit.cover,
                        );
                      } else if (plant.imageUrl != null &&
                          plant.imageUrl!.isNotEmpty) {
                        thumbnailWidget = Image.network(
                          plant.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.eco,
                            size: 40,
                            color: Color(0xFF1B4D3E),
                          ),
                        );
                      } else {
                        thumbnailWidget = const Icon(
                          Icons.eco,
                          size: 40,
                          color: Color(0xFF1B4D3E),
                        );
                      }

                      // Determine diagnosis & care badge
                      Widget statusBadge;
                      if (plant.diseases.isNotEmpty) {
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 12,
                                color: Color(0xFFDC2626),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                plant.diseases.first,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (plant.needsWater) {
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.water_drop_rounded,
                                size: 12,
                                color: Color(0xFFD97706),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Needs Water',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        statusBadge = Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3EB),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.eco_rounded,
                                size: 12,
                                color: Color(0xFF1B4D3E),
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Doing Great',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1B4D3E),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GestureDetector(
                          onTap: () => context.push('/plant/${plant.id}'),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6FAF7),
                              borderRadius: BorderRadius.circular(24),
                              border:
                                  Border.all(color: const Color(0xFFE8F0EA)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1B4D3E)
                                      .withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Thumbnail
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F3EB),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: thumbnailWidget,
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Title, Scientific Name & Diagnosis Badge
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        plant.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF1C3B30),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (plant.scientificName != null)
                                        Text(
                                          plant.scientificName!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontStyle: FontStyle.italic,
                                            color: Color(0xFF6A7E73),
                                          ),
                                        ),
                                      const SizedBox(height: 8),
                                      statusBadge,
                                    ],
                                  ),
                                ),

                                // Chevron Arrow
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F3EB),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chevron_right_rounded,
                                    color: Color(0xFF1B4D3E),
                                    size: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),

                    // View All Plants Button if user has more than 3 plants
                    if (plants.length > 3)
                      GestureDetector(
                        onTap: () => context.go('/dashboard/garden'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE8F0EA)),
                          ),
                          child: Center(
                            child: Text(
                              'View All ${plants.length} Plants in Garden →',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1B4D3E),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
