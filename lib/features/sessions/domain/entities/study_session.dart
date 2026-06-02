import 'package:equatable/equatable.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/capture_queue_item.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';

/// Full study session with metadata and capture queue.
class StudySession extends Equatable {
  const StudySession({
    required this.id,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColorValue,
    required this.title,
    required this.startedAt,
    required this.status,
    this.notes,
    this.tags = const [],
    this.endedAt,
    this.queue = const [],
    this.aiSummaryReady = false,
    this.ocrResult,
    this.aiSummary,
    this.flashcardsReady = false,
    this.flashcardDeck,
    this.quizReady = false,
    this.sessionQuiz,
    this.mindmapReady = false,
    this.sessionMindmap,
    this.accumulatedElapsedMs = 0,
    this.timerRunningSince,
  });

  final String id;
  final String subjectId;
  final String subjectName;
  final int subjectColorValue;
  final String title;
  final String? notes;
  final List<String> tags;
  final DateTime startedAt;
  final DateTime? endedAt;
  final SessionStatus status;
  final List<CaptureQueueItem> queue;
  final bool aiSummaryReady;
  final SessionOcrResult? ocrResult;
  final SessionAiSummary? aiSummary;
  final bool flashcardsReady;
  final SessionFlashcardDeck? flashcardDeck;
  final bool quizReady;
  final SessionQuiz? sessionQuiz;
  final bool mindmapReady;
  final SessionMindmap? sessionMindmap;

  /// Elapsed study time excluding background / app-closed periods.
  final int accumulatedElapsedMs;

  /// Non-null while the in-app timer is actively ticking.
  final DateTime? timerRunningSince;

  int get photoCount => queue.length;

  bool get ocrReady =>
      ocrResult != null &&
      (ocrResult!.status == OcrStatus.completed ||
          ocrResult!.status == OcrStatus.partial);

  Duration get elapsed {
    var ms = accumulatedElapsedMs;
    if (isActive && timerRunningSince != null) {
      ms += DateTime.now().difference(timerRunningSince!).inMilliseconds;
    } else if (endedAt != null && accumulatedElapsedMs == 0) {
      return endedAt!.difference(startedAt);
    }
    return Duration(milliseconds: ms);
  }

  bool get isTimerRunning => isActive && timerRunningSince != null;

  bool get isActive => status == SessionStatus.active;

  StudySession copyWith({
    String? title,
    String? notes,
    List<String>? tags,
    DateTime? endedAt,
    SessionStatus? status,
    List<CaptureQueueItem>? queue,
    bool? aiSummaryReady,
    SessionOcrResult? ocrResult,
    SessionAiSummary? aiSummary,
    bool? flashcardsReady,
    SessionFlashcardDeck? flashcardDeck,
    bool? quizReady,
    SessionQuiz? sessionQuiz,
    bool? mindmapReady,
    SessionMindmap? sessionMindmap,
    int? accumulatedElapsedMs,
    DateTime? timerRunningSince,
    bool clearTimerRunningSince = false,
  }) {
    return StudySession(
      id: id,
      subjectId: subjectId,
      subjectName: subjectName,
      subjectColorValue: subjectColorValue,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      tags: tags ?? this.tags,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      status: status ?? this.status,
      queue: queue ?? this.queue,
      aiSummaryReady: aiSummaryReady ?? this.aiSummaryReady,
      ocrResult: ocrResult ?? this.ocrResult,
      aiSummary: aiSummary ?? this.aiSummary,
      flashcardsReady: flashcardsReady ?? this.flashcardsReady,
      flashcardDeck: flashcardDeck ?? this.flashcardDeck,
      quizReady: quizReady ?? this.quizReady,
      sessionQuiz: sessionQuiz ?? this.sessionQuiz,
      mindmapReady: mindmapReady ?? this.mindmapReady,
      sessionMindmap: sessionMindmap ?? this.sessionMindmap,
      accumulatedElapsedMs:
          accumulatedElapsedMs ?? this.accumulatedElapsedMs,
      timerRunningSince: clearTimerRunningSince
          ? null
          : (timerRunningSince ?? this.timerRunningSince),
    );
  }

  @override
  List<Object?> get props => [
        id,
        subjectId,
        subjectName,
        subjectColorValue,
        title,
        notes,
        tags,
        startedAt,
        endedAt,
        status,
        queue,
        aiSummaryReady,
        ocrResult,
        aiSummary,
        flashcardsReady,
        flashcardDeck,
        quizReady,
        sessionQuiz,
        mindmapReady,
        sessionMindmap,
        accumulatedElapsedMs,
        timerRunningSince,
      ];
}
