import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject_folder.dart';

abstract interface class SubjectRepository {
  Future<Result<List<Subject>>> getSubjects();

  Future<Result<Subject?>> getSubjectById(String id);

  Future<Result<Subject>> createSubject({
    required String name,
    String? description,
    required int colorValue,
    required int iconCodePoint,
    String? folderId,
  });

  Future<Result<Subject>> updateSubject(Subject subject);

  Future<Result<void>> deleteSubject(String id);

  Future<Result<List<SubjectFolder>>> getFolders();

  Future<Result<SubjectFolder>> createFolder(String name);

  Future<Result<SubjectFolder>> updateFolder(SubjectFolder folder);

  Future<Result<void>> deleteFolder(String id);

  Future<Result<void>> ensureSeeded();
}
