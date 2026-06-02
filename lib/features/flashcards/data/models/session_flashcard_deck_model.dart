import 'package:snapstudy/features/flashcards/data/models/flashcard_model.dart';
import 'package:snapstudy/features/flashcards/domain/entities/deck_status.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';

class SessionFlashcardDeckModel {
  const SessionFlashcardDeckModel({
    required this.sessionId,
    required this.title,
    required this.cards,
    required this.status,
    required this.generatedAt,
    this.modelName,
    this.errorMessage,
  });

  factory SessionFlashcardDeckModel.fromJson(Map<String, dynamic> json) {
    final cardsRaw = json['cards'] as List<dynamic>? ?? [];
    return SessionFlashcardDeckModel(
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      cards: cardsRaw
          .map((e) => FlashcardModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      status: DeckStatus.values.byName(json['status'] as String),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      modelName: json['modelName'] as String?,
      errorMessage: json['errorMessage'] as String?,
    );
  }

  final String sessionId;
  final String title;
  final List<FlashcardModel> cards;
  final DeckStatus status;
  final DateTime generatedAt;
  final String? modelName;
  final String? errorMessage;

  Map<String, dynamic> toJson() => {
        'sessionId': sessionId,
        'title': title,
        'cards': cards.map((c) => c.toJson()).toList(),
        'status': status.name,
        'generatedAt': generatedAt.toIso8601String(),
        if (modelName != null) 'modelName': modelName,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  SessionFlashcardDeck toEntity() => SessionFlashcardDeck(
        sessionId: sessionId,
        title: title,
        cards: cards.map((c) => c.toEntity()).toList(),
        status: status,
        generatedAt: generatedAt,
        modelName: modelName,
        errorMessage: errorMessage,
      );

  static SessionFlashcardDeckModel fromEntity(SessionFlashcardDeck deck) =>
      SessionFlashcardDeckModel(
        sessionId: deck.sessionId,
        title: deck.title,
        cards: deck.cards.map(FlashcardModel.fromEntity).toList(),
        status: deck.status,
        generatedAt: deck.generatedAt,
        modelName: deck.modelName,
        errorMessage: deck.errorMessage,
      );
}
