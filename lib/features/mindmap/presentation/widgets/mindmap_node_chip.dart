import 'package:flutter/material.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_color_utils.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_cluster.dart';
import 'package:snapstudy/features/mindmap/domain/entities/mindmap_node.dart';
import 'package:snapstudy/features/mindmap/domain/services/mindmap_tree_layout.dart';

class MindmapNodeChip extends StatelessWidget {
  const MindmapNodeChip({
    super.key,
    required this.node,
    required this.cluster,
    required this.isCollapsed,
    required this.isRoot,
    required this.onTap,
    this.onToggleCollapse,
  });

  final MindmapNode node;
  final MindmapCluster? cluster;
  final bool isCollapsed;
  final bool isRoot;
  final VoidCallback onTap;
  final VoidCallback? onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final accent = cluster != null
        ? MindmapColorUtils.toColor(cluster!.colorValue)
        : Theme.of(context).colorScheme.primary;

    return Material(
      elevation: isRoot ? 4 : 2,
      shadowColor: accent.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: MindmapTreeLayout.nodeWidth,
          height: MindmapTreeLayout.nodeHeight,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent, width: isRoot ? 2.5 : 1.5),
          ),
          child: Row(
            children: [
              if (node.hasChildren)
                InkWell(
                  onTap: onToggleCollapse,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      isCollapsed
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      size: 18,
                      color: accent,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  node.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight:
                            isRoot ? FontWeight.w700 : FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
