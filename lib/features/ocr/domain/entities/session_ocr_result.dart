import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';

/// Aggregated OCR for all images in a study session.
class SessionOcrResult extends Equatable {
  const SessionOcrResult({
    required this.sessionId,
    required this.fullText,
    required this.captures,
    required this.keywords,
    required this.averageConfidence,
    required this.hasEquations,
    required this.status,
    required this.processedAt,
    this.suggestedSubjectId,
    this.suggestedSubjectName,
    this.suggestedSubjectConfidence = 0,
    this.errorMessage,
  });

  final String sessionId;
  final String fullText;
  final List<CaptureOcrResult> captures;
  final List<String> keywords;
  final String? suggestedSubjectId;
  final String? suggestedSubjectName;
  final double suggestedSubjectConfidence;
  final double averageConfidence;
  final bool hasEquations;
  final OcrStatus status;
  final DateTime processedAt;
  final String? errorMessage;

  int get successCount => captures.where((c) => c.isSuccess).length;

  @override
  List<Object?> get props => [
        sessionId,
        fullText,
        captures,
        keywords,
        suggestedSubjectId,
        suggestedSubjectName,
        suggestedSubjectConfidence,
        averageConfidence,
        hasEquations,
        status,
        processedAt,
        errorMessage,
      ];
}
