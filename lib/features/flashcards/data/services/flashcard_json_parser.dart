import 'dart:convert';

import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/flashcards/domain/entities/deck_status.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/flashcards/domain/services/sm2_scheduler.dart';

abstract final class FlashcardJsonParser {
  static Result<SessionFlashcardDeck> parse({
    required String sessionId,
    required String rawJson,
    String? modelName,
  }) {
    try {
      var text = rawJson.trim();
      if (text.startsWith('```')) {
        text = text
            .replaceFirst(RegExp(r'^```(?:json)?\s*', multiLine: true), '')
            .replaceFirst(RegExp(r'\s*```$'), '')
            .trim();
      }

      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        return const Error(
          ValidationFailure('Phản hồi flashcard không phải JSON object.'),
        );
      }

      final title = decoded['title'];
      if (title is! String || title.trim().isEmpty) {
        return const Error(ValidationFailure('Thiếu trường "title".'));
      }

      final cardsRaw = decoded['cards'];
      if (cardsRaw is! List || cardsRaw.isEmpty) {
        return const Error(ValidationFailure('Cần ít nhất 1 thẻ trong "cards".'));
      }

      final cards = <Flashcard>[];
      for (var i = 0; i < cardsRaw.length && i < 20; i++) {
        final item = cardsRaw[i];
        if (item is! Map<String, dynamic>) continue;
        final front = item['front'];
        final back = item['back'];
        if (front is! String ||
            back is! String ||
            front.trim().isEmpty ||
            back.trim().isEmpty) {
          continue;
        }
        final hint = item['hint'] is String ? (item['hint'] as String).trim() : null;
        final tags = (item['tags'] as List<dynamic>?)
                ?.whereType<String>()
                .map((t) => t.trim())
                .where((t) => t.isNotEmpty)
                .take(4)
                .toList() ??
            [];

        final card = Sm2Scheduler.scheduleNew(
          Flashcard(
            id: 'fc_${sessionId}_${i + 1}',
            front: front.trim(),
            back: back.trim(),
            hint: hint != null && hint.isNotEmpty ? hint : null,
            tags: tags,
          ),
        );
        cards.add(card);
      }

      if (cards.length < 3) {
        return const Error(
          ValidationFailure('Cần ít nhất 3 thẻ flashcard hợp lệ.'),
        );
      }

      return Success(
        SessionFlashcardDeck(
          sessionId: sessionId,
          title: title.trim(),
          cards: cards,
          status: DeckStatus.completed,
          generatedAt: DateTime.now(),
          modelName: modelName,
        ),
      );
    } catch (e) {
      return Error(ValidationFailure('JSON flashcard không hợp lệ: $e'));
    }
  }
}
