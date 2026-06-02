import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:snapstudy/core/constants/storage_keys.dart';
import 'package:snapstudy/core/storage/hive_boxes.dart';
import 'package:snapstudy/core/storage/hive_service.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/subjects/data/datasources/subject_local_datasource.dart';
import 'package:snapstudy/features/subjects/data/repositories/subject_repository_impl.dart';

void main() {
  late SubjectRepositoryImpl repository;

  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('snapstudy_subjects_test_');
    Hive.init(dir.path);
    HiveService.settingsBox = await Hive.openBox(HiveBoxes.settings);
    HiveService.cacheBox = await Hive.openBox(HiveBoxes.cache);
    HiveService.subjectsBox = await Hive.openBox(HiveBoxes.subjects);
    await HiveService.settingsBox.delete(StorageKeys.subjectsSeeded);

    repository = SubjectRepositoryImpl(SubjectLocalDataSource());
  });

  test('createSubject and getSubjects returns new subject', () async {
    final createResult = await repository.createSubject(
      name: 'Test Subject',
      colorValue: AppColors.primary.toARGB32(),
      iconCodePoint: 0xe24b,
    );

    expect(createResult.isSuccess, true);
    expect(createResult.valueOrNull?.name, 'Test Subject');

    final listResult = await repository.getSubjects();
    expect(listResult.isSuccess, true);
    expect(
      listResult.valueOrNull?.any((s) => s.name == 'Test Subject'),
      true,
    );
  });

  test('deleteSubject soft-deletes subject', () async {
    final createResult = await repository.createSubject(
      name: 'To Delete',
      colorValue: AppColors.primary.toARGB32(),
      iconCodePoint: 0xe24b,
    );
    final id = createResult.valueOrNull!.id;

    final deleteResult = await repository.deleteSubject(id);
    expect(deleteResult.isSuccess, true);

    final listResult = await repository.getSubjects();
    expect(
      listResult.valueOrNull?.any((s) => s.id == id),
      false,
    );
  });
}
