import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/mindmap/presentation/providers/mindmap_providers.dart';
import 'package:snapstudy/features/mindmap/presentation/widgets/mindmap_canvas.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_study_timer_provider.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/session_study_timer_chip.dart';

class MindmapViewPage extends ConsumerStatefulWidget {
  const MindmapViewPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<MindmapViewPage> createState() => _MindmapViewPageState();
}

class _MindmapViewPageState extends ConsumerState<MindmapViewPage> {
  final _canvasKey = GlobalKey<MindmapCanvasState>();
  String? _selectedNodeId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      bindSessionStudyTimer(ref, widget.sessionId);
    });
  }

  @override
  void dispose() {
    ref.read(sessionStudyTimerProvider.notifier).detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mindmapAsync = ref.watch(sessionMindmapProvider(widget.sessionId));
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sơ đồ tư duy'),
        actions: [
          mindmapAsync.maybeWhen(
            data: (mindmap) {
              if (mindmap == null || !mindmap.isReady) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToolbarButton(
                      icon: Icons.fit_screen_outlined,
                      tooltip: 'Xem toàn bộ',
                      onPressed: () => _canvasKey.currentState?.fitToView(),
                    ),
                    _ToolbarButton(
                      icon: Icons.copy_outlined,
                      tooltip: 'Sao chép mindmap',
                      onPressed: () {
                        final text = _mindmapAsPlainText(mindmap);
                        Clipboard.setData(ClipboardData(text: text));
                        if (context.mounted) {
                          context.showSnack(
                            'Đã sao chép mindmap — dán vào Notes/Zalo/Telegram',
                          );
                        }
                      },
                    ),
                  ],
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Stack(
        children: [
          mindmapAsync.when(
        loading: () => const AppLoading(fullScreen: true, useSkeleton: true),
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
                child: AppCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  AppColors.aiGradientStart,
                                  AppColors.aiGradientEnd,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.account_tree_outlined,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              mindmap.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      MindmapClusterLegend(mindmap: mindmap),
                      const SizedBox(height: 8),
                      Text(
                        '${mindmap.nodes.length} nút · Chụm ${mindmap.clusters.length} · '
                        'Chụm 2 ngón / chạm đúp để zoom · Kéo để di chuyển',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: MindmapCanvas(
                  key: _canvasKey,
                  mindmap: mindmap,
                  onNodeSelected: (id) => setState(() => _selectedNodeId = id),
                ),
              ),
              if (selected != null)
                AppCard(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  color: colors.surfaceContainerLow,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.radio_button_checked,
                            size: 16,
                            color: colors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              selected.label,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      if (selected.summary != null &&
                          selected.summary!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          selected.summary!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.onSurfaceVariant,
                              ),
                        ),
                      ],
                      if (selected.hasChildren)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primaryContainer.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${selected.childIds.length} nhánh con',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: colors.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
          const Positioned(
            top: 0,
            right: 12,
            child: SafeArea(child: SessionStudyTimerChip()),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, size: 22, color: colors.onSurface),
          ),
        ),
      ),
    );
  }
}

String _mindmapAsPlainText(SessionMindmap mindmap) {
  final lines = <String>[mindmap.title, ''];
  void walk(String id, int depth) {
    final node = mindmap.nodeById[id];
    if (node == null) return;
    lines.add('${'  ' * depth}• ${node.label}');
    for (final child in node.childIds) {
      walk(child, depth + 1);
    }
  }

  walk(mindmap.rootId, 0);
  return lines.join('\n');
}
