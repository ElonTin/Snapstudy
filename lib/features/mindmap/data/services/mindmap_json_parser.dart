import 'dart:convert';

import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_color_utils.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_compact_utils.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_cluster.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_node.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_status.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';

/// Parses and validates structured mindmap graph JSON from AI.
abstract final class MindmapJsonParser {
  static const _minNodes = 4;
  static const _maxNodes = 14;

  static Result<SessionMindmap> parse({
    required String sessionId,
    required String rawJson,
    String? modelName,
  }) {
    try {
      var text = rawJson.trim();
      if (text.startsWith('```')) {
        text = text
            .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim();
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        return const Error(
          ValidationFailure('Phản hồi mindmap không phải JSON object.'),
        );
      }

      final title = decoded['title'];
      if (title is! String || title.trim().isEmpty) {
        return const Error(ValidationFailure('Thiếu trường "title".'));
      }

      final rootId = decoded['rootId'];
      if (rootId is! String || rootId.trim().isEmpty) {
        return const Error(ValidationFailure('Thiếu trường "rootId".'));
      }

      final nodesRaw = decoded['nodes'];
      if (nodesRaw is! List || nodesRaw.isEmpty) {
        return const Error(ValidationFailure('Cần mảng "nodes".'));
      }

      final clustersRaw = decoded['clusters'];
      final clusters = <MindmapCluster>[];
      if (clustersRaw is List) {
        for (var i = 0; i < clustersRaw.length && i < 8; i++) {
          final item = clustersRaw[i];
          if (item is! Map<String, dynamic>) continue;
          final id = item['id'];
          final label = item['label'];
          if (id is! String || label is! String) continue;
          if (id.trim().isEmpty || label.trim().isEmpty) continue;
          clusters.add(
            MindmapCluster(
              id: id.trim(),
              label: label.trim(),
              colorValue: MindmapColorUtils.parseColor(
                item['color'] as String?,
                i,
              ),
            ),
          );
        }
      }

      final nodes = <MindmapNode>[];
      final ids = <String>{};

      for (var i = 0; i < nodesRaw.length && i < _maxNodes; i++) {
        final item = nodesRaw[i];
        if (item is! Map<String, dynamic>) continue;

        final id = item['id'];
        final label = item['label'];
        if (id is! String || label is! String) continue;
        if (id.trim().isEmpty || label.trim().isEmpty) continue;
        if (ids.contains(id.trim())) continue;
        ids.add(id.trim());

        final parentId = item['parentId'];
        final clusterId = item['clusterId'];
        final summary = item['summary'];

        nodes.add(
          MindmapNode(
            id: id.trim(),
            label: MindmapCompactUtils.shortenLabel(label),
            parentId: parentId is String && parentId.trim().isNotEmpty
                ? parentId.trim()
                : null,
            clusterId: clusterId is String && clusterId.trim().isNotEmpty
                ? clusterId.trim()
                : null,
            summary: summary is String && summary.trim().isNotEmpty
                ? summary.trim()
                : null,
            childIds: const [],
          ),
        );
      }

      if (nodes.length < _minNodes) {
        return Error(
          ValidationFailure('Cần ít nhất $_minNodes node hợp lệ.'),
        );
      }

      if (!ids.contains(rootId.trim())) {
        return const Error(ValidationFailure('rootId không khớp node nào.'));
      }

      final linked = _linkChildren(nodes);
      final nodeMap = {for (final n in linked) n.id: n};

      final root = nodeMap[rootId.trim()]!;
      if (root.parentId != null) {
        return const Error(
          ValidationFailure('Node gốc không được có parentId.'),
        );
      }

      if (!_isConnectedTree(nodeMap, rootId.trim())) {
        return const Error(
          ValidationFailure('Đồ thị phải là cây liên thông từ root.'),
        );
      }

      final raw = SessionMindmap(
        sessionId: sessionId,
        title: MindmapCompactUtils.shortenLabel(title),
        rootId: rootId.trim(),
        nodes: linked,
        clusters: clusters,
        status: MindmapStatus.completed,
        generatedAt: DateTime.now(),
        modelName: modelName,
      );

      return Success(MindmapCompactUtils.compact(raw));
    } catch (e) {
      return Error(ValidationFailure('JSON mindmap không hợp lệ: $e'));
    }
  }

  static List<MindmapNode> _linkChildren(List<MindmapNode> nodes) {
    final childrenMap = <String, List<String>>{};
    for (final n in nodes) {
      final parentId = n.parentId;
      if (parentId == null) continue;
      childrenMap.putIfAbsent(parentId, () => []).add(n.id);
    }
    return nodes
        .map(
          (n) => MindmapNode(
            id: n.id,
            label: n.label,
            parentId: n.parentId,
            clusterId: n.clusterId,
            summary: n.summary,
            childIds: childrenMap[n.id] ?? const [],
          ),
        )
        .toList();
  }

  static bool _isConnectedTree(Map<String, MindmapNode> map, String rootId) {
    final visited = <String>{};
    void dfs(String id) {
      if (visited.contains(id)) return;
      visited.add(id);
      final node = map[id];
      if (node == null) return;
      for (final childId in node.childIds) {
        dfs(childId);
      }
    }

    dfs(rootId);
    return visited.length == map.length;
  }
}
