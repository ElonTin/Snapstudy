import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_api_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/quiz/data/services/mock_quiz_generator.dart';
import 'package:snapstudy/features/quiz/data/services/quiz_json_parser.dart';
import 'package:snapstudy/features/quiz/data/services/quiz_prompt_builder.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_score_result.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/quiz/domain/repositories/quiz_repository.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';

class QuizRepositoryImpl implements QuizRepository {
  QuizRepositoryImpl({
    required SessionRepository sessions,
    required GeminiApiClient gemini,
  })  : _sessions = sessions,
        _gemini = gemini;

  final SessionRepository _sessions;
  final GeminiApiClient _gemini;

  @override
  Future<Result<SessionQuiz>> generateAndSave({
    required StudySession session,
  }) async {
    final ocr = session.ocrResult;
    if (ocr == null || ocr.fullText.trim().isEmpty) {
      return const Error(
        ValidationFailure('Cần OCR trước khi tạo quiz.'),
      );
    }

    final Result<SessionQuiz> generated;
    if (EnvConfig.useMockQuiz) {
      generated = Success(
        MockQuizGenerator.generate(
          session: session,
          summary: session.aiSummary,
          deck: session.flashcardDeck,
        ),
      );
    } else {
      final prompt = QuizPromptBuilder.buildQuizPrompt(
        session: session,
        ocr: ocr,
        summary: session.aiSummary,
        deck: session.flashcardDeck,
      );
      final raw = await _gemini.generateJson(
        prompt: prompt,
        feature: GeminiAiFeature.quiz,
      );
      generated = await raw.flatMap((jsonText) async {
        return QuizJsonParser.parse(
          sessionId: session.id,
          rawJson: jsonText,
          modelName: EnvConfig.geminiModel,
        );
      });
    }

    return await generated.flatMap((quiz) async {
      final saved = await _sessions.applySessionQuiz(
        sessionId: session.id,
        quiz: quiz,
      );
      return saved.fold(
        onSuccess: (_) => Success(quiz),
        onFailure: Error.new,
      );
    });
  }

  @override
  Future<Result<SessionQuiz?>> getQuiz(String sessionId) async {
    final session = await _sessions.getSessionById(sessionId);
    return session.fold(
      onSuccess: (s) => Success(s?.sessionQuiz),
      onFailure: Error.new,
    );
  }

  @override
  Future<Result<SessionQuiz>> saveScoreResult({
    required String sessionId,
    required QuizScoreResult result,
  }) async {
    final sessionResult = await _sessions.getSessionById(sessionId);
    final session = sessionResult.fold(
      onSuccess: (s) => s,
      onFailure: (_) => null,
    );
    final quiz = session?.sessionQuiz;
    if (quiz == null) {
      return const Error(ValidationFailure('Chưa có quiz.'));
    }

    final updated = SessionQuiz(
      sessionId: quiz.sessionId,
      title: quiz.title,
      questions: quiz.questions,
      status: quiz.status,
      generatedAt: quiz.generatedAt,
      defaultDifficulty: quiz.defaultDifficulty,
      modelName: quiz.modelName,
      errorMessage: quiz.errorMessage,
      lastResult: result,
    );

    final saved = await _sessions.applySessionQuiz(
      sessionId: sessionId,
      quiz: updated,
    );
    return saved.fold(
      onSuccess: (_) => Success(updated),
      onFailure: Error.new,
    );
  }
}
