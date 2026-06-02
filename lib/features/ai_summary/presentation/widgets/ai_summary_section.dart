import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/features/ai_summary/presentation/providers/ai_summary_providers.dart';
import 'package:snapstudy/features/home/presentation/utils/dashboard_formatters.dart';

class AiSummarySection extends ConsumerWidget {
  const AiSummarySection({
    super.key,
    required this.summary,
    this.onRegenerate,
    this.isRegenerating = false,
  });

  final SessionAiSummary summary;
  final VoidCallback? onRegenerate;
  final bool isRegenerating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isMock = ref.watch(useMockAiSummaryProvider);

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
                const Icon(
                  Icons.auto_awesome,
                  color: AppColors.aiGradientStart,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tóm tắt AI',
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
              MaterialBanner(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: colors.tertiaryContainer,
                content: Text(
                  EnvConfig.isGeminiConfigured
                      ? 'Tóm tắt mẫu cũ — nhấn «Tạo lại» để gọi Gemini.'
                      : 'Chế độ mẫu — thêm GEMINI_API_KEY vào .env, rồi chạy lại app (flutter run).',
                  style: const TextStyle(fontSize: 12),
                ),
                leading: Icon(Icons.info_outline, color: colors.onTertiaryContainer),
                actions: const [SizedBox.shrink()],
              ),
            ],
            const SizedBox(height: 12),
            _TopicChip(topic: summary.detectedTopic),
            const SizedBox(height: 12),
            Text(
              summary.overview,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'Ý chính',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...summary.keyPoints.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tóm tắt gạch đầu dòng',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ...summary.bulletSummary.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(b)),
                  ],
                ),
              ),
            ),
            if (summary.topics.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: summary.topics
                    .map(
                      (t) => Chip(
                        label: Text(t),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Tạo lúc ${DashboardFormatters.relativeTime(summary.generatedAt)}'
              '${summary.modelName != null ? ' · ${summary.modelName}' : ''}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicChip extends StatelessWidget {
  const _TopicChip({required this.topic});

  final String topic;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.aiGradientStart, AppColors.aiGradientEnd],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        topic,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
