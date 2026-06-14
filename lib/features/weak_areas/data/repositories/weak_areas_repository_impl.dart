import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/weak_areas/data/datasources/weak_areas_local_datasource.dart';
import 'package:snapstudy/features/weak_areas/data/prompts/weak_areas_prompt_builder.dart';
import 'package:snapstudy/features/weak_areas/data/services/weak_areas_ai_parser.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/session_weak_areas_insight.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';
import 'package:snapstudy/features/weak_areas/domain/repositories/weak_areas_repository.dart';
import 'package:snapstudy/features/weak_areas/domain/services/weak_areas_analyzer.dart';

class WeakAreasRepositoryImpl implements WeakAreasRepository {
  WeakAreasRepositoryImpl({
    required LlmJsonClient llm,
    WeakAreasLocalDataSource? local,
  })  : _llm = llm,
        _local = local ?? WeakAreasLocalDataSource();

  final LlmJsonClient _llm;
  final WeakAreasLocalDataSource _local;

  @override
  List<WeakAreaItem> analyzeSession(StudySession session) =>
      WeakAreasAnalyzer.analyzeSession(session);

  @override
  List<WeakAreaItem> analyzeAll(List<StudySession> sessions) =>
      WeakAreasAnalyzer.analyzeAll(sessions);

  @override
  Future<SessionWeakAreasInsight?> getCachedInsight(String sessionId) =>
      _local.read(sessionId);

  @override
  Future<Result<SessionWeakAreasInsight>> generateAiInsight({
    required StudySession session,
    bool forceRefresh = false,
  }) async {
    final signals = analyzeSession(session);
    if (signals.isEmpty) {
      return const Error(
        ValidationFailure('Chưa có dữ liệu ôn tập — hãy làm quiz hoặc flashcard trước.'),
      );
    }

    if (!forceRefresh) {
      final cached = await _local.read(session.id);
      if (cached != null) return Success(cached);
    }

    if (!EnvConfig.isTextLlmConfigured) {
      final fallback = SessionWeakAreasInsight(
        items: signals,
        aiAdvice:
            'Bạn còn yếu ${signals.length} phần — hãy ôn flashcard và làm lại quiz các chủ đề trên.',
        generatedAt: DateTime.now(),
      );
      await _local.save(session.id, fallback);
      return Success(fallback);
    }

    final prompt = WeakAreasPromptBuilder.build(
      session: session,
      signals: signals,
    );
    final raw = await _llm.generateJson(
      prompt: prompt,
      feature: GeminiAiFeature.weakAreas,
    );

    if (raw.isFailure) return Error(raw.failureOrNull!);

    final parsed = WeakAreasAiParser.parse(raw.valueOrNull!, signals);
    if (parsed.isFailure) return Error(parsed.failureOrNull!);

    final insight = parsed.valueOrNull!.copyWithItemsSessionMeta(session, signals);
    await _local.save(session.id, insight);
    return Success(insight);
  }
}

extension on SessionWeakAreasInsight {
  SessionWeakAreasInsight copyWithItemsSessionMeta(
    StudySession session,
    List<WeakAreaItem> signals,
  ) {
    final merged = items.map((item) {
      final match = signals.where((s) => s.label == item.label).firstOrNull;
      return WeakAreaItem(
        label: item.label,
        reason: item.reason,
        source: match?.source ?? item.source,
        priorityScore: match?.priorityScore ?? item.priorityScore,
        referenceId: match?.referenceId,
        sessionId: session.id,
        sessionTitle: session.title,
      );
    }).toList();

    if (merged.isEmpty) {
      return SessionWeakAreasInsight(
        items: signals,
        aiAdvice: aiAdvice,
        generatedAt: generatedAt,
      );
    }

    return SessionWeakAreasInsight(
      items: merged,
      aiAdvice: aiAdvice,
      generatedAt: generatedAt,
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
