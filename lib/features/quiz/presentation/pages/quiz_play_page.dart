import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_answer_record.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/weak_areas/data/datasources/weak_areas_local_datasource.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_question.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:snapstudy/features/quiz/presentation/widgets/quiz_result_sheet.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_study_timer_provider.dart';
import 'package:snapstudy/features/sessions/presentation/widgets/session_study_timer_chip.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  const QuizPlayPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
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

  QuizDifficulty? _difficulty;
  List<QuizQuestion> _questions = [];
  var _index = 0;
  int? _selectedIndex;
  var _correctCount = 0;
  var _isSaving = false;
  final _answers = <QuizAnswerRecord>[];

  void _startQuiz(SessionQuiz quiz, QuizDifficulty level) {
    final filtered = quiz.questionsForDifficulty(level);
    if (filtered.isEmpty) {
      context.showSnack('Không có câu phù hợp mức độ này');
      return;
    }
    setState(() {
      _difficulty = level;
      _questions = filtered;
      _index = 0;
      _selectedIndex = null;
      _correctCount = 0;
      _answers.clear();
    });
  }

  /// Làm lại chỉ các câu sai từ lần vừa xong.
  void _retryWrongAnswers(List<QuizQuestion> allQuestions) {
    final wrongIds = _answers
        .where((a) => !a.isCorrect)
        .map((a) => a.questionId)
        .toSet();
    final wrongQuestions =
        allQuestions.where((q) => wrongIds.contains(q.id)).toList();
    if (wrongQuestions.isEmpty) return;
    setState(() {
      _questions = wrongQuestions;
      _index = 0;
      _selectedIndex = null;
      _correctCount = 0;
      _answers.clear();
    });
  }

  void _selectAnswer(int index) {
    if (_selectedIndex != null) return;
    final question = _questions[_index];
    setState(() {
      _selectedIndex = index;
      if (question.isCorrectAnswer(index)) _correctCount++;
    });
  }

  void _recordCurrentAnswer() {
    final question = _questions[_index];
    _answers.add(
      QuizAnswerRecord(
        questionId: question.id,
        selectedIndex: _selectedIndex!,
        isCorrect: question.isCorrectAnswer(_selectedIndex!),
      ),
    );
  }

  Future<void> _nextOrFinish() async {
    if (_selectedIndex == null) return;

    _recordCurrentAnswer();

    if (_index < _questions.length - 1) {
      setState(() {
        _index++;
        _selectedIndex = null;
      });
      return;
    }

    final difficulty = _difficulty!;
    final totalCount = _questions.length;
    final correctCount = _correctCount;
    final result = QuizScoreResult(
      difficulty: difficulty,
      correctCount: correctCount,
      totalCount: totalCount,
      completedAt: DateTime.now(),
      answers: List.unmodifiable(_answers),
    );

    setState(() => _isSaving = true);
    await ref.read(quizRepositoryProvider).saveScoreResult(
          sessionId: widget.sessionId,
          result: result,
        );
    ref.invalidate(sessionQuizProvider(widget.sessionId));
    await WeakAreasLocalDataSource().delete(widget.sessionId);

    if (mounted) {
      // Snapshot câu hỏi trước khi reset state
      final allQuestions = List<QuizQuestion>.from(_questions);

      setState(() {
        _isSaving = false;
        _difficulty = null;
        _questions = [];
      });

      // Hiển thị Bottom Sheet kết quả
      final action = await showQuizResultSheet(
        context: context,
        result: result,
        questions: allQuestions,
        sessionId: widget.sessionId,
      );

      // Xử lý action người dùng chọn
      if (action == null) return;
      if (mounted) {
        final quizAsync =
            ref.read(sessionQuizProvider(widget.sessionId));
        final quiz = quizAsync.valueOrNull;
        if (quiz != null) _retryWrongAnswers(quiz.questions);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(sessionQuizProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Làm quiz')),
      body: Stack(
        children: [
          quizAsync.when(
        loading: () => const AppLoading(fullScreen: true, useSkeleton: true),
        error: (e, _) => Center(child: Text('$e')),
        data: (quiz) {
          if (quiz == null || !quiz.isReady) {
            return const Center(child: Text('Chưa có quiz cho buổi học này.'));
          }

          if (_difficulty == null || _questions.isEmpty) {
            return _DifficultyPicker(
              quiz: quiz,
              onSelect: (d) => _startQuiz(quiz, d),
            );
          }

          final question = _questions[_index];
          final progress = (_index + 1) / _questions.length;

          return Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _difficulty!.label,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Câu ${_index + 1}/${_questions.length}',
                            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(progress * 100).round()}%',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.secondary,
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
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    question.difficulty.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: question.choices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final selected = _selectedIndex == i;
                      final isCorrect = question.correctIndex == i;
                      Color? bg;
                      Color? borderColor;
                      if (_selectedIndex != null) {
                        if (isCorrect) {
                          bg = Colors.green.withValues(alpha: 0.12);
                          borderColor = Colors.green.withValues(alpha: 0.5);
                        } else if (selected) {
                          bg = Colors.red.withValues(alpha: 0.1);
                          borderColor = Colors.red.withValues(alpha: 0.4);
                        }
                      }

                      return AppCard(
                        onTap: _selectedIndex == null
                            ? () => _selectAnswer(i)
                            : null,
                        color: bg,
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: selected
                                    ? (isCorrect
                                        ? Colors.green.withValues(alpha: 0.2)
                                        : Colors.red.withValues(alpha: 0.15))
                                    : AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                                border: borderColor != null
                                    ? Border.all(color: borderColor)
                                    : null,
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + i),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: selected
                                        ? (isCorrect
                                            ? Colors.green.shade700
                                            : Colors.red.shade700)
                                        : AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                question.choices[i],
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                            if (_selectedIndex != null && isCorrect)
                              Icon(Icons.check_circle,
                                  color: Colors.green.shade600, size: 22),
                            if (selected && !isCorrect)
                              Icon(Icons.cancel,
                                  color: Colors.red.shade600, size: 22),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedIndex != null) ...[
                  const SizedBox(height: 12),
                  AppCard(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withValues(alpha: 0.4),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            question.explanation,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                AppButton(
                  label: _isSaving
                      ? 'Đang lưu...'
                      : _index < _questions.length - 1
                          ? 'Câu tiếp theo'
                          : 'Xem kết quả',
                  variant: AppButtonVariant.primary,
                  expand: true,
                  isLoading: _isSaving,
                  onPressed: _selectedIndex == null || _isSaving
                      ? null
                      : _nextOrFinish,
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

class _DifficultyPicker extends StatelessWidget {
  const _DifficultyPicker({
    required this.quiz,
    required this.onSelect,
  });

  final SessionQuiz quiz;
  final ValueChanged<QuizDifficulty> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionHeader(
            title: quiz.title,
            subtitle:
                '${quiz.questions.length} câu trong đề · Chọn mức độ',
          ),
          const SizedBox(height: 16),
          _DifficultyTile(
            title: QuizDifficulty.easy.label,
            subtitle:
                '${quiz.questionsForDifficulty(QuizDifficulty.easy).length} câu — dễ & trung bình',
            icon: Icons.sentiment_satisfied_alt_outlined,
            onTap: () => onSelect(QuizDifficulty.easy),
          ),
          const SizedBox(height: 12),
          _DifficultyTile(
            title: QuizDifficulty.medium.label,
            subtitle: '${quiz.questions.length} câu — toàn bộ đề',
            icon: Icons.balance_outlined,
            onTap: () => onSelect(QuizDifficulty.medium),
          ),
          const SizedBox(height: 12),
          _DifficultyTile(
            title: QuizDifficulty.hard.label,
            subtitle:
                '${quiz.questionsForDifficulty(QuizDifficulty.hard).length} câu — khó & trung bình',
            icon: Icons.local_fire_department_outlined,
            onTap: () => onSelect(QuizDifficulty.hard),
          ),
        ],
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  const _DifficultyTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
