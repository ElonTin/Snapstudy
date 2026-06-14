import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/flashcards/presentation/providers/flashcard_providers.dart';

class FlashcardDeckSection extends ConsumerWidget {
  const FlashcardDeckSection({
    super.key,
    required this.deck,
    this.onRegenerate,
    this.isRegenerating = false,
  });

  final SessionFlashcardDeck deck;
  final VoidCallback? onRegenerate;
  final bool isRegenerating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isMock = ref.watch(useMockFlashcardsProvider);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Flashcard',
            subtitle: deck.title,
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
              'Chế độ mẫu — thêm GEMINI_API_KEY để tạo thẻ từ AI.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${deck.cards.length} thẻ · ${deck.dueCount} cần ôn',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Bắt đầu ôn tập',
            icon: Icons.play_arrow,
            expand: true,
            onPressed: deck.cards.isEmpty
                ? null
                : () => context.push(
                      RoutePaths.reviewQueuePath(sessionId: deck.sessionId),
                    ),
          ),
          const SizedBox(height: 12),
          ...deck.cards.take(3).map(
                (c) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.style_outlined,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c.front,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              c.back,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (deck.cards.length > 3)
            Text(
              '+ ${deck.cards.length - 3} thẻ khác',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }
}
