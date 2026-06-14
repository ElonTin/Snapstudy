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
    this.nodeWidth = MindmapTreeLayout.nodeWidth,
    this.nodeHeight = MindmapTreeLayout.nodeHeight,
  });

  final MindmapNode node;
  final MindmapCluster? cluster;
  final bool isCollapsed;
  final bool isRoot;
  final VoidCallback onTap;
  final VoidCallback? onToggleCollapse;
  final double nodeWidth;
  final double nodeHeight;

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
          width: nodeWidth,
          height: nodeHeight,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent, width: isRoot ? 2.5 : 1.5),
          ),
          clipBehavior: Clip.hardEdge,
          child: Row(
            children: [
              if (node.hasChildren)
                SizedBox(
                  width: 22,
                  child: InkWell(
                    onTap: onToggleCollapse,
                    borderRadius: BorderRadius.circular(8),
                    child: Icon(
                      isCollapsed
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      size: 16,
                      color: accent,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  node.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight:
                            isRoot ? FontWeight.w700 : FontWeight.w600,
                        height: 1.15,
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
