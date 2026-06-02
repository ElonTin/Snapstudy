import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

class SubjectModel {
  const SubjectModel({
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

  factory SubjectModel.fromJson(Map<String, dynamic> json) {
    return SubjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      colorValue: json['colorValue'] as int,
      iconCodePoint: json['iconCodePoint'] as int,
      folderId: json['folderId'] as String?,
      sessionCount: json['sessionCount'] as int? ?? 0,
      pendingReviews: json['pendingReviews'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
    );
  }

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

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'folderId': folderId,
        'sessionCount': sessionCount,
        'pendingReviews': pendingReviews,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
      };

  Subject toEntity() => Subject(
        id: id,
        name: name,
        description: description,
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
        folderId: folderId,
        sessionCount: sessionCount,
        pendingReviews: pendingReviews,
        createdAt: createdAt,
        updatedAt: updatedAt,
        isDeleted: isDeleted,
      );

  static SubjectModel fromEntity(Subject subject) => SubjectModel(
        id: subject.id,
        name: subject.name,
        description: subject.description,
        colorValue: subject.colorValue,
        iconCodePoint: subject.iconCodePoint,
        folderId: subject.folderId,
        sessionCount: subject.sessionCount,
        pendingReviews: subject.pendingReviews,
        createdAt: subject.createdAt,
        updatedAt: subject.updatedAt,
        isDeleted: subject.isDeleted,
      );
}
