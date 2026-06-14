import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_prompt_builder.dart';
import 'package:snapstudy/features/ai_summary/data/services/mock_ai_summary_generator.dart';
import 'package:snapstudy/features/ai_summary/data/services/summary_json_parser.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/ai_summary/domain/repositories/ai_summary_repository.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';

class AiSummaryRepositoryImpl implements AiSummaryRepository {
  AiSummaryRepositoryImpl({
    required SessionRepository sessions,
    required LlmJsonClient llm,
  })  : _sessions = sessions,
        _llm = llm;

  final SessionRepository _sessions;
  final LlmJsonClient _llm;

  @override
  Future<Result<SessionAiSummary>> generateAndSave({
    required StudySession session,
  }) async {
    final ocr = session.ocrResult;
    if (ocr == null || ocr.fullText.trim().isEmpty) {
      return const Error(
        ValidationFailure('Cần OCR trước khi tạo tóm tắt AI.'),
      );
    }

    final Result<SessionAiSummary> generated;
    if (EnvConfig.useMockAiSummary) {
      generated = Success(
        MockAiSummaryGenerator.generate(session: session, ocr: ocr),
      );
    } else {
      final prompt = GeminiPromptBuilder.buildSummaryPrompt(
        session: session,
        ocr: ocr,
      );
      final raw = await _llm.generateJson(
        prompt: prompt,
        feature: GeminiAiFeature.summary,
      );
      generated = await raw.flatMap((jsonText) async {
        final parsed = SummaryJsonParser.parse(
          sessionId: session.id,
          rawJson: jsonText,
          modelName: EnvConfig.activeTextLlmModel,
        );
        return parsed;
      });
    }

    return await generated.flatMap((summary) async {
      final saved = await _sessions.applyAiSummary(
        sessionId: session.id,
        summary: summary,
      );
      return saved.fold(
        onSuccess: (_) => Success(summary),
        onFailure: Error.new,
      );
    });
  }

  @override
  Future<Result<SessionAiSummary?>> getSummary(String sessionId) async {
    final session = await _sessions.getSessionById(sessionId);
    return session.fold(
      onSuccess: (s) => Success(s?.aiSummary),
      onFailure: Error.new,
    );
  }
}

