import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_color_utils.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_compact_utils.dart';
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
    final topic = MindmapCompactUtils.shortenLabel(
      summary?.detectedTopic ?? session.title,
    );
    final points = summary?.keyPoints ?? [session.subjectName];

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
        label: 'Dạng bài',
        colorValue: MindmapColorUtils.parseColor('#26A69A', 1),
      ),
    ];

    final branchLabels = <String>[
      if (points.isNotEmpty) MindmapCompactUtils.shortenLabel(points[0]),
      if (points.length > 1) MindmapCompactUtils.shortenLabel(points[1]),
      MindmapCompactUtils.shortenLabel(session.subjectName),
    ];

    final branchIds = <String>[];
    final nodes = <MindmapNode>[];

    for (var i = 0; i < branchLabels.length; i++) {
      final id = 'mm_b_$i';
      branchIds.add(id);
      nodes.add(
        MindmapNode(
          id: id,
          label: branchLabels[i],
          parentId: rootId,
          clusterId: i.isEven ? cConcept : cApps,
          childIds: i == 0 ? const ['mm_d_0'] : const [],
        ),
      );
    }

    nodes.add(
      MindmapNode(
        id: 'mm_d_0',
        label: 'Ví dụ / công thức',
        parentId: 'mm_b_0',
        clusterId: cApps,
      ),
    );

    nodes.add(
      MindmapNode(
        id: rootId,
        label: topic,
        clusterId: cConcept,
        summary: summary != null
            ? MindmapCompactUtils.shortenLabel(summary.overview)
            : 'Mẫu dev',
        childIds: branchIds,
      ),
    );

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
