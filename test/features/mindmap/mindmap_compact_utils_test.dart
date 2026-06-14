import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_compact_utils.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_cluster.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_node.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_status.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';

void main() {
  test('shortenLabel truncates long text', () {
    final long = 'Công thức tính xác suất có điều kiện rất dài';
    expect(
      MindmapCompactUtils.shortenLabel(long).length,
      lessThanOrEqualTo(MindmapCompactUtils.maxLabelLength),
    );
  });

  test('compact limits node count and depth', () {
    final nodes = <MindmapNode>[
      const MindmapNode(id: 'root', label: 'Gốc', childIds: ['a', 'b']),
      const MindmapNode(id: 'a', label: 'A', parentId: 'root', childIds: ['a1']),
      const MindmapNode(id: 'a1', label: 'A1', parentId: 'a', childIds: ['a2']),
      const MindmapNode(id: 'a2', label: 'A2', parentId: 'a1'),
      const MindmapNode(id: 'b', label: 'B', parentId: 'root'),
    ];

    final map = SessionMindmap(
      sessionId: 's',
      title: 'Test',
      rootId: 'root',
      nodes: nodes,
      clusters: const [
        MindmapCluster(id: 'c1', label: 'C', colorValue: 0xFF0000FF),
      ],
      status: MindmapStatus.completed,
      generatedAt: DateTime(2026),
    );

    final compact = MindmapCompactUtils.compact(map);
    expect(compact.nodes.length, lessThanOrEqualTo(MindmapCompactUtils.maxNodes));
  });
}
