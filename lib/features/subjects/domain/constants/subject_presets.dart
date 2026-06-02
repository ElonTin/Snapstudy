import 'package:flutter/material.dart';
import 'package:snapstudy/core/theme/app_colors.dart';

/// Preset colors and icons for subject customization.
abstract final class SubjectPresets {
  static const List<Color> colors = [
    AppColors.primary,
    AppColors.secondary,
    AppColors.accent,
    AppColors.success,
    AppColors.warning,
    AppColors.error,
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
  ];

  static const List<IconData> icons = [
    Icons.calculate_outlined,
    Icons.science_outlined,
    Icons.biotech_outlined,
    Icons.translate_outlined,
    Icons.menu_book_outlined,
    Icons.history_edu_outlined,
    Icons.computer_outlined,
    Icons.palette_outlined,
    Icons.music_note_outlined,
    Icons.public_outlined,
  ];
}
