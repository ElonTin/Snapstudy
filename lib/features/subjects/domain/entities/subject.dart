import 'package:equatable/equatable.dart';

/// Full subject entity with appearance and folder assignment.
class Subject extends Equatable {
  const Subject({
    required this.id,
    required this.name,
    required this.colorValue,
    required this.iconCodePoint,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.folderId,
    this.sessionCount = 0,
    this.pendingReviews = 0,
    this.isDeleted = false,
  });

  final String id;
  final String name;
  final String? description;
  final int colorValue;
  final int iconCodePoint;
  final String? folderId;
  final int sessionCount;
  final int pendingReviews;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  Subject copyWith({
    String? id,
    String? name,
    String? description,
    int? colorValue,
    int? iconCodePoint,
    String? folderId,
    bool clearFolderId = false,
    int? sessionCount,
    int? pendingReviews,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      sessionCount: sessionCount ?? this.sessionCount,
      pendingReviews: pendingReviews ?? this.pendingReviews,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        colorValue,
        iconCodePoint,
        folderId,
        sessionCount,
        pendingReviews,
        createdAt,
        updatedAt,
        isDeleted,
      ];
}
