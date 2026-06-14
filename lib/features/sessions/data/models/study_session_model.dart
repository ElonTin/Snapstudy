import 'package:snapstudy/features/ai_summary/data/models/session_ai_summary_model.dart';
import 'package:snapstudy/features/flashcards/data/models/session_flashcard_deck_model.dart';
import 'package:snapstudy/features/mindmap/data/models/session_mindmap_model.dart';
import 'package:snapstudy/features/quiz/data/models/session_quiz_model.dart';
import 'package:snapstudy/features/ocr/data/models/session_ocr_result_model.dart';
import 'package:snapstudy/features/sessions/data/models/capture_queue_item_model.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';

class StudySessionModel {
  const StudySessionModel({
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

  factory StudySessionModel.fromJson(Map<String, dynamic> json) {
    final queueRaw = json['queue'] as List<dynamic>? ?? [];
    return StudySessionModel(
      id: json['id'] as String,
      subjectId: json['subjectId'] as String,
      subjectName: json['subjectName'] as String,
      subjectColorValue: json['subjectColorValue'] as int,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt'] as String)
          : null,
      status: SessionStatus.values.byName(json['status'] as String),
      queue: queueRaw
          .map((e) => CaptureQueueItemModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      aiSummaryReady: json['aiSummaryReady'] as bool? ?? false,
      ocrResult: json['ocrResult'] != null
          ? SessionOcrResultModel.fromJson(
              Map<String, dynamic>.from(json['ocrResult'] as Map),
            )
          : null,
      aiSummary: json['aiSummary'] != null
          ? SessionAiSummaryModel.fromJson(
              Map<String, dynamic>.from(json['aiSummary'] as Map),
            )
          : null,
      flashcardsReady: json['flashcardsReady'] as bool? ?? false,
      flashcardDeck: json['flashcardDeck'] != null
          ? SessionFlashcardDeckModel.fromJson(
              Map<String, dynamic>.from(json['flashcardDeck'] as Map),
            )
          : null,
      quizReady: json['quizReady'] as bool? ?? false,
      sessionQuiz: json['sessionQuiz'] != null
          ? SessionQuizModel.fromJson(
              Map<String, dynamic>.from(json['sessionQuiz'] as Map),
            )
          : null,
      mindmapReady: json['mindmapReady'] as bool? ?? false,
      sessionMindmap: json['sessionMindmap'] != null
          ? SessionMindmapModel.fromJson(
              Map<String, dynamic>.from(json['sessionMindmap'] as Map),
            )
          : null,
      accumulatedElapsedMs: json['accumulatedElapsedMs'] as int? ?? 0,
      timerRunningSince: json['timerRunningSince'] != null
          ? DateTime.parse(json['timerRunningSince'] as String)
          : null,
    );
  }

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
  final List<CaptureQueueItemModel> queue;
  final bool aiSummaryReady;
  final SessionOcrResultModel? ocrResult;
  final SessionAiSummaryModel? aiSummary;
  final bool flashcardsReady;
  final SessionFlashcardDeckModel? flashcardDeck;
  final bool quizReady;
  final SessionQuizModel? sessionQuiz;
  final bool mindmapReady;
  final SessionMindmapModel? sessionMindmap;
  final int accumulatedElapsedMs;
  final DateTime? timerRunningSince;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'subjectName': subjectName,
        'subjectColorValue': subjectColorValue,
        'title': title,
        'notes': notes,
        'tags': tags,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'status': status.name,
        'queue': queue.map((q) => q.toJson()).toList(),
        'aiSummaryReady': aiSummaryReady,
        'accumulatedElapsedMs': accumulatedElapsedMs,
        if (timerRunningSince != null)
          'timerRunningSince': timerRunningSince!.toIso8601String(),
        if (ocrResult != null) 'ocrResult': ocrResult!.toJson(),
        if (aiSummary != null) 'aiSummary': aiSummary!.toJson(),
        'flashcardsReady': flashcardsReady,
        if (flashcardDeck != null) 'flashcardDeck': flashcardDeck!.toJson(),
        'quizReady': quizReady,
        if (sessionQuiz != null) 'sessionQuiz': sessionQuiz!.toJson(),
        'mindmapReady': mindmapReady,
        if (sessionMindmap != null) 'sessionMindmap': sessionMindmap!.toJson(),
      };

  StudySessionModel copyWith({
    String? subjectId,
    String? subjectName,
    int? subjectColorValue,
    String? title,
    String? notes,
    List<String>? tags,
    DateTime? endedAt,
    SessionStatus? status,
    List<CaptureQueueItemModel>? queue,
    bool? aiSummaryReady,
    SessionOcrResultModel? ocrResult,
    SessionAiSummaryModel? aiSummary,
    bool? flashcardsReady,
    SessionFlashcardDeckModel? flashcardDeck,
    bool? quizReady,
    SessionQuizModel? sessionQuiz,
    bool? mindmapReady,
    SessionMindmapModel? sessionMindmap,
    int? accumulatedElapsedMs,
    DateTime? timerRunningSince,
    bool clearTimerRunningSince = false,
  }) {
    return StudySessionModel(
      id: id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      subjectColorValue: subjectColorValue ?? this.subjectColorValue,
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

  StudySession toEntity() => StudySession(
        id: id,
        subjectId: subjectId,
        subjectName: subjectName,
        subjectColorValue: subjectColorValue,
        title: title,
        notes: notes,
        tags: tags,
        startedAt: startedAt,
        endedAt: endedAt,
        status: status,
        queue: queue.map((q) => q.toEntity()).toList(),
        aiSummaryReady: aiSummaryReady,
        ocrResult: ocrResult?.toEntity(),
        aiSummary: aiSummary?.toEntity(),
        flashcardsReady: flashcardsReady,
        flashcardDeck: flashcardDeck?.toEntity(),
        quizReady: quizReady,
        sessionQuiz: sessionQuiz?.toEntity(),
        mindmapReady: mindmapReady,
        sessionMindmap: sessionMindmap?.toEntity(),
        accumulatedElapsedMs: accumulatedElapsedMs,
        timerRunningSince: timerRunningSince,
      );

  static StudySessionModel fromEntity(StudySession session) =>
      StudySessionModel(
        id: session.id,
        subjectId: session.subjectId,
        subjectName: session.subjectName,
        subjectColorValue: session.subjectColorValue,
        title: session.title,
        notes: session.notes,
        tags: session.tags,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
        status: session.status,
        queue: session.queue.map(CaptureQueueItemModel.fromEntity).toList(),
        aiSummaryReady: session.aiSummaryReady,
        ocrResult: session.ocrResult != null
            ? SessionOcrResultModel.fromEntity(session.ocrResult!)
            : null,
        aiSummary: session.aiSummary != null
            ? SessionAiSummaryModel.fromEntity(session.aiSummary!)
            : null,
        flashcardsReady: session.flashcardsReady,
        flashcardDeck: session.flashcardDeck != null
            ? SessionFlashcardDeckModel.fromEntity(session.flashcardDeck!)
            : null,
        quizReady: session.quizReady,
        sessionQuiz: session.sessionQuiz != null
            ? SessionQuizModel.fromEntity(session.sessionQuiz!)
            : null,
        mindmapReady: session.mindmapReady,
        sessionMindmap: session.sessionMindmap != null
            ? SessionMindmapModel.fromEntity(session.sessionMindmap!)
            : null,
        accumulatedElapsedMs: session.accumulatedElapsedMs,
        timerRunningSince: session.timerRunningSince,
      );
}
