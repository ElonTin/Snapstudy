import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/mindmap/data/services/mock_mindmap_generator.dart';
import 'package:snapstudy/features/mindmap/domain/services/mindmap_tree_layout.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

void main() {
  test('layout respects collapsed nodes', () {
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
    final full = MindmapTreeLayout.compute(
      mindmap: map,
      collapsedIds: {},
    );
    final collapsed = MindmapTreeLayout.compute(
      mindmap: map,
      collapsedIds: {map.rootId},
    );
    expect(full.nodes.length, greaterThan(collapsed.nodes.length));
    expect(collapsed.edges, isEmpty);
  });
}
