import 'package:equatable/equatable.dart';

/// Lightweight subject card data for the dashboard.
class SubjectSummary extends Equatable {
  const SubjectSummary({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.sessionCount,
    required this.pendingReviews,
  });

  final String id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  final int sessionCount;
  final int pendingReviews;

  @override
  List<Object?> get props =>
      [id, name, colorValue, iconCodePoint, sessionCount, pendingReviews];
}
