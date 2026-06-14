import 'dart:convert';

import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai/data/services/llm_json_client.dart';
import 'package:snapstudy/features/ai_summary/data/services/gemini_token_limits.dart';
import 'package:snapstudy/features/ocr/domain/entities/ai_subject_classification.dart';
import 'package:snapstudy/features/ocr/domain/services/keyword_extractor.dart';

/// Phân loại môn học bằng Gemini (hoặc heuristic khi offline).
class AiSubjectClassifier {
  AiSubjectClassifier({LlmJsonClient? llm}) : _llm = llm;

  final LlmJsonClient? _llm;

  /// Phân loại nhanh offline — không gọi API (dùng khi ingest để không chặn UI).
  Future<Result<AiSubjectClassification>> classifyFast(String ocrSample) async {
    final text = ocrSample.trim();
    if (text.isEmpty) {
      return const Success(
        AiSubjectClassification(
          subjectName: 'Tổng hợp',
          confidence: 0.3,
          topic: 'Tài liệu chưa có chữ',
        ),
      );
    }
    return Success(_classifyHeuristic(text));
  }

  Future<Result<AiSubjectClassification>> classify(String ocrSample) async {
    final text = ocrSample.trim();
    if (text.isEmpty) {
      return const Success(
        AiSubjectClassification(
          subjectName: 'Tổng hợp',
          confidence: 0.3,
          topic: 'Tài liệu chưa có chữ',
        ),
      );
    }

    if (EnvConfig.isTextLlmConfigured && _llm != null) {
      final ai = await _classifyWithLlm(text);
      if (ai.isSuccess) return ai;
    }

    return Success(_classifyHeuristic(text));
  }

  Future<Result<AiSubjectClassification>> _classifyWithLlm(String text) async {
    final prompt = '''
Bạn là chuyên gia phân loại tài liệu học tập Việt Nam (lớp 1–12, THPT, đại học, mọi môn).
Đọc đoạn OCR và trả về ĐÚNG MỘT JSON (không markdown):
{
  "subjectName": "tên môn chính xác bằng tiếng Việt",
  "educationLevel": "Lớp X hoặc THPT hoặc Đại học hoặc null",
  "topic": "chủ đề bài 1 câu ngắn",
  "confidence": 0.0 đến 1.0
}

OCR:
---
${GeminiTokenLimits.truncate(text, 4000)}
---
''';

    final result = await _llm!.generateJson(
      prompt: prompt,
      feature: GeminiAiFeature.summary,
    );

    return result.fold(
      onSuccess: (raw) {
        try {
          var body = raw.trim();
          if (body.startsWith('```')) {
            body = body
                .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
                .replaceFirst(RegExp(r'\s*```$'), '')
                .trim();
          }
          final json = jsonDecode(body) as Map<String, dynamic>;
          final name = (json['subjectName'] as String?)?.trim();
          if (name == null || name.isEmpty) {
            return Error(ValidationFailure('AI không trả subjectName.'));
          }
          return Success(
            AiSubjectClassification(
              subjectName: name,
              educationLevel: (json['educationLevel'] as String?)?.trim(),
              topic: (json['topic'] as String?)?.trim(),
              confidence:
                  ((json['confidence'] as num?)?.toDouble() ?? 0.75).clamp(0, 1),
            ),
          );
        } catch (e) {
          return Error(ValidationFailure('JSON phân loại môn không hợp lệ: $e'));
        }
      },
      onFailure: Error.new,
    );
  }

  AiSubjectClassification _classifyHeuristic(String text) {
    final lower = text.toLowerCase();
    final keywords = KeywordExtractor.extract(text, maxKeywords: 8);

    const rules = <String, List<String>>{
      'Toán học': ['toán', 'tích phân', 'đạo hàm', 'phương trình', 'hàm số', 'logarit'],
      'Vật lý': ['vật lý', 'lực', 'điện', 'quang', 'nhiệt', 'newton', 'joule'],
      'Hóa học': ['hóa', 'phản ứng', 'mol', 'ion', 'axit', 'bazơ'],
      'Sinh học': ['sinh', 'tế bào', 'di truyền', 'quang hợp', 'adn'],
      'Ngữ văn': ['văn', 'thơ', 'truyện', 'tác giả', 'nghị luận'],
      'Tiếng Anh': ['english', 'grammar', 'vocabulary', 'tense', 'reading'],
      'Lịch sử': ['lịch sử', 'cách mạng', 'triều đại', 'chiến tranh'],
      'Địa lý': ['địa lý', 'khí hậu', 'dân số', 'kinh tế'],
      'Tin học': ['lập trình', 'algorithm', 'python', 'java', 'code', 'biến'],
      'GDCD': ['gdcd', 'công dân', 'pháp luật', 'hiến pháp'],
    };

    var best = 'Tổng hợp';
    var bestScore = 0.0;

    for (final entry in rules.entries) {
      var score = 0.0;
      for (final kw in entry.value) {
        if (lower.contains(kw)) score += 2;
      }
      for (final kw in keywords) {
        if (entry.value.any((r) => kw.contains(r) || r.contains(kw))) score += 1.5;
      }
      if (score > bestScore) {
        bestScore = score;
        best = entry.key;
      }
    }

    final level = _guessLevel(lower);
    return AiSubjectClassification(
      subjectName: best,
      educationLevel: level,
      topic: keywords.isNotEmpty ? keywords.take(3).join(', ') : null,
      confidence: (bestScore / 6).clamp(0.35, 0.85),
    );
  }

  String? _guessLevel(String lower) {
    final grade = RegExp(r'lớp\s*(\d{1,2})').firstMatch(lower);
    if (grade != null) return 'Lớp ${grade.group(1)}';
    if (lower.contains('đại học') || lower.contains('đh ')) return 'Đại học';
    if (lower.contains('thpt') || lower.contains('trung học')) return 'THPT';
    return null;
  }
}
