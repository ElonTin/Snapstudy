import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/errors/app_exception.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/features/subjects/data/models/subject_folder_model.dart';
import 'package:snapstudy/features/subjects/data/models/subject_model.dart';

/// Hive-backed persistence for subjects and folders.
class SubjectLocalDataSource {
  Future<List<SubjectModel>> readSubjects() async {
    try {
      final raw = HiveService.subjectsBox.get(StorageKeys.subjectsList);
      if (raw is! List) return [];
      return raw
          .cast<Map>()
          .map((e) => SubjectModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw CacheException('Không đọc được danh sách môn học: $e');
    }
  }

  Future<void> writeSubjects(List<SubjectModel> subjects) async {
    try {
      await HiveService.subjectsBox.put(
        StorageKeys.subjectsList,
        subjects.map((s) => s.toJson()).toList(),
      );
    } catch (e) {
      throw CacheException('Không lưu được danh sách môn học: $e');
    }
  }

  Future<List<SubjectFolderModel>> readFolders() async {
    try {
      final raw = HiveService.subjectsBox.get(StorageKeys.subjectFoldersList);
      if (raw is! List) return [];
      return raw
          .cast<Map>()
          .map((e) => SubjectFolderModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      throw CacheException('Không đọc được thư mục: $e');
    }
  }

  Future<void> writeFolders(List<SubjectFolderModel> folders) async {
    try {
      await HiveService.subjectsBox.put(
        StorageKeys.subjectFoldersList,
        folders.map((f) => f.toJson()).toList(),
      );
    } catch (e) {
      throw CacheException('Không lưu được thư mục: $e');
    }
  }

  bool isSeeded() =>
      HiveService.settingsBox.get(StorageKeys.subjectsSeeded) == true;

  Future<void> markSeeded() async {
    await HiveService.settingsBox.put(StorageKeys.subjectsSeeded, true);
  }
}
