import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/mindmap/presentation/providers/mindmap_providers.dart';

class MindmapSection extends ConsumerWidget {
  const MindmapSection({
    super.key,
    required this.mindmap,
    this.onRegenerate,
    this.isRegenerating = false,
  });

  final SessionMindmap mindmap;
  final VoidCallback? onRegenerate;
  final bool isRegenerating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isMock = ref.watch(useMockMindmapProvider);

    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_tree_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mindmap',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                if (onRegenerate != null)
                  TextButton.icon(
                    onPressed: isRegenerating ? null : onRegenerate,
                    icon: isRegenerating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 18),
                    label: Text(isRegenerating ? 'Đang tạo...' : 'Tạo lại'),
                  ),
              ],
            ),
            if (isMock) ...[
              const SizedBox(height: 8),
              Text(
                'Chế độ mẫu — thêm GEMINI_API_KEY để tạo sơ đồ từ AI.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              mindmap.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${mindmap.nodes.length} nút · ${mindmap.clusters.length} cụm chủ đề',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () =>
                    context.push(RoutePaths.mindmapViewPath(mindmap.sessionId)),
                icon: const Icon(Icons.open_in_full),
                label: const Text('Mở sơ đồ tư duy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
