import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_color_utils.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_cluster.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_node.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_status.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

abstract final class MockMindmapGenerator {
  static SessionMindmap generate({
    required StudySession session,
    SessionAiSummary? summary,
  }) {
    final topic = summary?.detectedTopic ?? session.title;
    final points = summary?.keyPoints ?? [session.subjectName, session.title];

    const rootId = 'mm_root';
    const cConcept = 'cluster_concepts';
    const cApps = 'cluster_apps';

    final clusters = [
      MindmapCluster(
        id: cConcept,
        label: 'Khái niệm',
        colorValue: MindmapColorUtils.parseColor('#5C6BC0', 0),
      ),
      MindmapCluster(
        id: cApps,
        label: 'Ứng dụng',
        colorValue: MindmapColorUtils.parseColor('#26A69A', 1),
      ),
    ];

    final branchIds = <String>[];
    final nodes = <MindmapNode>[];

    for (var i = 0; i < 3; i++) {
      final id = 'mm_b_$i';
      branchIds.add(id);
      final label = i < points.length
          ? (points[i].length > 36
              ? '${points[i].substring(0, 36)}…'
              : points[i])
          : 'Nhánh ${i + 1}';
      nodes.add(
        MindmapNode(
          id: id,
          label: label,
          parentId: rootId,
          clusterId: i.isEven ? cConcept : cApps,
          summary: i < points.length ? 'Ý ${i + 1}' : null,
          childIds: i == 0 ? ['mm_d_0', 'mm_d_1'] : const [],
        ),
      );
    }

    nodes.addAll([
      MindmapNode(
        id: 'mm_meta',
        label: session.subjectName,
        parentId: rootId,
        clusterId: cConcept,
      ),
      MindmapNode(
        id: 'mm_d_0',
        label: 'Chi tiết A',
        parentId: 'mm_b_0',
        clusterId: cApps,
      ),
      MindmapNode(
        id: 'mm_d_1',
        label: 'Chi tiết B',
        parentId: 'mm_b_0',
        clusterId: cApps,
      ),
      MindmapNode(
        id: rootId,
        label: topic,
        clusterId: cConcept,
        summary: summary?.overview ?? 'Mẫu dev — GEMINI cho mindmap thật',
        childIds: [...branchIds, 'mm_meta'],
      ),
    ]);

    return SessionMindmap(
      sessionId: session.id,
      title: 'Mindmap: $topic',
      rootId: rootId,
      nodes: nodes,
      clusters: clusters,
      status: MindmapStatus.completed,
      generatedAt: DateTime.now(),
      modelName: 'mock-dev',
    );
  }
}
