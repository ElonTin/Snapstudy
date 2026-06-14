import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_source.dart';
import 'package:snapstudy/features/weak_areas/presentation/providers/weak_areas_providers.dart';

class WeakAreasSection extends ConsumerWidget {
  const WeakAreasSection({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(sessionWeakAreasProvider(sessionId));
    final insightAsync = ref.watch(sessionWeakAreasInsightProvider(sessionId));

    return itemsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final insight = insightAsync.valueOrNull;
        final advice = insight?.aiAdvice;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSectionHeader(
              title: 'Ôn tập phần còn yếu',
              trailing: AppButton(
                label: insight == null ? 'Phân tích AI' : 'Cập nhật',
                icon: Icons.auto_awesome,
                variant: AppButtonVariant.text,
                isLoading: insightAsync.isLoading,
                onPressed: insightAsync.isLoading
                    ? null
                    : () => ref
                        .read(sessionWeakAreasInsightProvider(sessionId)
                            .notifier)
                        .generate(forceRefresh: true),
              ),
            ),
            const SizedBox(height: 12),
            if (advice != null && advice.isNotEmpty) ...[
              AppCard(
                color: AppColors.secondary.withValues(alpha: 0.1),
                padding: const EdgeInsets.all(14),
                child: Text(
                  advice,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 12),
            ],
            ...items.take(5).map((item) {
              final icon = item.source == WeakAreaSource.flashcard
                  ? Icons.style_outlined
                  : Icons.quiz_outlined;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppConstants.smallRadius),
                        ),
                        child: Icon(icon, size: 18, color: AppColors.warning),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              item.reason,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                AppButton(
                  label: 'Ôn thẻ yếu',
                  icon: Icons.style_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => context.push(
                    RoutePaths.flashcardStudyPath(sessionId, weakOnly: true),
                  ),
                ),
                AppButton(
                  label: 'Làm lại quiz',
                  icon: Icons.quiz_outlined,
                  variant: AppButtonVariant.outline,
                  onPressed: () =>
                      context.push(RoutePaths.quizPlayPath(sessionId)),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.sectionSpacing),
          ],
        );
      },
    );
  }
}
