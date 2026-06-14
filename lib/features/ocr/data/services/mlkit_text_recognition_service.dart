import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:snapstudy/features/ocr/data/services/text_recognition_service.dart';
import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_line.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_text_block.dart';
import 'package:snapstudy/features/ocr/domain/services/equation_detector.dart';

class MlKitTextRecognitionService implements TextRecognitionService {
  MlKitTextRecognitionService() : _recognizer = TextRecognizer();

  final TextRecognizer _recognizer;

  @override
  Future<CaptureOcrResult> recognizeCapture({
    required String captureId,
    required String imagePath,
  }) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return CaptureOcrResult(
          captureId: captureId,
          imagePath: imagePath,
          text: '',
          blocks: const [],
          confidence: 0,
          hasEquations: false,
          status: OcrStatus.failed,
          errorMessage: 'File ảnh không tồn tại',
        );
      }

      final input = InputImage.fromFilePath(imagePath);
      final recognized = await _recognizer.processImage(input);
      final blocks = _mapBlocks(recognized);
      final text = _textFromBlocks(blocks, recognized.text.trim());
      final confidence = _estimateConfidence(blocks, text);
      final hasEquations = EquationDetector.containsEquations(text);

      return CaptureOcrResult(
        captureId: captureId,
        imagePath: imagePath,
        text: text,
        blocks: blocks,
        confidence: confidence,
        hasEquations: hasEquations,
        status: text.isEmpty ? OcrStatus.partial : OcrStatus.completed,
      );
    } catch (e) {
      return CaptureOcrResult(
        captureId: captureId,
        imagePath: imagePath,
        text: '',
        blocks: const [],
        confidence: 0,
        hasEquations: false,
        status: OcrStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  String _textFromBlocks(List<OcrTextBlock> blocks, String fallback) {
    if (blocks.isEmpty) return fallback;
    final fromBlocks = blocks
        .map((b) => b.lines.map((l) => l.text).join('\n'))
        .where((p) => p.trim().isNotEmpty)
        .join('\n\n');
    return fromBlocks.isNotEmpty ? fromBlocks : fallback;
  }

  List<OcrTextBlock> _mapBlocks(RecognizedText recognized) {
    return recognized.blocks.map((block) {
      final lines = block.lines.map((line) {
        var lineConfidence = 0.0;
        var count = 0;
        for (final element in line.elements) {
          final c = element.confidence;
          if (c != null) {
            lineConfidence += c;
            count++;
          }
        }
        final conf = count > 0 ? lineConfidence / count : 0.85;
        return OcrLine(text: line.text, confidence: conf.clamp(0, 1));
      }).toList();

      final blockConf = lines.isEmpty
          ? 0.0
          : lines.map((l) => l.confidence).reduce((a, b) => a + b) / lines.length;

      return OcrTextBlock(
        text: block.text,
        confidence: blockConf,
        lines: lines,
      );
    }).toList();
  }

  double _estimateConfidence(List<OcrTextBlock> blocks, String text) {
    if (text.isEmpty) return 0;
    if (blocks.isEmpty) return 0.75;
    return blocks.map((b) => b.confidence).reduce((a, b) => a + b) /
        blocks.length;
  }

  @override
  Future<void> dispose() => _recognizer.close();
}
