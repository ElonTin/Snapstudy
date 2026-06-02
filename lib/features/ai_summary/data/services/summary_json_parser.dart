import 'dart:convert';

import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/summary_status.dart';

/// Validates and parses Gemini JSON summary responses.
abstract final class SummaryJsonParser {
  static Result<SessionAiSummary> parse({
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
          ValidationFailure('Phản hồi AI không phải JSON object.'),
        );
      }

      final topic = _requireString(decoded, 'detectedTopic');
      if (topic.isFailure) return Error(topic.failureOrNull!);

      final overview = _requireString(decoded, 'overview');
      if (overview.isFailure) return Error(overview.failureOrNull!);

      final keyPoints = _requireStringList(decoded, 'keyPoints', min: 1, max: 12);
      if (keyPoints.isFailure) return Error(keyPoints.failureOrNull!);

      final bullets =
          _requireStringList(decoded, 'bulletSummary', min: 1, max: 15);
      if (bullets.isFailure) return Error(bullets.failureOrNull!);

      final topics = _requireStringList(decoded, 'topics', min: 1, max: 8);
      if (topics.isFailure) return Error(topics.failureOrNull!);

      return Success(
        SessionAiSummary(
          sessionId: sessionId,
          detectedTopic: topic.valueOrNull!,
          overview: overview.valueOrNull!,
          keyPoints: keyPoints.valueOrNull!,
          bulletSummary: bullets.valueOrNull!,
          topics: topics.valueOrNull!,
          status: SummaryStatus.completed,
          generatedAt: DateTime.now(),
          modelName: modelName,
        ),
      );
    } catch (e) {
      return Error(ValidationFailure('JSON AI không hợp lệ: $e'));
    }
  }

  static Result<String> _requireString(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.trim().isEmpty) {
      return Error(ValidationFailure('Thiếu hoặc sai trường "$key".'));
    }
    return Success(value.trim());
  }

  static Result<List<String>> _requireStringList(
    Map<String, dynamic> json,
    String key, {
    required int min,
    required int max,
  }) {
    final value = json[key];
    if (value is! List) {
      return Error(ValidationFailure('Trường "$key" phải là mảng.'));
    }
    final list = value
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(max)
        .toList();
    if (list.length < min) {
      return Error(ValidationFailure('Trường "$key" cần ít nhất $min mục.'));
    }
    return Success(list);
  }
}
