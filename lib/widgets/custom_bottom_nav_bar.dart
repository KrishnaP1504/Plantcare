import 'package:flutter/material.dart';

/// Floating pill-shaped bottom navigation bar with tropical leaves background.
///
/// Matches the screenshot design:
/// - 5 tab items: Home, Plants, Camera (FAB), Care, Guide
/// - Active Home tab with rounded green container
/// - Central elevated dark green camera FAB
/// - Tropical plant leaves graphics peeking behind the nav bar on left & right
class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onCameraTap;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Tropical Plant Leaves Background in Bottom Corners ──
        Positioned(
          bottom: 0,
          left: 4,
          child: Opacity(
            opacity: 0.85,
            child: SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(
                painter: TropicalLeavesPainter(isLeft: true),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 4,
          child: Opacity(
            opacity: 0.85,
            child: SizedBox(
              width: 90,
              height: 90,
              child: CustomPaint(
                painter: TropicalLeavesPainter(isLeft: false),
              ),
            ),
          ),
        ),

        // ── Floating White Navigation Bar Container ──
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(36),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B4D3E).withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, Icons.home_rounded, 'Home'),
                _buildNavItem(1, Icons.park_outlined, 'Plants'),
                _buildCameraButton(),
                _buildNavItem(2, Icons.calendar_today_outlined, 'Care', badge: '8'),
                _buildNavItem(3, Icons.menu_book_outlined, 'Guide'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {String? badge}) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE8F3EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isActive ? const Color(0xFF1B4D3E) : const Color(0xFF556B60),
                ),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1B4D3E),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? const Color(0xFF1B4D3E) : const Color(0xFF556B60),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraButton() {
    return GestureDetector(
      onTap: onCameraTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          color: Color(0xFF1B4D3E),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x301B4D3E),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.camera_alt_rounded,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Custom painter for the tropical plant leaves in the bottom corners of the nav bar.
class TropicalLeavesPainter extends CustomPainter {
  final bool isLeft;

  TropicalLeavesPainter({required this.isLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paintDark = Paint()
      ..color = const Color(0xFF2C553C)
      ..style = PaintingStyle.fill;

    final paintLight = Paint()
      ..color = const Color(0xFF4A7C59)
      ..style = PaintingStyle.fill;

    canvas.save();
    if (!isLeft) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    // Draw leaf 1
    final path1 = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.2, 0)
      ..quadraticBezierTo(size.width * 0.7, size.height * 0.4, 0, size.height);
    canvas.drawPath(path1, paintDark);

    // Draw leaf 2
    final path2 = Path()
      ..moveTo(0, size.height)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.6, size.width * 0.8, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.9, size.height * 0.7, 0, size.height);
    canvas.drawPath(path2, paintLight);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
