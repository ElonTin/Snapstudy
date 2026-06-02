import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/flashcards/domain/entities/deck_status.dart';
import 'package:snapstudy/features/flashcards/domain/entities/flashcard.dart';

/// Flashcard deck generated for one study session (Phase 10).
class SessionFlashcardDeck extends Equatable {
  const SessionFlashcardDeck({
    required this.sessionId,
    required this.title,
    required this.cards,
    required this.status,
    required this.generatedAt,
    this.modelName,
    this.errorMessage,
  });

  final String sessionId;
  final String title;
  final List<Flashcard> cards;
  final DeckStatus status;
  final DateTime generatedAt;
  final String? modelName;
  final String? errorMessage;

  bool get isReady => status == DeckStatus.completed && cards.isNotEmpty;

  int get dueCount => cards.where((c) => c.isDue).length;

  @override
  List<Object?> get props => [
        sessionId,
        title,
        cards,
        status,
        generatedAt,
        modelName,
        errorMessage,
      ];
}
