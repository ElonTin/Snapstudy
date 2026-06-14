import 'dart:convert';

import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/session_weak_areas_insight.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_item.dart';
import 'package:snapstudy/features/weak_areas/domain/entities/weak_area_source.dart';

abstract final class WeakAreasAiParser {
  WeakAreasAiParser._();

  static Result<SessionWeakAreasInsight> parse(
    String rawJson,
    List<WeakAreaItem> fallbackItems,
  ) {
    try {
      final map = jsonDecode(rawJson) as Map<String, dynamic>;
      final advice = map['aiAdvice'] as String? ?? '';
      final topics = map['focusTopics'] as List<dynamic>? ?? [];

      final items = <WeakAreaItem>[];
      for (final t in topics) {
        if (t is! Map<String, dynamic>) continue;
        final label = t['label'] as String?;
        if (label == null || label.isEmpty) continue;
        items.add(
          WeakAreaItem(
            label: label,
            reason: t['reason'] as String? ?? 'AI gợi ý ôn tập',
            source: WeakAreaSource.flashcard,
            priorityScore: 50,
          ),
        );
      }

      return Success(
        SessionWeakAreasInsight(
          items: items.isNotEmpty ? items : fallbackItems,
          aiAdvice: advice.isNotEmpty
              ? advice
              : 'Hãy ôn lại các phần bạn vừa sai hoặc đánh dấu khó.',
          generatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      return Error(ValidationFailure('Không parse được gợi ý AI: $e'));
    }
  }
}
