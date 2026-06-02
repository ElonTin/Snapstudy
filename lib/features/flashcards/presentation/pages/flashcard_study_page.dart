import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/flashcards/presentation/providers/flashcard_providers.dart';

/// Flip-card study mode for a session deck (Phase 10).
class FlashcardStudyPage extends ConsumerStatefulWidget {
  const FlashcardStudyPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends ConsumerState<FlashcardStudyPage> {
  var _index = 0;
  var _showBack = false;
  var _isSubmitting = false;

  List<Flashcard> _dueCards(List<Flashcard> all) =>
      all.where((c) => c.isDue).toList();

  Future<void> _rate(ReviewRating rating) async {
    final deckAsync = ref.read(sessionFlashcardDeckProvider(widget.sessionId));
    final deck = deckAsync.valueOrNull;
    if (deck == null) return;

    final due = _dueCards(deck.cards);
    if (_index >= due.length) return;

    setState(() => _isSubmitting = true);
    final card = due[_index];

    await ref.read(flashcardRepositoryProvider).recordReview(
          sessionId: widget.sessionId,
          cardId: card.id,
          rating: rating,
        );

    ref.invalidate(sessionFlashcardDeckProvider(widget.sessionId));

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showBack = false;
        if (_index < due.length - 1) {
          _index++;
        } else {
          _index = 0;
        }
      });
      context.showSnack('Đã lưu tiến độ ôn tập');
    }
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(sessionFlashcardDeckProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ôn flashcard')),
      body: deckAsync.when(
        loading: () => const AppLoading(fullScreen: true),
        error: (e, _) => Center(child: Text('$e')),
        data: (deck) {
          if (deck == null || deck.cards.isEmpty) {
            return const Center(child: Text('Chưa có bộ flashcard.'));
          }

          final due = _dueCards(deck.cards);
          if (due.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.celebration_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'Đã ôn hết thẻ đến hạn!',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final card = due[_index.clamp(0, due.length - 1)];
          final progress = (_index + 1) / due.length;

          return Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              children: [
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 8),
                Text(
                  'Thẻ ${_index + 1} / ${due.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _showBack = !_showBack),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _showBack
                              ? [
                                  AppColors.aiGradientEnd,
                                  AppColors.aiGradientStart,
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.aiGradientStart,
                                ],
                        ),
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultRadius,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _showBack ? card.back : card.front,
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (card.hint != null && !_showBack) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Gợi ý: ${card.hint}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _showBack ? 'Chạm để xem mặt trước' : 'Chạm để lật thẻ',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                const SizedBox(height: 16),
                if (_showBack)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _rate(ReviewRating.again),
                          child: const Text('Chưa thuộc'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _rate(ReviewRating.good),
                          child: const Text('Thuộc'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.tonal(
                          onPressed: _isSubmitting
                              ? null
                              : () => _rate(ReviewRating.easy),
                          child: const Text('Dễ'),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
