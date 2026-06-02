import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

abstract interface class SessionRepository {
  Future<Result<List<StudySession>>> getAllSessions();

  Future<Result<List<StudySession>>> getRecentSessions({int limit = 10});

  Future<Result<StudySession?>> getActiveSession();

  Future<Result<StudySession?>> getSessionById(String id);

  Future<Result<StudySession>> startSession({
    required Subject subject,
    required String title,
    String? notes,
    List<String>? tags,
  });

  Future<Result<StudySession>> addCaptureToQueue({
    required String sessionId,
    required String imagePath,
  });

  Future<Result<void>> removeFromQueue({
    required String sessionId,
    required String itemId,
  });

  Future<Result<StudySession>> endSession(String sessionId);

  Future<Result<void>> cancelSession(String sessionId);

  Future<Result<StudySession>> applyOcrResult({
    required String sessionId,
    required SessionOcrResult ocrResult,
  });

  Future<Result<StudySession>> applyAiSummary({
    required String sessionId,
    required SessionAiSummary summary,
  });

  Future<Result<StudySession>> applyFlashcardDeck({
    required String sessionId,
    required SessionFlashcardDeck deck,
  });

  Future<Result<StudySession>> applySessionQuiz({
    required String sessionId,
    required SessionQuiz quiz,
  });

  Future<Result<StudySession>> applySessionMindmap({
    required String sessionId,
    required SessionMindmap mindmap,
  });

  /// Flushes running segment into [accumulatedElapsedMs] and stops the clock.
  Future<Result<StudySession?>> pauseActiveSessionTimer();

  /// Starts the in-app clock (only while app is in foreground).
  Future<Result<StudySession?>> resumeActiveSessionTimer();
}
