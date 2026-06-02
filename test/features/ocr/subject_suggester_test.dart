import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/ocr/domain/services/subject_suggester.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

void main() {
  final subjects = [
    Subject(
      id: 'sub-math',
      name: 'Toán học',
      colorValue: 0xFF0000FF,
      iconCodePoint: 0xe24b,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
    Subject(
      id: 'sub-phys',
      name: 'Vật lý',
      colorValue: 0xFF00FF00,
      iconCodePoint: 0xe24b,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    ),
  ];

  test('suggests subject matching keywords', () {
    final suggestion = SubjectSuggester.suggest(
      keywords: ['toán', 'đạo', 'hàm'],
      subjects: subjects,
    );

    expect(suggestion.subjectId, 'sub-math');
    expect(suggestion.subjectName, 'Toán học');
    expect(suggestion.confidence, greaterThan(0));
  });
}
