import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
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
                const Icon(Icons.style_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Flashcard',
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
                'Chế độ mẫu — thêm GEMINI_API_KEY để tạo thẻ từ AI.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              deck.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${deck.cards.length} thẻ · ${deck.dueCount} cần ôn',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: deck.cards.isEmpty
                    ? null
                    : () => context.push(
                          RoutePaths.reviewQueuePath(sessionId: deck.sessionId),
                        ),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Bắt đầu ôn tập'),
              ),
            ),
            const SizedBox(height: 12),
            ...deck.cards.take(3).map(
                  (c) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      c.front,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      c.back,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            if (deck.cards.length > 3)
              Text(
                '+ ${deck.cards.length - 3} thẻ khác',
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }
}
