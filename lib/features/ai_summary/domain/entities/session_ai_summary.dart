import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/summary_status.dart';

/// Structured AI lecture summary (Phase 9 — Gemini).
class SessionAiSummary extends Equatable {
  const SessionAiSummary({
    required this.sessionId,
    required this.detectedTopic,
    required this.overview,
    required this.keyPoints,
    required this.bulletSummary,
    required this.topics,
    required this.status,
    required this.generatedAt,
    this.modelName,
    this.errorMessage,
  });

  final String sessionId;
  final String detectedTopic;
  final String overview;
  final List<String> keyPoints;
  final List<String> bulletSummary;
  final List<String> topics;
  final SummaryStatus status;
  final DateTime generatedAt;
  final String? modelName;
  final String? errorMessage;

  bool get isReady => status == SummaryStatus.completed;

  @override
  List<Object?> get props => [
        sessionId,
        detectedTopic,
        overview,
        keyPoints,
        bulletSummary,
        topics,
        status,
        generatedAt,
        modelName,
        errorMessage,
      ];
}
