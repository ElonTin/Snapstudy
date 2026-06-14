import 'package:snapstudy/features/ocr/data/models/capture_ocr_result_model.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';

class SessionOcrResultModel {
  const SessionOcrResultModel({
    required this.sessionId,
    required this.fullText,
    required this.captures,
    required this.keywords,
    required this.averageConfidence,
    required this.hasEquations,
    this.latexEquations = const [],
    required this.status,
    required this.processedAt,
    this.suggestedSubjectId,
    this.suggestedSubjectName,
    this.suggestedSubjectConfidence = 0,
    this.errorMessage,
  });

  factory SessionOcrResultModel.fromJson(Map<String, dynamic> json) {
    final capturesRaw = json['captures'] as List<dynamic>? ?? [];
    return SessionOcrResultModel(
      sessionId: json['sessionId'] as String,
      fullText: json['fullText'] as String,
      captures: capturesRaw
          .map(
            (e) => CaptureOcrResultModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      keywords: (json['keywords'] as List<dynamic>?)?.cast<String>() ?? [],
      suggestedSubjectId: json['suggestedSubjectId'] as String?,
      suggestedSubjectName: json['suggestedSubjectName'] as String?,
      suggestedSubjectConfidence:
          (json['suggestedSubjectConfidence'] as num?)?.toDouble() ?? 0,
      averageConfidence: (json['averageConfidence'] as num).toDouble(),
      hasEquations: json['hasEquations'] as bool? ?? false,
      latexEquations:
          (json['latexEquations'] as List<dynamic>?)?.cast<String>() ?? [],
      status: OcrStatus.values.byName(json['status'] as String),
      processedAt: DateTime.parse(json['processedAt'] as String),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  final String sessionId;
  final String fullText;
  final List<CaptureOcrResultModel> captures;
  final List<String> keywords;
  final String? suggestedSubjectId;
  final String? suggestedSubjectName;
  final double suggestedSubjectConfidence;
  final double averageConfidence;
  final bool hasEquations;
  final List<String> latexEquations;
  final OcrStatus status;
  final DateTime processedAt;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'fullText': fullText,
        'captures': captures.map((c) => c.toJson()).toList(),
        'keywords': keywords,
        'suggestedSubjectId': suggestedSubjectId,
        'suggestedSubjectName': suggestedSubjectName,
        'suggestedSubjectConfidence': suggestedSubjectConfidence,
        'averageConfidence': averageConfidence,
        'hasEquations': hasEquations,
        'latexEquations': latexEquations,
        'status': status.name,
        'processedAt': processedAt.toIso8601String(),
        'errorMessage': errorMessage,
      };

  SessionOcrResult toEntity() => SessionOcrResult(
        sessionId: sessionId,
        fullText: fullText,
        captures: captures.map((c) => c.toEntity()).toList(),
        keywords: keywords,
        suggestedSubjectId: suggestedSubjectId,
        suggestedSubjectName: suggestedSubjectName,
        suggestedSubjectConfidence: suggestedSubjectConfidence,
        averageConfidence: averageConfidence,
        hasEquations: hasEquations,
        latexEquations: latexEquations,
        status: status,
        processedAt: processedAt,
        errorMessage: errorMessage,
      );

  static SessionOcrResultModel fromEntity(SessionOcrResult result) =>
      SessionOcrResultModel(
        sessionId: result.sessionId,
        fullText: result.fullText,
        captures:
            result.captures.map(CaptureOcrResultModel.fromEntity).toList(),
        keywords: result.keywords,
        suggestedSubjectId: result.suggestedSubjectId,
        suggestedSubjectName: result.suggestedSubjectName,
        suggestedSubjectConfidence: result.suggestedSubjectConfidence,
        averageConfidence: result.averageConfidence,
        hasEquations: result.hasEquations,
        latexEquations: result.latexEquations,
        status: result.status,
        processedAt: result.processedAt,
        errorMessage: result.errorMessage,
      );
}
