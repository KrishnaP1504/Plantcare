import 'dart:io';
import 'package:flutter/material.dart';
import '../models/plant_model.dart';

/// Plant card widget displaying user captured plant photo.
class PlantCard extends StatelessWidget {
  final PlantModel plant;
  final VoidCallback? onTap;

  const PlantCard({
    super.key,
    required this.plant,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (plant.imagePath != null && File(plant.imagePath!).existsSync()) {
      imageWidget = Image.file(
        File(plant.imagePath!),
        fit: BoxFit.cover,
      );
    } else if (plant.imageUrl != null && plant.imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        plant.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.eco,
          size: 36,
          color: Color(0xFF1B4D3E),
        ),
      );
    } else {
      imageWidget = Container(
        color: const Color(0xFFE8F3EB),
        child: const Center(
          child: Icon(
            Icons.eco,
            size: 36,
            color: Color(0xFF1B4D3E),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE8F0EA)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1B4D3E).withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Photo Thumbnail
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: double.infinity,
                  child: imageWidget,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              plant.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1C3B30),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              plant.formattedPlantedAgo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6A7E73),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
