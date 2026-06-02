import 'package:flutter/material.dart';

abstract final class MindmapColorUtils {
  static const _palette = [
    0xFF5C6BC0,
    0xFF26A69A,
    0xFFEF6C00,
    0xFFAB47BC,
    0xFF42A5F5,
    0xFFEC407A,
  ];

  static int parseColor(String? raw, int fallbackIndex) {
    if (raw == null || raw.trim().isEmpty) {
      return _palette[fallbackIndex % _palette.length];
    }
    var hex = raw.trim();
    if (hex.startsWith('#')) hex = hex.substring(1);
    if (hex.length == 6) hex = 'FF$hex';
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return _palette[fallbackIndex % _palette.length];
    return value;
  }

  static Color toColor(int colorValue) => Color(colorValue);
}
