import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomBottomNav extends StatelessWidget {
  final int active;
  const CustomBottomNav({super.key, required this.active});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24, left: 24, right: 24,
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: const Color(0xFFD6E8D8),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, LucideIcons.layoutGrid, 0, '/home'),
            _buildNavItem(context, LucideIcons.flower2, 1, '/my_plants'),
            _buildScanButton(context),
            _buildNavItem(context, LucideIcons.calendar, 2, '/calendar'),
            _buildNavItem(context, LucideIcons.bookOpen, 3, '/guide'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, int index, String route) {
    final isActive = active == index;
    return GestureDetector(
      onTap: () {
        if (!isActive) Navigator.pushReplacementNamed(context, route);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: isActive ? const BoxDecoration(color: Color(0xFF7CB342), shape: BoxShape.circle) : null,
        child: Icon(icon, color: isActive ? Colors.white : const Color(0xFF558B2F), size: 24),
      ),
    );
  }

  Widget _buildScanButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/scanner'),
      child: Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF1B4B27),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFF1B4B27).withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
        ),
        child: const Icon(LucideIcons.camera, color: Colors.white, size: 28),
      ),
    );
  }
}