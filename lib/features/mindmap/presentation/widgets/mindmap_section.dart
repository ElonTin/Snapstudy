import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Mindmap',
            subtitle: mindmap.title,
            trailing: onRegenerate != null
                ? AppButton(
                    label: isRegenerating ? 'Đang tạo...' : 'Tạo lại',
                    icon: Icons.refresh,
                    variant: AppButtonVariant.text,
                    isLoading: isRegenerating,
                    onPressed: isRegenerating ? null : onRegenerate,
                  )
                : null,
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
            '${mindmap.nodes.length} nút · ${mindmap.clusters.length} cụm chủ đề',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Mở sơ đồ tư duy',
            icon: Icons.open_in_full,
            expand: true,
            onPressed: () =>
                context.push(RoutePaths.mindmapViewPath(mindmap.sessionId)),
          ),
        ],
      ),
    );
  }
}
