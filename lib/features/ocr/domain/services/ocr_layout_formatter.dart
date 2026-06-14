import 'package:snapstudy/features/ocr/domain/entities/capture_ocr_result.dart';
import 'package:snapstudy/features/ocr/domain/services/ocr_unicode_normalizer.dart';

/// Ghép khối OCR thành văn bản có bố cục (đoạn, câu hỏi, đáp án).
abstract final class OcrLayoutFormatter {
  static String fromCapture(CaptureOcrResult capture) {
    if (capture.blocks.isEmpty) {
      return _formatPlain(capture.text);
    }

    final paragraphs = <String>[];
    for (final block in capture.blocks) {
      final lines = block.lines
          .map((l) => l.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      if (lines.isEmpty) continue;

      final joined = lines.map(_formatLine).join('\n');
      if (joined.trim().isNotEmpty) paragraphs.add(joined);
    }

    if (paragraphs.isEmpty) return _formatPlain(capture.text);
    return OcrUnicodeNormalizer.normalize(paragraphs.join('\n\n'));
  }

  static String fromCaptures(List<CaptureOcrResult> captures) {
    return captures
        .where((c) => c.isSuccess && c.text.trim().isNotEmpty)
        .map(fromCapture)
        .join('\n\n---\n\n');
  }

  static String _formatPlain(String text) =>
      OcrUnicodeNormalizer.normalize(text.trim());

  static String _formatLine(String line) {
    var s = line.trim();

    final question = RegExp(
      r'^(câu|cau)\s*(\d+|[IVXLC]+)\s*[\.\):\-]?\s*(.*)$',
      caseSensitive: false,
    ).firstMatch(s);
    if (question != null) {
      final num = question.group(2) ?? '';
      final rest = question.group(3)?.trim() ?? '';
      return rest.isEmpty ? 'Câu $num' : 'Câu $num: $rest';
    }

    final option = RegExp(r'^([a-dA-D])[\.\)]\s*(.+)$').firstMatch(s);
    if (option != null) {
      return '${option.group(1)!.toLowerCase()}. ${option.group(2)!.trim()}';
    }

    if (RegExp(r'^\d+[\.\)]\s+').hasMatch(s)) {
      return s.replaceFirstMapped(
        RegExp(r'^(\d+)[\.\)]\s+'),
        (m) => '${m.group(1)}. ',
      );
    }

    return s;
  }
}
