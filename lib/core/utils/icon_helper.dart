import 'package:flutter/material.dart';
import 'package:snapstudy/features/subjects/domain/constants/subject_presets.dart';

/// Returns the [IconData] corresponding to [codePoint].
///
/// Looks up the code point from [SubjectPresets.icons] first so that
/// Flutter's icon tree-shaker can statically determine which glyphs are
/// used.  Falls back to the first preset icon if the code point is not
/// found (should never happen under normal usage).
IconData iconFromCodePoint(int codePoint) {
  for (final icon in SubjectPresets.icons) {
    if (icon.codePoint == codePoint) return icon;
  }
  // Fallback: return first preset so we never crash.
  return SubjectPresets.icons.first;
}
