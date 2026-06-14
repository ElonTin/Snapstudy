import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Quiz trắc nghiệm',
            subtitle: quiz.title,
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
              'Chế độ mẫu — thêm GEMINI_API_KEY để tạo quiz từ AI.',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            '${quiz.questions.length} câu · ${quiz.defaultDifficulty.label}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
          ),
          if (last != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Lần làm gần nhất: ${last.scorePercent}% '
                '(${last.correctCount}/${last.totalCount}) · ${last.difficulty.label}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          AppButton(
            label: last != null ? 'Làm lại quiz' : 'Bắt đầu quiz',
            icon: Icons.play_circle_outline,
            expand: true,
            onPressed: quiz.questions.isEmpty
                ? null
                : () => context.push(RoutePaths.quizPlayPath(quiz.sessionId)),
          ),
        ],
      ),
    );
  }
}
