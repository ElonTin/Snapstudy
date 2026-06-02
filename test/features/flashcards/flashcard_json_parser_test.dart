import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/flashcards/data/services/flashcard_json_parser.dart';
import 'package:snapstudy/features/flashcards/domain/entities/deck_status.dart';

void main() {
  test('parse valid flashcard deck JSON', () {
    const raw = '''
{
  "title": "Đạo hàm cơ bản",
  "cards": [
    {"front": "Đạo hàm là gì?", "back": "Tốc độ thay đổi", "hint": "", "tags": ["toán"]},
    {"front": "f'(x)", "back": "Đạo hàm của f", "tags": []},
    {"front": "Quy tắc chuỗi", "back": "Chain rule", "tags": ["rule"]}
  ]
}
''';

    final result = FlashcardJsonParser.parse(
      sessionId: 'ses-1',
      rawJson: raw,
    );

    expect(result.isSuccess, true);
    final deck = result.valueOrNull!;
    expect(deck.sessionId, 'ses-1');
    expect(deck.cards.length, 3);
    expect(deck.status, DeckStatus.completed);
    expect(deck.cards.first.isDue, true);
  });

  test('parse fails with too few cards', () {
    const raw = '''
{"title": "X", "cards": [{"front": "a", "back": "b"}]}
''';
    final result = FlashcardJsonParser.parse(sessionId: 's', rawJson: raw);
    expect(result.isFailure, true);
  });
}
