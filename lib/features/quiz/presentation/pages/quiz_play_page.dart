import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_question.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/quiz/presentation/providers/quiz_providers.dart';

class QuizPlayPage extends ConsumerStatefulWidget {
  const QuizPlayPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  ConsumerState<QuizPlayPage> createState() => _QuizPlayPageState();
}

class _QuizPlayPageState extends ConsumerState<QuizPlayPage> {
  QuizDifficulty? _difficulty;
  List<QuizQuestion> _questions = [];
  var _index = 0;
  int? _selectedIndex;
  var _correctCount = 0;
  var _isSaving = false;

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

  Future<void> _nextOrFinish() async {
    if (_selectedIndex == null) return;

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
    );

    setState(() => _isSaving = true);
    await ref.read(quizRepositoryProvider).saveScoreResult(
          sessionId: widget.sessionId,
          result: result,
        );
    ref.invalidate(sessionQuizProvider(widget.sessionId));

    if (mounted) {
      setState(() {
        _isSaving = false;
        _difficulty = null;
        _questions = [];
      });
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Kết quả quiz'),
          content: Text(
            'Bạn trả lời đúng $correctCount/$totalCount câu '
            '(${result.scorePercent}%) · Mức ${difficulty.label}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizAsync = ref.watch(sessionQuizProvider(widget.sessionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Làm quiz')),
      body: quizAsync.when(
        loading: () => const AppLoading(fullScreen: true),
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
                Row(
                  children: [
                    Chip(
                      label: Text(_difficulty!.label),
                      visualDensity: VisualDensity.compact,
                    ),
                    const Spacer(),
                    Text(
                      '${_index + 1}/${_questions.length}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
                const SizedBox(height: 20),
                Text(
                  question.prompt,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Chip(
                  label: Text(question.difficulty.label),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: question.choices.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final selected = _selectedIndex == i;
                      final isCorrect = question.correctIndex == i;
                      Color? bg;
                      if (_selectedIndex != null) {
                        if (isCorrect) {
                          bg = Colors.green.withValues(alpha: 0.15);
                        } else if (selected) {
                          bg = Colors.red.withValues(alpha: 0.12);
                        }
                      }

                      return Material(
                        color: bg ??
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: _selectedIndex == null
                              ? () => _selectAnswer(i)
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor:
                                      AppColors.primary.withValues(alpha: 0.2),
                                  child: Text(
                                    String.fromCharCode(65 + i),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(question.choices[i])),
                                if (_selectedIndex != null && isCorrect)
                                  const Icon(Icons.check_circle,
                                      color: Colors.green),
                                if (selected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (_selectedIndex != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      question.explanation,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _selectedIndex == null || _isSaving
                      ? null
                      : _nextOrFinish,
                  child: Text(
                    _isSaving
                        ? 'Đang lưu...'
                        : _index < _questions.length - 1
                            ? 'Câu tiếp theo'
                            : 'Xem kết quả',
                  ),
                ),
              ],
            ),
          );
        },
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
          Text(
            quiz.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${quiz.questions.length} câu trong đề · Chọn mức độ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
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
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
