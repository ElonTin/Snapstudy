import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_api_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_json_parser.dart';
import 'package:snapstudy/features/mindmap/data/services/mindmap_prompt_builder.dart';
import 'package:snapstudy/features/mindmap/data/services/mock_mindmap_generator.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/mindmap/domain/repositories/mindmap_repository.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';

class MindmapRepositoryImpl implements MindmapRepository {
  MindmapRepositoryImpl({
    required SessionRepository sessions,
    required GeminiApiClient gemini,
  })  : _sessions = sessions,
        _gemini = gemini;

  final SessionRepository _sessions;
  final GeminiApiClient _gemini;

  @override
  Future<Result<SessionMindmap>> generateAndSave({
    required StudySession session,
  }) async {
    final ocr = session.ocrResult;
    if (ocr == null || ocr.fullText.trim().isEmpty) {
      return const Error(
        ValidationFailure('Cần OCR trước khi tạo mindmap.'),
      );
    }

    final Result<SessionMindmap> generated;
    if (EnvConfig.useMockMindmap) {
      generated = Success(
        MockMindmapGenerator.generate(
          session: session,
          summary: session.aiSummary,
        ),
      );
    } else {
      final prompt = MindmapPromptBuilder.buildMindmapPrompt(
        session: session,
        ocr: ocr,
        summary: session.aiSummary,
        deck: session.flashcardDeck,
        quiz: session.sessionQuiz,
      );
      final raw = await _gemini.generateJson(
        prompt: prompt,
        feature: GeminiAiFeature.mindmap,
      );
      generated = await raw.flatMap((jsonText) async {
        return MindmapJsonParser.parse(
          sessionId: session.id,
          rawJson: jsonText,
          modelName: EnvConfig.geminiModel,
        );
      });
    }

    return await generated.flatMap((map) async {
      final saved = await _sessions.applySessionMindmap(
        sessionId: session.id,
        mindmap: map,
      );
      return saved.fold(
        onSuccess: (_) => Success(map),
        onFailure: Error.new,
      );
    });
  }

  @override
  Future<Result<SessionMindmap?>> getMindmap(String sessionId) async {
    final session = await _sessions.getSessionById(sessionId);
    return session.fold(
      onSuccess: (s) => Success(s?.sessionMindmap),
      onFailure: Error.new,
    );
  }
}
