import 'package:flutter/material.dart';

/// Color palette extracted from the Plantcare design system.
/// 
/// Primary: dark green (#2D6A4F)
/// Surface: cream (#F5F5F0)
/// Accent: lime green for active states, amber for level badges
class AppColors {
  AppColors._();

  // ── Primary Greens ──
  static const Color primaryDark = Color(0xFF2D6A4F);
  static const Color primaryMedium = Color(0xFF40916C);
  static const Color primaryLight = Color(0xFF95D5B2);
  static const Color primarySurface = Color(0xFFD8F3DC);
  static const Color primaryFaint = Color(0xFFE8F5E9);

  // ── Background & Surface ──
  static const Color background = Color(0xFFF5F5F0);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF0F7F2);
  static const Color navBarBackground = Color(0xFFDCEED8);

  // ── Accent Colors ──
  static const Color activeTab = Color(0xFF7CB342);
  static const Color levelBadge = Color(0xFFE8A317);
  static const Color levelBadgeBackground = Color(0xFFFFF8E1);

  // ── Text ──
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Borders & Dividers ──
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // ── Status ──
  static const Color error = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);

  // ── Misc ──
  static const Color shadowColor = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);
}
