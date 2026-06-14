import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:snapstudy/core/theme/app_colors.dart';

/// Typography — Source Serif 4 (headings) + Inter (body).
abstract final class AppTypography {
  static TextTheme textTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final primary = isLight
        ? AppColors.lightTextPrimary
        : AppColors.darkTextPrimary;
    final secondary = isLight
        ? AppColors.lightTextSecondary
        : AppColors.darkTextSecondary;

    final bodyBase = GoogleFonts.interTextTheme();
    final serif = GoogleFonts.sourceSerif4TextTheme(bodyBase);

    return serif.copyWith(
      displayLarge: GoogleFonts.sourceSerif4(
        fontWeight: FontWeight.w700,
        fontSize: 40,
        letterSpacing: -1.0,
        height: 1.15,
        color: primary,
      ),
      displayMedium: GoogleFonts.sourceSerif4(
        fontWeight: FontWeight.w700,
        fontSize: 32,
        letterSpacing: -0.6,
        height: 1.2,
        color: primary,
      ),
      displaySmall: GoogleFonts.sourceSerif4(
        fontWeight: FontWeight.w600,
        fontSize: 28,
        letterSpacing: -0.4,
        color: primary,
      ),
      headlineLarge: GoogleFonts.sourceSerif4(
        fontWeight: FontWeight.w600,
        fontSize: 24,
        letterSpacing: -0.3,
        color: primary,
      ),
      headlineMedium: GoogleFonts.sourceSerif4(
        fontWeight: FontWeight.w600,
        fontSize: 22,
        color: primary,
      ),
      headlineSmall: GoogleFonts.sourceSerif4(
        fontWeight: FontWeight.w600,
        fontSize: 20,
        color: primary,
      ),
      titleLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 18,
        color: primary,
      ),
      titleMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 16,
        color: primary,
      ),
      titleSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 14,
        color: primary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 16,
        height: 1.55,
        color: primary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 14,
        height: 1.5,
        color: primary,
      ),
      bodySmall: GoogleFonts.inter(
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.45,
        color: secondary,
      ),
      labelLarge: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        letterSpacing: 0.3,
        color: primary,
      ),
      labelMedium: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 12,
        letterSpacing: 0.2,
        color: secondary,
      ),
      labelSmall: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        letterSpacing: 0.15,
        color: secondary,
      ),
    );
  }
}
