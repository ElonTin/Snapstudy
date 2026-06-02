import 'package:flutter_test/flutter_test.dart';
import 'package:snapstudy/features/quiz/data/services/quiz_json_parser.dart';
import 'package:snapstudy/features/quiz/domain/entities/quiz_difficulty.dart';

void main() {
  const validJson = '''
{
  "title": "Quiz Toán",
  "defaultDifficulty": "medium",
  "questions": [
    {
      "prompt": "Câu 1?",
      "choices": ["A", "B", "C", "D"],
      "correctIndex": 0,
      "explanation": "Vì A đúng",
      "difficulty": "easy"
    },
    {
      "prompt": "Câu 2?",
      "choices": ["X", "Y", "Z", "W"],
      "correctIndex": 1,
      "explanation": "Vì B đúng",
      "difficulty": "medium"
    },
    {
      "prompt": "Câu 3?",
      "choices": ["1", "2", "3", "4"],
      "correctIndex": 2,
      "explanation": "Vì C đúng",
      "difficulty": "hard"
    },
    {
      "prompt": "Câu 4?",
      "choices": ["p", "q", "r", "s"],
      "correctIndex": 3,
      "explanation": "Vì D đúng",
      "difficulty": "medium"
    },
    {
      "prompt": "Câu 5?",
      "choices": ["m", "n", "o", "p"],
      "correctIndex": 0,
      "explanation": "Giải thích",
      "difficulty": "easy"
    }
  ]
}
''';

  test('parse valid quiz JSON', () {
    final result = QuizJsonParser.parse(
      sessionId: 's1',
      rawJson: validJson,
    );
    expect(result.isSuccess, isTrue);
    final quiz = result.valueOrNull!;
    expect(quiz.title, 'Quiz Toán');
    expect(quiz.questions.length, 5);
    expect(quiz.defaultDifficulty, QuizDifficulty.medium);
    expect(quiz.questions.first.correctIndex, 0);
  });

  test('rejects duplicate choices', () {
    const json = '''
{
  "title": "Bad",
  "questions": [
    {
      "prompt": "Q?",
      "choices": ["A", "A", "C", "D"],
      "correctIndex": 0,
      "explanation": "x",
      "difficulty": "easy"
    }
  ]
}
''';
    final result = QuizJsonParser.parse(sessionId: 's1', rawJson: json);
    expect(result.isSuccess, isFalse);
  });

  test('rejects fewer than 5 valid questions', () {
    const json = '''
{
  "title": "Short",
  "questions": [
    {
      "prompt": "Only one?",
      "choices": ["A", "B", "C", "D"],
      "correctIndex": 0,
      "explanation": "ok",
      "difficulty": "easy"
    }
  ]
}
''';
    final result = QuizJsonParser.parse(sessionId: 's1', rawJson: json);
    expect(result.isSuccess, isFalse);
  });
}
