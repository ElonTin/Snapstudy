import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_question.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';

/// Bottom Sheet hiển thị kết quả sau khi hoàn thành quiz.
/// Cho phép người dùng xem điểm số, câu sai, và điều hướng đến phân tích AI.
Future<_QuizResultAction?> showQuizResultSheet({
  required BuildContext context,
  required QuizScoreResult result,
  required List<QuizQuestion> questions,
  required String sessionId,
}) {
  return showModalBottomSheet<_QuizResultAction>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _QuizResultSheet(
      result: result,
      questions: questions,
      sessionId: sessionId,
    ),
  );
}

enum _QuizResultAction { retryWrong, viewWeakAreas }

// ---------------------------------------------------------------------------

class _QuizResultSheet extends StatelessWidget {
  const _QuizResultSheet({
    required this.result,
    required this.questions,
    required this.sessionId,
  });

  final QuizScoreResult result;
  final List<QuizQuestion> questions;
  final String sessionId;

  @override
  Widget build(BuildContext context) {
    final score = result.scorePercent;
    final wrongAnswers = result.wrongAnswers;
    final wrongQuestions = wrongAnswers
        .map((a) => questions.where((q) => q.id == a.questionId).firstOrNull)
        .whereType<QuizQuestion>()
        .toList();

    final Color scoreColor;
    final IconData scoreIcon;
    final String scoreLabel;

    if (score >= 80) {
      scoreColor = Colors.green.shade600;
      scoreIcon = Icons.emoji_events_rounded;
      scoreLabel = 'Xuất sắc!';
    } else if (score >= 60) {
      scoreColor = AppColors.warning;
      scoreIcon = Icons.thumb_up_alt_rounded;
      scoreLabel = 'Khá tốt!';
    } else {
      scoreColor = Colors.red.shade500;
      scoreIcon = Icons.sentiment_dissatisfied_rounded;
      scoreLabel = 'Cần cải thiện';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppConstants.largeRadius),
            ),
          ),
          child: Column(
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(
                    AppConstants.defaultPadding,
                    8,
                    AppConstants.defaultPadding,
                    AppConstants.defaultPadding,
                  ),
                  children: [
                    // ─── Score Header ──────────────────────────────────────
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: scoreColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(scoreIcon,
                                size: 36, color: scoreColor),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            scoreLabel,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kết quả quiz',
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

                    const SizedBox(height: 20),

                    // ─── Score Stats ───────────────────────────────────────
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          _StatItem(
                            label: 'Điểm số',
                            value: '$score%',
                            color: scoreColor,
                          ),
                          _Divider(),
                          _StatItem(
                            label: 'Đúng',
                            value: '${result.correctCount}',
                            color: Colors.green.shade600,
                          ),
                          _Divider(),
                          _StatItem(
                            label: 'Sai',
                            value:
                                '${result.totalCount - result.correctCount}',
                            color: Colors.red.shade500,
                          ),
                          _Divider(),
                          _StatItem(
                            label: 'Tổng',
                            value: '${result.totalCount}',
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ─── Action Buttons ────────────────────────────────────
                    AppButton(
                      label: 'Xem phân tích điểm yếu AI',
                      icon: Icons.auto_awesome,
                      variant: AppButtonVariant.primary,
                      expand: true,
                      onPressed: () {
                        Navigator.pop(context, _QuizResultAction.viewWeakAreas);
                        context.push(RoutePaths.weakAreasPath(sessionId));
                      },
                    ),

                    if (wrongQuestions.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      AppButton(
                        label: 'Làm lại ${wrongQuestions.length} câu sai',
                        icon: Icons.replay_rounded,
                        variant: AppButtonVariant.outline,
                        expand: true,
                        onPressed: () => Navigator.pop(
                            context, _QuizResultAction.retryWrong),
                      ),
                    ],

                    const SizedBox(height: 10),
                    AppButton(
                      label: 'Đóng',
                      variant: AppButtonVariant.text,
                      expand: true,
                      onPressed: () => Navigator.pop(context),
                    ),

                    // ─── Wrong Answers List ────────────────────────────────
                    if (wrongQuestions.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      AppSectionHeader(
                        title: 'Câu trả lời sai',
                        subtitle: '${wrongQuestions.length} câu cần ôn lại',
                      ),
                      const SizedBox(height: 12),
                      ...wrongQuestions.asMap().entries.map((entry) {
                        final i = entry.key;
                        final q = entry.value;
                        return _WrongAnswerCard(
                          index: i + 1,
                          question: q,
                        );
                      }),
                    ] else ...[
                      const SizedBox(height: 16),
                      AppCard(
                        padding: const EdgeInsets.all(14),
                        color: Colors.green.withValues(alpha: 0.08),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green.shade600),
                            const SizedBox(width: 10),
                            Text(
                              'Không có câu sai — hoàn hảo!',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------

class _StatItem extends StatelessWidget {
  const _StatItem({
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
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}

class _WrongAnswerCard extends StatelessWidget {
  const _WrongAnswerCard({required this.index, required this.question});

  final int index;
  final QuizQuestion question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    question.prompt,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius:
                    BorderRadius.circular(AppConstants.smallRadius),
                border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đáp án: ${question.choices[question.correctIndex]}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            if (question.explanation.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      question.explanation,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
