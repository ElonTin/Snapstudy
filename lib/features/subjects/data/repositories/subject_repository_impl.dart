import 'package:snapstudy/core/errors/app_exception.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/subjects/data/datasources/subject_local_datasource.dart';
import 'package:snapstudy/features/subjects/data/datasources/subject_seeder.dart';
import 'package:snapstudy/features/subjects/data/models/subject_folder_model.dart';
import 'package:snapstudy/features/subjects/data/models/subject_model.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject_folder.dart';
import 'package:snapstudy/features/subjects/domain/repositories/subject_repository.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl(this._local);

  final SubjectLocalDataSource _local;

  String _newId(String prefix) =>
      '$prefix${DateTime.now().millisecondsSinceEpoch}';

  @override
  Future<Result<void>> ensureSeeded() async {
    try {
      if (_local.isSeeded()) return const Success(null);

      final existing = await _local.readSubjects();
      if (existing.isNotEmpty) {
        await _local.markSeeded();
        return const Success(null);
      }

      await _local.writeFolders(SubjectSeeder.defaultFolders());
      await _local.writeSubjects(SubjectSeeder.defaultSubjects());
      await _local.markSeeded();
      return const Success(null);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<Subject>>> getSubjects() async {
    try {
      await ensureSeeded();
      final models = await _local.readSubjects();
      final subjects = models
          .where((s) => !s.isDeleted)
          .map((s) => s.toEntity())
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      return Success(subjects);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Subject?>> getSubjectById(String id) async {
    final result = await getSubjects();
    return result.fold(
      onSuccess: (list) {
        for (final s in list) {
          if (s.id == id) return Success(s);
        }
        return const Success(null);
      },
      onFailure: Error.new,
    );
  }

  @override
  Future<Result<Subject>> createSubject({
    required String name,
    String? description,
    required int colorValue,
    required int iconCodePoint,
    String? folderId,
  }) async {
    try {
      if (name.trim().isEmpty) {
        return const Error(ValidationFailure('Tên môn học không được trống.'));
      }

      final now = DateTime.now();
      final subject = SubjectModel(
        id: _newId('sub_'),
        name: name.trim(),
        description: description?.trim(),
        colorValue: colorValue,
        iconCodePoint: iconCodePoint,
        folderId: folderId,
        createdAt: now,
        updatedAt: now,
      );

      final all = await _local.readSubjects();
      all.add(subject);
      await _local.writeSubjects(all);
      return Success(subject.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<Subject>> updateSubject(Subject subject) async {
    try {
      if (subject.name.trim().isEmpty) {
        return const Error(ValidationFailure('Tên môn học không được trống.'));
      }

      final all = await _local.readSubjects();
      final index = all.indexWhere((s) => s.id == subject.id);
      if (index < 0) {
        return const Error(ValidationFailure('Không tìm thấy môn học.'));
      }

      final updated = SubjectModel.fromEntity(
        subject.copyWith(
          name: subject.name.trim(),
          updatedAt: DateTime.now(),
        ),
      );
      all[index] = updated;
      await _local.writeSubjects(all);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteSubject(String id) async {
    try {
      final all = await _local.readSubjects();
      final index = all.indexWhere((s) => s.id == id);
      if (index < 0) {
        return const Error(ValidationFailure('Không tìm thấy môn học.'));
      }

      all[index] = SubjectModel(
        id: all[index].id,
        name: all[index].name,
        description: all[index].description,
        colorValue: all[index].colorValue,
        iconCodePoint: all[index].iconCodePoint,
        folderId: all[index].folderId,
        sessionCount: all[index].sessionCount,
        pendingReviews: all[index].pendingReviews,
        createdAt: all[index].createdAt,
        updatedAt: DateTime.now(),
        isDeleted: true,
      );
      await _local.writeSubjects(all);
      return const Success(null);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<SubjectFolder>>> getFolders() async {
    try {
      await ensureSeeded();
      final models = await _local.readFolders();
      final folders = models.map((f) => f.toEntity()).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return Success(folders);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SubjectFolder>> createFolder(String name) async {
    try {
      if (name.trim().isEmpty) {
        return const Error(ValidationFailure('Tên thư mục không được trống.'));
      }

      final now = DateTime.now();
      final all = await _local.readFolders();
      final folder = SubjectFolderModel(
        id: _newId('folder_'),
        name: name.trim(),
        sortOrder: all.length,
        createdAt: now,
        updatedAt: now,
      );
      all.add(folder);
      await _local.writeFolders(all);
      return Success(folder.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<SubjectFolder>> updateFolder(SubjectFolder folder) async {
    try {
      final all = await _local.readFolders();
      final index = all.indexWhere((f) => f.id == folder.id);
      if (index < 0) {
        return const Error(ValidationFailure('Không tìm thấy thư mục.'));
      }
      all[index] = SubjectFolderModel.fromEntity(
        SubjectFolder(
          id: folder.id,
          name: folder.name.trim(),
          sortOrder: folder.sortOrder,
          createdAt: folder.createdAt,
          updatedAt: DateTime.now(),
        ),
      );
      await _local.writeFolders(all);
      return Success(all[index].toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> deleteFolder(String id) async {
    try {
      final folders = await _local.readFolders();
      folders.removeWhere((f) => f.id == id);
      await _local.writeFolders(folders);

      final subjects = await _local.readSubjects();
      for (var i = 0; i < subjects.length; i++) {
        if (subjects[i].folderId == id) {
          subjects[i] = SubjectModel(
            id: subjects[i].id,
            name: subjects[i].name,
            description: subjects[i].description,
            colorValue: subjects[i].colorValue,
            iconCodePoint: subjects[i].iconCodePoint,
            folderId: null,
            sessionCount: subjects[i].sessionCount,
            pendingReviews: subjects[i].pendingReviews,
            createdAt: subjects[i].createdAt,
            updatedAt: DateTime.now(),
            isDeleted: subjects[i].isDeleted,
          );
        }
      }
      await _local.writeSubjects(subjects);
      return const Success(null);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}
