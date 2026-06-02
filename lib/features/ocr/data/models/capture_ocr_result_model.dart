import 'package:snapstudy/features/ocr/data/models/ocr_text_block_model.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';

class CaptureOcrResultModel {
  const CaptureOcrResultModel({
    required this.captureId,
    required this.imagePath,
    required this.text,
    required this.blocks,
    required this.confidence,
    required this.hasEquations,
    required this.status,
    this.errorMessage,
  });

  factory CaptureOcrResultModel.fromJson(Map<String, dynamic> json) {
    final blocksRaw = json['blocks'] as List<dynamic>? ?? [];
    return CaptureOcrResultModel(
      captureId: json['captureId'] as String,
      imagePath: json['imagePath'] as String,
      text: json['text'] as String,
      blocks: blocksRaw
          .map(
            (e) => OcrTextBlockModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
      confidence: (json['confidence'] as num).toDouble(),
      hasEquations: json['hasEquations'] as bool? ?? false,
      status: OcrStatus.values.byName(json['status'] as String),
      errorMessage: json['errorMessage'] as String?,
    );
  }

  final String captureId;
  final String imagePath;
  final String text;
  final List<OcrTextBlockModel> blocks;
  final double confidence;
  final bool hasEquations;
  final OcrStatus status;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'captureId': captureId,
        'imagePath': imagePath,
        'text': text,
        'blocks': blocks.map((b) => b.toJson()).toList(),
        'confidence': confidence,
        'hasEquations': hasEquations,
        'status': status.name,
        'errorMessage': errorMessage,
      };

  CaptureOcrResult toEntity() => CaptureOcrResult(
        captureId: captureId,
        imagePath: imagePath,
        text: text,
        blocks: blocks.map((b) => b.toEntity()).toList(),
        confidence: confidence,
        hasEquations: hasEquations,
        status: status,
        errorMessage: errorMessage,
      );

  static CaptureOcrResultModel fromEntity(CaptureOcrResult result) =>
      CaptureOcrResultModel(
        captureId: result.captureId,
        imagePath: result.imagePath,
        text: result.text,
        blocks: result.blocks.map(OcrTextBlockModel.fromEntity).toList(),
        confidence: result.confidence,
        hasEquations: result.hasEquations,
        status: result.status,
        errorMessage: result.errorMessage,
      );
}
