import 'package:snapstudy/features/mindmap/domain/entities/mindmap_node.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';

/// Rút gọn nhãn và giới hạn độ sâu cây mindmap.
abstract final class MindmapCompactUtils {
  MindmapCompactUtils._();

  static const maxLabelLength = 28;
  static const maxSummaryLength = 72;
  static const maxNodes = 12;
  static const maxDepth = 3;

  static String shortenLabel(String text) {
    final t = text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (t.length <= maxLabelLength) return t;
    return '${t.substring(0, maxLabelLength - 1)}…';
  }

  static SessionMindmap compact(SessionMindmap mindmap) {
    final nodeMap = {for (final n in mindmap.nodes) n.id: n};
    final root = nodeMap[mindmap.rootId];
    if (root == null) return mindmap;

    final keptIds = <String>{};
    void walk(String id, int depth) {
      if (keptIds.length >= maxNodes) return;
      if (depth > maxDepth) return;
      keptIds.add(id);
      final node = nodeMap[id];
      if (node == null) return;
      for (final childId in node.childIds) {
        walk(childId, depth + 1);
      }
    }

    walk(mindmap.rootId, 0);

    final compactNodes = mindmap.nodes
        .where((n) => keptIds.contains(n.id))
        .map((n) {
          final children =
              n.childIds.where((id) => keptIds.contains(id)).toList();
          return MindmapNode(
            id: n.id,
            label: shortenLabel(n.label),
            parentId: n.parentId != null && keptIds.contains(n.parentId)
                ? n.parentId
                : (n.id == mindmap.rootId ? null : n.parentId),
            clusterId: n.clusterId,
            summary: n.summary != null
                ? _shortenSummary(n.summary!)
                : null,
            childIds: children,
          );
        })
        .toList();

    return SessionMindmap(
      sessionId: mindmap.sessionId,
      title: shortenLabel(mindmap.title),
      rootId: mindmap.rootId,
      nodes: compactNodes,
      clusters: mindmap.clusters,
      status: mindmap.status,
      generatedAt: mindmap.generatedAt,
      modelName: mindmap.modelName,
      errorMessage: mindmap.errorMessage,
    );
  }

  static String _shortenSummary(String text) {
    final t = text.trim();
    if (t.length <= maxSummaryLength) return t;
    return '${t.substring(0, maxSummaryLength - 1)}…';
  }
}
