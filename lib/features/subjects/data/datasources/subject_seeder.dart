import 'package:flutter/material.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/subjects/data/models/subject_folder_model.dart';
import 'package:snapstudy/features/subjects/data/models/subject_model.dart';

/// Default subjects/folders for first launch.
abstract final class SubjectSeeder {
  static List<SubjectFolderModel> defaultFolders() {
    final now = DateTime.now();
    return [
      SubjectFolderModel(
        id: 'folder-hk1',
        name: 'Học kỳ 1',
        sortOrder: 0,
        createdAt: now,
        updatedAt: now,
      ),
      SubjectFolderModel(
        id: 'folder-ontap',
        name: 'Ôn thi',
        sortOrder: 1,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  static List<SubjectModel> defaultSubjects() {
    final now = DateTime.now();
    return [
      SubjectModel(
        id: 'sub-1',
        name: 'Toán 12',
        colorValue: AppColors.primary.toARGB32(),
        iconCodePoint: Icons.calculate_outlined.codePoint,
        folderId: 'folder-hk1',
        sessionCount: 8,
        pendingReviews: 12,
        createdAt: now,
        updatedAt: now,
      ),
      SubjectModel(
        id: 'sub-2',
        name: 'Vật lý',
        colorValue: AppColors.secondary.toARGB32(),
        iconCodePoint: Icons.science_outlined.codePoint,
        folderId: 'folder-hk1',
        sessionCount: 5,
        pendingReviews: 6,
        createdAt: now,
        updatedAt: now,
      ),
      SubjectModel(
        id: 'sub-3',
        name: 'Hóa học',
        colorValue: AppColors.accent.toARGB32(),
        iconCodePoint: Icons.biotech_outlined.codePoint,
        folderId: 'folder-ontap',
        sessionCount: 4,
        pendingReviews: 0,
        createdAt: now,
        updatedAt: now,
      ),
      SubjectModel(
        id: 'sub-4',
        name: 'Tiếng Anh',
        colorValue: AppColors.success.toARGB32(),
        iconCodePoint: Icons.translate_outlined.codePoint,
        folderId: 'folder-ontap',
        sessionCount: 3,
        pendingReviews: 8,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }
}
