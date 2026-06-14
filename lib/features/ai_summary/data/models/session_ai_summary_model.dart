import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/summary_status.dart';

class SessionAiSummaryModel {
  const SessionAiSummaryModel({
    required this.sessionId,
    required this.detectedTopic,
    required this.shortSummary,
    required this.overview,
    required this.keyPoints,
    required this.bulletSummary,
    required this.topics,
    required this.status,
    required this.generatedAt,
    this.modelName,
    this.errorMessage,
  });

  factory SessionAiSummaryModel.fromJson(Map<String, dynamic> json) {
    final overview = json['overview'] as String? ?? '';
    return SessionAiSummaryModel(
      sessionId: json['sessionId'] as String,
      detectedTopic: json['detectedTopic'] as String,
      shortSummary: json['shortSummary'] as String? ?? overview,
      overview: overview,
      keyPoints: (json['keyPoints'] as List<dynamic>).cast<String>(),
      bulletSummary: (json['bulletSummary'] as List<dynamic>).cast<String>(),
      topics: (json['topics'] as List<dynamic>).cast<String>(),
      status: SummaryStatus.values.byName(json['status'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      modelName: json['modelName'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  final String sessionId;
  final String detectedTopic;
  final String shortSummary;
  final String overview;
  final List<String> keyPoints;
  final List<String> bulletSummary;
  final List<String> topics;
  final SummaryStatus status;
  final DateTime generatedAt;
  final String? modelName;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'detectedTopic': detectedTopic,
        'shortSummary': shortSummary,
        'overview': overview,
        'keyPoints': keyPoints,
        'bulletSummary': bulletSummary,
        'topics': topics,
        'status': status.name,
        'generatedAt': generatedAt.toIso8601String(),
        'modelName': modelName,
        'errorMessage': errorMessage,
      };

  SessionAiSummary toEntity() => SessionAiSummary(
        sessionId: sessionId,
        detectedTopic: detectedTopic,
        shortSummary: shortSummary,
        overview: overview,
        keyPoints: keyPoints,
        bulletSummary: bulletSummary,
        topics: topics,
        status: status,
        generatedAt: generatedAt,
        modelName: modelName,
        errorMessage: errorMessage,
      );

  static SessionAiSummaryModel fromEntity(SessionAiSummary summary) =>
      SessionAiSummaryModel(
        sessionId: summary.sessionId,
        detectedTopic: summary.detectedTopic,
        shortSummary: summary.shortSummary,
        overview: summary.overview,
        keyPoints: summary.keyPoints,
        bulletSummary: summary.bulletSummary,
        topics: summary.topics,
        status: summary.status,
        generatedAt: summary.generatedAt,
        modelName: summary.modelName,
        errorMessage: summary.errorMessage,
      );
}
