import 'dart:convert';

import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_question.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_status.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';

/// Parses and validates AI quiz JSON (structured schema + sanity checks).
abstract final class QuizJsonParser {
  static const _minQuestions = 4;
  static const _maxQuestions = 12;
  static const _choiceCount = 4;

  static Result<SessionQuiz> parse({
    required String sessionId,
    required String rawJson,
    String? modelName,
  }) {
    try {
      var text = rawJson.trim();
      if (text.startsWith('```')) {
        text = text
            .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim();
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        return const Error(
          ValidationFailure('Phản hồi quiz không phải JSON object.'),
        );
      }

      final title = decoded['title'];
      if (title is! String || title.trim().isEmpty) {
        return const Error(ValidationFailure('Thiếu trường "title".'));
      }

      final defaultDifficulty = QuizDifficultyX.tryParse(
            decoded['defaultDifficulty'] as String?,
          ) ??
          QuizDifficulty.medium;

      final questionsRaw = decoded['questions'];
      if (questionsRaw is! List || questionsRaw.isEmpty) {
        return const Error(
          ValidationFailure('Cần mảng "questions" không rỗng.'),
        );
      }

      final questions = <QuizQuestion>[];
      final seenPrompts = <String>{};

      for (var i = 0; i < questionsRaw.length && i < _maxQuestions; i++) {
        final parsed = _parseQuestion(
          item: questionsRaw[i],
          sessionId: sessionId,
          index: i,
          seenPrompts: seenPrompts,
        );
        if (parsed != null) questions.add(parsed);
      }

      if (questions.length < _minQuestions) {
        return Error(
          ValidationFailure(
            'Cần ít nhất $_minQuestions câu hợp lệ (có $_choiceCount đáp án).',
          ),
        );
      }

      return Success(
        SessionQuiz(
          sessionId: sessionId,
          title: title.trim(),
          questions: questions,
          status: QuizStatus.completed,
          generatedAt: DateTime.now(),
          defaultDifficulty: defaultDifficulty,
          modelName: modelName,
        ),
      );
    } catch (e) {
      return Error(ValidationFailure('JSON quiz không hợp lệ: $e'));
    }
  }

  static QuizQuestion? _parseQuestion({
    required Object? item,
    required String sessionId,
    required int index,
    required Set<String> seenPrompts,
  }) {
    if (item is! Map<String, dynamic>) return null;

    final prompt = item['prompt'];
    if (prompt is! String || prompt.trim().isEmpty) return null;
    final promptKey = prompt.trim().toLowerCase();
    if (seenPrompts.contains(promptKey)) return null;
    seenPrompts.add(promptKey);

    final choicesRaw = item['choices'];
    if (choicesRaw is! List || choicesRaw.length != _choiceCount) return null;

    final choices = <String>[];
    for (final c in choicesRaw) {
      if (c is! String || c.trim().isEmpty) return null;
      choices.add(c.trim());
    }

    final uniqueChoices = choices.toSet();
    if (uniqueChoices.length != _choiceCount) return null;

    final correctIndex = item['correctIndex'];
    if (correctIndex is! int ||
        correctIndex < 0 ||
        correctIndex >= _choiceCount) {
      return null;
    }

    final explanation = item['explanation'];
    if (explanation is! String || explanation.trim().isEmpty) return null;

    final difficulty = QuizDifficultyX.tryParse(
          item['difficulty'] as String?,
        ) ??
        QuizDifficulty.medium;

    return QuizQuestion(
      id: 'q_${sessionId}_${index + 1}',
      prompt: prompt.trim(),
      choices: choices,
      correctIndex: correctIndex,
      explanation: explanation.trim(),
      difficulty: difficulty,
    );
  }
}
