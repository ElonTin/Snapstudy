import 'dart:convert';

import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/ocr/domain/services/latex_equation_extractor.dart';
import 'package:snapstudy/features/ocr/domain/services/ocr_unicode_normalizer.dart';

class OcrEnhancementResult {
  const OcrEnhancementResult({
    required this.formattedText,
    required this.latexEquations,
  });

  final String formattedText;
  final List<String> latexEquations;
}

/// Làm đẹp bố cục + chuyển công thức sang LaTeX bằng LLM (Groq/Gemini).
class OcrTextEnhancer {
  OcrTextEnhancer({LlmJsonClient? llm}) : _llm = llm;

  final LlmJsonClient? _llm;

  Future<OcrEnhancementResult> enhance(String rawText) async {
    final locallyFormatted = OcrUnicodeNormalizer.normalize(rawText);

    if (!EnvConfig.enableOcrEnhancement ||
        !EnvConfig.isTextLlmConfigured ||
        _llm == null ||
        locallyFormatted.trim().length < 12) {
      return _localOnly(locallyFormatted);
    }

    final prompt = '''
Bạn là chuyên gia biên tập OCR học thuật (toán, lý, hóa, văn, tiếng Anh).
Nhiệm vụ: làm sạch và cấu trúc lại văn bản OCR, KHÔNG thêm nội dung mới.

Trả về ĐÚNG MỘT JSON (không markdown):
{
  "formattedText": "văn bản đã sắp xếp",
  "latexEquations": ["công thức 1", "công thức 2"]
}

Quy tắc formattedText:
- Giữ nguyên ngôn ngữ gốc, không dịch
- Tách đoạn rõ ràng (xuống dòng kép giữa đoạn/câu hỏi)
- Câu hỏi trắc nghiệm: "Câu 1:", đáp án "a.", "b." mỗi dòng
- Tiêu đề in hoa nếu trên ảnh là tiêu đề
- Công thức toán inline: bọc trong cặp ký hiệu dollar LaTeX
- Công thức riêng dòng: bọc trong cặp dollar kép
- Ký hiệu đặc biệt: dùng LaTeX (times, leq, sqrt, frac, mũ, chỉ số)
- Không bịa, không giải thích, không markdown

latexEquations: liệt kê các biể thức LaTeX quan trọng (không có ký hiệu dollar), tối đa 15 mục.

OCR thô:
---
${GeminiTokenLimits.truncate(locallyFormatted, 5500)}
---
''';

    final result = await _llm.generateJson(
      prompt: prompt,
      feature: GeminiAiFeature.ocrFormat,
    );

    return result.fold(
      onSuccess: (raw) => _parseLlm(raw, locallyFormatted),
      onFailure: (_) => _localOnly(locallyFormatted),
    );
  }

  OcrEnhancementResult _parseLlm(String raw, String fallback) {
    try {
      var body = raw.trim();
      if (body.startsWith('```')) {
        body = body
            .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim();
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final formatted = (json['formattedText'] as String?)?.trim();
      if (formatted == null || formatted.isEmpty) {
        return _localOnly(fallback);
      }

      final equations = <String>[
        ...LatexEquationExtractor.extract(formatted),
        ...((json['latexEquations'] as List<dynamic>?)
                ?.map((e) => e.toString().trim())
                .where((e) => e.length > 1) ??
            []),
      ];

      return OcrEnhancementResult(
        formattedText: OcrUnicodeNormalizer.normalize(formatted),
        latexEquations: equations.toSet().take(20).toList(),
      );
    } catch (_) {
      return _localOnly(fallback);
    }
  }

  OcrEnhancementResult _localOnly(String text) {
    return OcrEnhancementResult(
      formattedText: text,
      latexEquations: LatexEquationExtractor.extract(text),
    );
  }
}
