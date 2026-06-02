import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/mindmap/data/services/mock_mindmap_generator.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

void main() {
  test('mock mindmap is ready tree', () {
    final session = StudySession(
      id: 's1',
      subjectId: 'sub',
      subjectName: 'Toán',
      subjectColorValue: 0xFF2196F3,
      title: 'Buổi 1',
      startedAt: DateTime(2025, 1, 1),
      status: SessionStatus.completed,
    );

    final map = MockMindmapGenerator.generate(session: session);
    expect(map.isReady, isTrue);
    expect(map.nodes.length, greaterThanOrEqualTo(4));
    expect(map.root?.childIds, isNotEmpty);
    expect(map.clusters.length, 2);
  });
}
