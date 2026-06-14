import 'package:flutter/material.dart';

/// Design tokens — academic premium palette.
abstract final class AppColors {
  // Brand — scholarly navy + gold
  static const Color primary = Color(0xFF1E3A5F);
  static const Color primaryLight = Color(0xFF2D5A8E);
  static const Color primaryDark = Color(0xFF0F2440);

  static const Color secondary = Color(0xFFC9A227);
  static const Color secondaryLight = Color(0xFFE8C547);
  static const Color accent = Color(0xFF3D7A6E);

  // Semantic
  static const Color success = Color(0xFF2D6A4F);
  static const Color warning = Color(0xFFB8860B);
  static const Color error = Color(0xFFC0392B);
  static const Color info = Color(0xFF2D5A8E);

  // Light surfaces
  static const Color lightBackground = Color(0xFFFAFAF8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F1EC);
  static const Color lightBorder = Color(0xFFE8E4DC);
  static const Color lightTextPrimary = Color(0xFF1A1A2E);
  static const Color lightTextSecondary = Color(0xFF5C5C6F);

  // Dark surfaces
  static const Color darkBackground = Color(0xFF0F1419);
  static const Color darkSurface = Color(0xFF1A1F2E);
  static const Color darkSurfaceVariant = Color(0xFF252B3B);
  static const Color darkBorder = Color(0xFF3A4155);
  static const Color darkTextPrimary = Color(0xFFF5F3EF);
  static const Color darkTextSecondary = Color(0xFFA8A8B8);

  // AI / scan accent gradients
  static const Color aiGradientStart = Color(0xFF1E3A5F);
  static const Color aiGradientEnd = Color(0xFF3D7A6E);
  static const Color scanLineStart = Color(0x00C9A227);
  static const Color scanLineMid = Color(0xFFC9A227);
  static const Color scanLineEnd = Color(0x00C9A227);

  // Shadows
  static Color shadowLight = const Color(0xFF1A1A2E).withValues(alpha: 0.08);
  static Color shadowDark = Colors.black.withValues(alpha: 0.35);
}
