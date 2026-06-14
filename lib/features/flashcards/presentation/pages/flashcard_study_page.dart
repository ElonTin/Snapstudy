import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_empty_state.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/review_rating.dart';
import 'package:snapstudy/features/flashcards/presentation/providers/flashcard_providers.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_study_timer_provider.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/session_study_timer_chip.dart';
import 'package:snapstudy/features/weak_areas/data/datasources/weak_areas_local_datasource.dart';
import 'package:snapstudy/features/weak_areas/domain/services/weak_areas_analyzer.dart';

/// Flip-card study mode for a session deck (Phase 10).

class FlashcardStudyPage extends ConsumerStatefulWidget {
  const FlashcardStudyPage({
    super.key,
    required this.sessionId,
    this.weakOnly = false,
  });

  final String sessionId;
  final bool weakOnly;

  @override
  ConsumerState<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends ConsumerState<FlashcardStudyPage> {
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

  var _index = 0;
  var _showBack = false;
  var _isSubmitting = false;

  // Thống kê những thẻ đã ôn trong phiên này
  var _againCount = 0;
  var _hardCount = 0;
  var _goodCount = 0;
  var _easyCount = 0;
  var _totalRated = 0;
  var _hasShownSummary = false;

  List<Flashcard> _studyCards(List<Flashcard> all) {
    if (widget.weakOnly) {
      final weakIds = WeakAreasAnalyzer.analyzeCards(
        all,
      ).map((w) => w.referenceId).whereType<String>().toSet();
      return all.where((c) => weakIds.contains(c.id)).toList();
    }
    return all.where((c) => c.isDue).toList();
  }

  Future<void> _rate(ReviewRating rating) async {
    final deckAsync = ref.read(sessionFlashcardDeckProvider(widget.sessionId));
    final deck = deckAsync.valueOrNull;
    if (deck == null) return;

    final study = _studyCards(deck.cards);
    if (_index >= study.length) return;

    setState(() => _isSubmitting = true);
    final card = study[_index];

    await ref
        .read(flashcardRepositoryProvider)
        .recordReview(
          sessionId: widget.sessionId,
          cardId: card.id,
          rating: rating,
        );

    // Cập nhật thống kê phiên
    _totalRated++;
    switch (rating) {
      case ReviewRating.again:
        _againCount++;
      case ReviewRating.hard:
        _hardCount++;
      case ReviewRating.good:
        _goodCount++;
      case ReviewRating.easy:
        _easyCount++;
    }

    ref.invalidate(sessionFlashcardDeckProvider(widget.sessionId));
    await WeakAreasLocalDataSource().delete(widget.sessionId);

    final isLastCard = _index >= study.length - 1;

    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showBack = false;
        if (!isLastCard) {
          _index++;
        } else {
          _index = 0;
        }
      });

      if (isLastCard && !_hasShownSummary && _totalRated > 0) {
        _hasShownSummary = true;
        await _showSessionSummary();
      } else {
        context.showSnack('Đã lưu tiến độ ôn tập');
      }
    }
  }

  Future<void> _showSessionSummary() async {
    if (!mounted) return;
    final weakCount = _againCount + _hardCount;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _FlashcardSummarySheet(
        sessionId: widget.sessionId,
        totalRated: _totalRated,
        againCount: _againCount,
        hardCount: _hardCount,
        goodCount: _goodCount,
        easyCount: _easyCount,
        weakCount: weakCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deckAsync = ref.watch(sessionFlashcardDeckProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.weakOnly ? 'Ôn thẻ yếu' : 'Ôn flashcard'),
      ),
      body: Stack(
        children: [
          deckAsync.when(
            loading: () =>
                const AppLoading(fullScreen: true, useSkeleton: true),
            error: (e, _) => Center(child: Text('$e')),
            data: (deck) {
              if (deck == null || deck.cards.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.style_outlined,
                  title: 'Chưa có bộ flashcard',
                  subtitle: 'Tạo flashcard từ buổi học để bắt đầu ôn tập.',
                );
              }

              final study = _studyCards(deck.cards);
              if (study.isEmpty) {
                return AppEmptyState(
                  icon: Icons.celebration_outlined,
                  title: widget.weakOnly
                      ? 'Không còn thẻ yếu — tuyệt vời!'
                      : 'Đã ôn hết thẻ đến hạn!',
                  subtitle: 'Quay lại khi có thẻ mới cần ôn.',
                  action: AppButton(
                    label: 'Quay lại',
                    variant: AppButtonVariant.primary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                );
              }

              final card = study[_index.clamp(0, study.length - 1)];
              final progress = (_index + 1) / study.length;

              return Padding(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  children: [
                    AppCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Thẻ ${_index + 1} / ${study.length}',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Spacer(),
                              Text(
                                '${(progress * 100).round()}%',
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progress,
                              minHeight: 6,
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _showBack = !_showBack),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeInOut,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
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
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.18,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _showBack ? 'MẶT SAU' : 'MẶT TRƯỚC',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: Colors.white70,
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _showBack ? card.back : card.front,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        height: 1.35,
                                      ),
                                ),
                                if (card.hint != null && !_showBack) ...[
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Gợi ý: ${card.hint}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: Colors.white70),
                                    ),
                                  ),
                                ],
                                const Spacer(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _showBack ? 'Chạm để xem mặt trước' : 'Chạm để lật thẻ',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_showBack)
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Chưa thuộc',
                                  variant: AppButtonVariant.outline,
                                  expand: true,
                                  isLoading: _isSubmitting,
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _rate(ReviewRating.again),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppButton(
                                  label: 'Khó',
                                  variant: AppButtonVariant.outline,
                                  expand: true,
                                  isLoading: _isSubmitting,
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _rate(ReviewRating.hard),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Thuộc',
                                  variant: AppButtonVariant.primary,
                                  expand: true,
                                  isLoading: _isSubmitting,
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _rate(ReviewRating.good),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppButton(
                                  label: 'Dễ',
                                  variant: AppButtonVariant.secondary,
                                  expand: true,
                                  isLoading: _isSubmitting,
                                  onPressed: _isSubmitting
                                      ? null
                                      : () => _rate(ReviewRating.easy),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
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

// ---------------------------------------------------------------------------
// Flashcard Session Summary Bottom Sheet
// ---------------------------------------------------------------------------

class _FlashcardSummarySheet extends StatelessWidget {
  const _FlashcardSummarySheet({
    required this.sessionId,
    required this.totalRated,
    required this.againCount,
    required this.hardCount,
    required this.goodCount,
    required this.easyCount,
    required this.weakCount,
  });

  final String sessionId;
  final int totalRated;
  final int againCount;
  final int hardCount;
  final int goodCount;
  final int easyCount;
  final int weakCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Color headerColor;
    final IconData headerIcon;
    final String headerTitle;

    if (weakCount == 0) {
      headerColor = Colors.green.shade600;
      headerIcon = Icons.emoji_events_rounded;
      headerTitle = 'Tuyệt vời! Không có thẻ yếu';
    } else if (weakCount <= totalRated ~/ 3) {
      headerColor = AppColors.warning;
      headerIcon = Icons.thumb_up_alt_rounded;
      headerTitle = 'Khá tốt! Còn $weakCount thẻ cần ôn';
    } else {
      headerColor = Colors.red.shade500;
      headerIcon = Icons.sentiment_dissatisfied_rounded;
      headerTitle = 'Còn $weakCount thẻ chưa thuộc';
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppConstants.largeRadius),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        12,
        AppConstants.defaultPadding,
        AppConstants.defaultPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header icon + title
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(headerIcon, size: 32, color: headerColor),
          ),
          const SizedBox(height: 12),
          Text(
            headerTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Đã ôn $totalRated thẻ trong phiên này',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 20),

          // Stats row
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Row(
              children: [
                _StatCell(
                  label: 'Chưa thuộc',
                  value: '$againCount',
                  color: Colors.red.shade500,
                ),
                _StatCell(
                  label: 'Khó',
                  value: '$hardCount',
                  color: AppColors.warning,
                ),
                _StatCell(
                  label: 'Thuộc',
                  value: '$goodCount',
                  color: Colors.blue.shade500,
                ),
                _StatCell(
                  label: 'Dễ',
                  value: '$easyCount',
                  color: Colors.green.shade600,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          if (weakCount > 0) ...[
            AppButton(
              label: 'Xem phân tích điểm yếu AI',
              icon: Icons.auto_awesome,
              variant: AppButtonVariant.primary,
              expand: true,
              onPressed: () {
                Navigator.pop(context);
                context.push(RoutePaths.weakAreasPath(sessionId));
              },
            ),
            const SizedBox(height: 10),
            AppButton(
              label: 'Ôn lại thẻ yếu ngay',
              icon: Icons.style_outlined,
              variant: AppButtonVariant.outline,
              expand: true,
              onPressed: () {
                Navigator.pop(context);
                context.push(
                  RoutePaths.flashcardStudyPath(sessionId, weakOnly: true),
                );
              },
            ),
          ] else ...[
            AppButton(
              label: 'Làm quiz để kiểm tra',
              icon: Icons.quiz_outlined,
              variant: AppButtonVariant.primary,
              expand: true,
              onPressed: () {
                Navigator.pop(context);
                context.push(RoutePaths.quizPlayPath(sessionId));
              },
            ),
          ],

          const SizedBox(height: 10),
          AppButton(
            label: 'Đóng',
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
