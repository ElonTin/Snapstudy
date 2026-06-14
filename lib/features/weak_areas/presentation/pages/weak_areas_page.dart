import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_source.dart';
import 'package:snapstudy/features/weak_areas/presentation/providers/weak_areas_providers.dart';

/// Màn hình phân tích điểm yếu đầy đủ — hiển thị sau khi quiz/flashcard kết thúc.
class WeakAreasPage extends ConsumerWidget {
  const WeakAreasPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Auto-trigger AI nếu chưa có insight
    ref.watch(autoTriggerWeakAreasProvider(sessionId));

    final itemsAsync = ref.watch(sessionWeakAreasProvider(sessionId));
    final insightAsync = ref.watch(sessionWeakAreasInsightProvider(sessionId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Phân tích điểm yếu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Phân tích lại',
            onPressed: insightAsync.isLoading
                ? null
                : () => ref
                    .read(sessionWeakAreasInsightProvider(sessionId).notifier)
                    .generate(forceRefresh: true),
          ),
        ],
      ),
      body: itemsAsync.when(
        loading: () => const AppLoading(fullScreen: true, useSkeleton: true),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(sessionId: sessionId);
          }
          return _WeakAreasContent(
            sessionId: sessionId,
            items: items,
            insightAsync: insightAsync,
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _WeakAreasContent extends ConsumerWidget {
  const _WeakAreasContent({
    required this.sessionId,
    required this.items,
    required this.insightAsync,
  });

  final String sessionId;
  final List<WeakAreaItem> items;
  final AsyncValue insightAsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insight = insightAsync.valueOrNull;
    final isLoading = insightAsync.isLoading;
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      children: [
        // ─── AI Advice Card ────────────────────────────────────────────────
        if (isLoading) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.aiGradientStart.withValues(alpha: 0.15),
                  AppColors.aiGradientEnd.withValues(alpha: 0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
              border: Border.all(
                color: AppColors.aiGradientStart.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Text(
                  'AI đang phân tích điểm yếu…',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ] else if (insight?.aiAdvice != null &&
            insight!.aiAdvice.isNotEmpty) ...[
          _AiAdviceCard(advice: insight.aiAdvice),
        ] else ...[
          _AiAdviceCard(
            advice:
                'Bạn còn ${items.length} phần cần ôn tập. Hãy ôn thẻ yếu và làm lại quiz để cải thiện.',
            isFallback: true,
          ),
          const SizedBox(height: 8),
          AppButton(
            label: 'Phân tích bằng AI',
            icon: Icons.auto_awesome,
            variant: AppButtonVariant.outline,
            onPressed: () => ref
                .read(sessionWeakAreasInsightProvider(sessionId).notifier)
                .generate(),
          ),
        ],

        const SizedBox(height: 24),

        // ─── Action Buttons ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: 'Ôn thẻ yếu',
                icon: Icons.style_outlined,
                variant: AppButtonVariant.primary,
                expand: true,
                onPressed: () => context.push(
                  RoutePaths.flashcardStudyPath(sessionId, weakOnly: true),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AppButton(
                label: 'Làm lại quiz',
                icon: Icons.quiz_outlined,
                variant: AppButtonVariant.secondary,
                expand: true,
                onPressed: () =>
                    context.push(RoutePaths.quizPlayPath(sessionId)),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ─── Weak Area List ─────────────────────────────────────────────────
        AppSectionHeader(
          title: 'Các phần cần ôn tập',
          subtitle: '${items.length} mục được phát hiện',
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _WeakAreaCard(item: item)),
        const SizedBox(height: AppConstants.sectionSpacing),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _AiAdviceCard extends StatelessWidget {
  const _AiAdviceCard({required this.advice, this.isFallback = false});

  final String advice;
  final bool isFallback;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isFallback
              ? [
                  AppColors.warning.withValues(alpha: 0.1),
                  AppColors.warning.withValues(alpha: 0.05),
                ]
              : [
                  AppColors.aiGradientStart.withValues(alpha: 0.15),
                  AppColors.aiGradientEnd.withValues(alpha: 0.15),
                ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(
          color: isFallback
              ? AppColors.warning.withValues(alpha: 0.3)
              : AppColors.aiGradientStart.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isFallback
                  ? AppColors.warning.withValues(alpha: 0.15)
                  : AppColors.aiGradientStart.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFallback ? Icons.info_outline : Icons.auto_awesome,
              size: 18,
              color: isFallback ? AppColors.warning : AppColors.aiGradientStart,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFallback ? 'Gợi ý ôn tập' : 'Phân tích từ AI',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isFallback
                            ? AppColors.warning
                            : AppColors.aiGradientStart,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  advice,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _WeakAreaCard extends StatelessWidget {
  const _WeakAreaCard({required this.item});

  final WeakAreaItem item;

  @override
  Widget build(BuildContext context) {
    final isQuiz = item.source == WeakAreaSource.quiz;
    final icon =
        isQuiz ? Icons.quiz_outlined : Icons.style_outlined;
    final color = isQuiz ? AppColors.secondary : AppColors.warning;

    // Priority badge color
    Color priorityColor;
    String priorityLabel;
    if (item.priorityScore >= 80) {
      priorityColor = Colors.red.shade600;
      priorityLabel = 'Cao';
    } else if (item.priorityScore >= 50) {
      priorityColor = AppColors.warning;
      priorityLabel = 'Trung bình';
    } else {
      priorityColor = Colors.green.shade600;
      priorityLabel = 'Thấp';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon source
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius:
                    BorderRadius.circular(AppConstants.smallRadius),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Priority badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          priorityLabel,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: priorityColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.reason,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (item.sessionTitle != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.sessionTitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration_outlined,
              size: 64,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Không có điểm yếu!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bạn đang học tốt. Hãy tiếp tục làm quiz và ôn flashcard để duy trì.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Làm quiz',
              icon: Icons.quiz_outlined,
              variant: AppButtonVariant.primary,
              onPressed: () =>
                  context.push(RoutePaths.quizPlayPath(sessionId)),
            ),
          ],
        ),
      ),
    );
  }
}
