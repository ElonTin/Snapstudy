import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/features/home/presentation/providers/dashboard_provider.dart';
import 'package:snapstudy/features/subjects/data/datasources/subject_local_datasource.dart';
import 'package:snapstudy/features/subjects/data/repositories/subject_repository_impl.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject_folder.dart';
import 'package:snapstudy/features/subjects/domain/repositories/subject_repository.dart';

final subjectLocalDataSourceProvider = Provider<SubjectLocalDataSource>(
  (ref) => SubjectLocalDataSource(),
);

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepositoryImpl(ref.watch(subjectLocalDataSourceProvider));
});

/// All active subjects.
class SubjectsController extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    final result = await ref.read(subjectRepositoryProvider).getSubjects();
    return result.fold(
      onSuccess: (list) => list,
      onFailure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(subjectRepositoryProvider).getSubjects();
      return result.fold(
        onSuccess: (list) => list,
        onFailure: (f) => throw f,
      );
    });
    ref.invalidate(dashboardProvider);
  }

  Future<bool> create({
    required String name,
    String? description,
    required int colorValue,
    required int iconCodePoint,
    String? folderId,
  }) async {
    final result = await ref.read(subjectRepositoryProvider).createSubject(
          name: name,
          description: description,
          colorValue: colorValue,
          iconCodePoint: iconCodePoint,
          folderId: folderId,
        );
    if (result.isSuccess) {
      await refresh();
      return true;
    }
    state = AsyncError(result.failureOrNull!, StackTrace.current);
    return false;
  }

  Future<bool> updateSubject(Subject subject) async {
    final result =
        await ref.read(subjectRepositoryProvider).updateSubject(subject);
    if (result.isSuccess) {
      await refresh();
      return true;
    }
    state = AsyncError(result.failureOrNull!, StackTrace.current);
    return false;
  }

  Future<bool> delete(String id) async {
    final result =
        await ref.read(subjectRepositoryProvider).deleteSubject(id);
    if (result.isSuccess) {
      await refresh();
      return true;
    }
    state = AsyncError(result.failureOrNull!, StackTrace.current);
    return false;
  }
}

final subjectsControllerProvider =
    AsyncNotifierProvider<SubjectsController, List<Subject>>(
  SubjectsController.new,
);

/// Subject folders.
class SubjectFoldersController extends AsyncNotifier<List<SubjectFolder>> {
  @override
  Future<List<SubjectFolder>> build() async {
    final result = await ref.read(subjectRepositoryProvider).getFolders();
    return result.fold(
      onSuccess: (list) => list,
      onFailure: (f) => throw f,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final result = await ref.read(subjectRepositoryProvider).getFolders();
      return result.fold(
        onSuccess: (list) => list,
        onFailure: (f) => throw f,
      );
    });
  }

  Future<bool> create(String name) async {
    final result =
        await ref.read(subjectRepositoryProvider).createFolder(name);
    return result.fold(
      onSuccess: (_) {
        refresh();
        ref.read(subjectsControllerProvider.notifier).refresh();
        return true;
      },
      onFailure: (f) {
        state = AsyncError(f, StackTrace.current);
        return false;
      },
    );
  }

  Future<bool> delete(String id) async {
    final result =
        await ref.read(subjectRepositoryProvider).deleteFolder(id);
    return result.fold(
      onSuccess: (_) {
        refresh();
        ref.read(subjectsControllerProvider.notifier).refresh();
        return true;
      },
      onFailure: (f) {
        state = AsyncError(f, StackTrace.current);
        return false;
      },
    );
  }
}

final subjectFoldersControllerProvider =
    AsyncNotifierProvider<SubjectFoldersController, List<SubjectFolder>>(
  SubjectFoldersController.new,
);
