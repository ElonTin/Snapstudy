import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/quiz/presentation/providers/quiz_providers.dart';

class QuizSection extends ConsumerWidget {
  const QuizSection({
    super.key,
    required this.quiz,
    this.onRegenerate,
    this.isRegenerating = false,
  });

  final SessionQuiz quiz;
  final VoidCallback? onRegenerate;
  final bool isRegenerating;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isMock = ref.watch(useMockQuizProvider);
    final last = quiz.lastResult;

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
                const Icon(Icons.quiz_outlined, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Quiz trắc nghiệm',
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
                'Chế độ mẫu — thêm GEMINI_API_KEY để tạo quiz từ AI.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Text(
              '${quiz.questions.length} câu · ${quiz.defaultDifficulty.label}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            if (last != null) ...[
              const SizedBox(height: 8),
              Text(
                'Lần làm gần nhất: ${last.scorePercent}% (${last.correctCount}/${last.totalCount}) · ${last.difficulty.label}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: quiz.questions.isEmpty
                    ? null
                    : () => context.push(RoutePaths.quizPlayPath(quiz.sessionId)),
                icon: const Icon(Icons.play_circle_outline),
                label: Text(last != null ? 'Làm lại quiz' : 'Bắt đầu quiz'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
