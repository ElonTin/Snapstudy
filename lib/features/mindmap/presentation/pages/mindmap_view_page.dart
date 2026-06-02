import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/features/mindmap/presentation/providers/mindmap_providers.dart';
import 'package:snapstudy/features/mindmap/presentation/widgets/mindmap_canvas.dart';

class MindmapViewPage extends ConsumerStatefulWidget {
  const MindmapViewPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<MindmapViewPage> createState() => _MindmapViewPageState();
}

class _MindmapViewPageState extends ConsumerState<MindmapViewPage> {
  String? _selectedNodeId;

  @override
  Widget build(BuildContext context) {
    final mindmapAsync = ref.watch(sessionMindmapProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Sơ đồ tư duy')),
      body: mindmapAsync.when(
        loading: () => const AppLoading(fullScreen: true),
        error: (e, _) => Center(child: Text('$e')),
        data: (mindmap) {
          if (mindmap == null || !mindmap.isReady) {
            return const Center(child: Text('Chưa có mindmap.'));
          }

          final selected = _selectedNodeId != null
              ? mindmap.nodeById[_selectedNodeId!]
              : mindmap.root;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppConstants.defaultPadding,
                  8,
                  AppConstants.defaultPadding,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mindmap.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    MindmapClusterLegend(mindmap: mindmap),
                    const SizedBox(height: 4),
                    Text(
                      '${mindmap.nodes.length} nút · Chụm ${mindmap.clusters.length} · Pinch để zoom',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: MindmapCanvas(
                  mindmap: mindmap,
                  onNodeSelected: (id) => setState(() => _selectedNodeId = id),
                ),
              ),
              if (selected != null)
                Material(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(AppConstants.defaultPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selected.label,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        if (selected.summary != null &&
                            selected.summary!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(selected.summary!),
                        ],
                        if (selected.hasChildren)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              '${selected.childIds.length} nhánh con',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
