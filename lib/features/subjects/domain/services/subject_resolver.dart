import 'package:flutter/material.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/domain/repositories/subject_repository.dart';

/// Tìm môn có sẵn hoặc tạo mới theo tên AI (không giới hạn danh sách cố định).
abstract final class SubjectResolver {
  static final _palette = [
    AppColors.primary.toARGB32(),
    AppColors.secondary.toARGB32(),
    AppColors.accent.toARGB32(),
    const Color(0xFF6B4EFF).toARGB32(),
    const Color(0xFF00897B).toARGB32(),
    const Color(0xFFE65100).toARGB32(),
    const Color(0xFF5D4037).toARGB32(),
    const Color(0xFF1565C0).toARGB32(),
  ];

  static Future<Result<Subject>> resolveOrCreate({
    required SubjectRepository repository,
    required String subjectName,
  }) async {
    final name = subjectName.trim();
    if (name.isEmpty) {
      return const Error(ValidationFailure('Tên môn trống.'));
    }

    final listResult = await repository.getSubjects();
    return listResult.fold(
      onSuccess: (subjects) async {
        final normalized = _normalize(name);
        Subject? match;

        for (final s in subjects) {
          final sn = _normalize(s.name);
          if (sn == normalized ||
              sn.contains(normalized) ||
              normalized.contains(sn)) {
            match = s;
            break;
          }
        }

        if (match != null) return Success(match);

        final color = _palette[name.hashCode.abs() % _palette.length];
        return repository.createSubject(
          name: name,
          description: 'Tự động tạo bởi AI phân loại',
          colorValue: color,
          iconCodePoint: Icons.auto_stories_outlined.codePoint,
        );
      },
      onFailure: Error.new,
    );
  }

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
