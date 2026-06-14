import 'package:snapstudy/core/cache/performance_caches.dart';
import 'package:snapstudy/core/cache/session_list_cache.dart';
import 'package:snapstudy/core/errors/app_exception.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/ai_summary/data/models/session_ai_summary_model.dart';
import 'package:snapstudy/features/ai_summary/domain/entities/session_ai_summary.dart';
import 'package:snapstudy/features/flashcards/data/models/session_flashcard_deck_model.dart';
import 'package:snapstudy/features/flashcards/domain/entities/session_flashcard_deck.dart';
import 'package:snapstudy/features/mindmap/data/models/session_mindmap_model.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/quiz/data/models/session_quiz_model.dart';
import 'package:snapstudy/features/quiz/domain/entities/session_quiz.dart';
import 'package:snapstudy/features/ocr/data/models/session_ocr_result_model.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/sessions/data/datasources/session_local_datasource.dart';
import 'package:snapstudy/features/sessions/data/models/capture_queue_item_model.dart';
import 'package:snapstudy/features/sessions/data/models/study_session_model.dart';
import 'package:snapstudy/features/sessions/data/services/session_file_storage.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl({
    required SessionLocalDataSource local,
    required SessionFileStorage fileStorage,
  })  : _local = local,
        _files = fileStorage;

  final SessionLocalDataSource _local;
  final SessionFileStorage _files;

  Future<void> _save(StudySessionModel model) async {
    await _local.upsert(model);
    PerformanceCaches.invalidateAll();
  }

  String _newId() => 'ses_${DateTime.now().millisecondsSinceEpoch}';

  List<String> _buildAutoTags(Subject subject) => [
        subject.name,
        'snapstudy',
        DateTime.now().weekday <= 5 ? 'weekday' : 'weekend',
      ];

  StudySessionModel _flushRunningTimer(StudySessionModel session) {
    if (session.timerRunningSince == null) return session;
    final extra = DateTime.now()
        .difference(session.timerRunningSince!)
        .inMilliseconds;
    return session.copyWith(
      accumulatedElapsedMs: session.accumulatedElapsedMs + extra,
      clearTimerRunningSince: true,
    );
  }

  @override
  Future<Result<StudySession?>> pauseActiveSessionTimer() async {
    try {
      final activeId = _local.readActiveSessionId();
      if (activeId == null) return const Success(null);

      final model = await _local.readById(activeId);
      if (model == null || model.status != SessionStatus.active) {
        return const Success(null);
      }
      if (model.timerRunningSince == null) {
        return Success(model.toEntity());
      }

      final paused = _flushRunningTimer(model);
      await _save(paused);
      return Success(paused.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession?>> resumeActiveSessionTimer() async {
    try {
      final activeId = _local.readActiveSessionId();
      if (activeId == null) return const Success(null);

      final model = await _local.readById(activeId);
      if (model == null || model.status != SessionStatus.active) {
        return const Success(null);
      }
      if (model.timerRunningSince != null) {
        return Success(model.toEntity());
      }

      final resumed = model.copyWith(timerRunningSince: DateTime.now());
      await _save(resumed);
      return Success(resumed.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<StudySession>>> getAllSessions() async {
    try {
      final cached = SessionListCache.get();
      if (cached != null) return Success(cached);

      final models = await _local.readAll();
      final sessions = models.map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      SessionListCache.put(sessions);
      return Success(sessions);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<List<StudySession>>> getRecentSessions({int limit = 10}) async {
    final all = await getAllSessions();
    return all.fold(
      onSuccess: (list) => Success(
        list
            .where((s) => s.status != SessionStatus.active)
            .take(limit)
            .toList(),
      ),
      onFailure: Error.new,
    );
  }

  @override
  Future<Result<StudySession?>> getActiveSession() async {
    try {
      final activeId = _local.readActiveSessionId();
      if (activeId == null) return const Success(null);
      return getSessionById(activeId);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession?>> getSessionById(String id) async {
    try {
      final cached = SessionListCache.get();
      if (cached != null) {
        final hit = cached.where((s) => s.id == id).firstOrNull;
        if (hit != null) return Success(hit);
      }

      final model = await _local.readById(id);
      return Success(model?.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> startSession({
    required Subject subject,
    required String title,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final active = await getActiveSession();
      if (active.valueOrNull != null) {
        return const Error(
          ValidationFailure('Đã có buổi học đang diễn ra. Hãy kết thúc trước.'),
        );
      }

      if (title.trim().isEmpty) {
        return const Error(ValidationFailure('Tiêu đề buổi học không được trống.'));
      }

      final now = DateTime.now();
      final session = StudySessionModel(
        id: _newId(),
        subjectId: subject.id,
        subjectName: subject.name,
        subjectColorValue: subject.colorValue,
        title: title.trim(),
        notes: notes?.trim(),
        tags: tags ?? _buildAutoTags(subject),
        startedAt: now,
        status: SessionStatus.active,
        timerRunningSince: now,
      );

      await _save(session);
      await _local.writeActiveSessionId(session.id);

      return Success(session.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> addCaptureToQueue({
    required String sessionId,
    required String imagePath,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }
      if (session.status != SessionStatus.active) {
        return const Error(ValidationFailure('Buổi học không còn hoạt động.'));
      }

      final savedPath = await _files.saveCaptureFromPath(imagePath, sessionId);
      final thumbPath = await _files.generateThumbnail(savedPath, sessionId);
      final item = CaptureQueueItemModel(
        id: 'cap_${DateTime.now().millisecondsSinceEpoch}',
        localPath: savedPath,
        thumbnailPath: thumbPath,
        capturedAt: DateTime.now(),
        status: CaptureItemStatus.pending,
      );

      final updated = session.copyWith(queue: [...session.queue, item]);
      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> removeFromQueue({
    required String sessionId,
    required String itemId,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      final item = session.queue.where((q) => q.id == itemId).firstOrNull;
      if (item != null) await _files.deleteFile(item.localPath);

      final updated = session.copyWith(
        queue: session.queue.where((q) => q.id != itemId).toList(),
      );
      await _save(updated);
      return const Success(null);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> endSession(String sessionId) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      final flushed = _flushRunningTimer(session);
      final ended = flushed.copyWith(
        endedAt: DateTime.now(),
        status: flushed.queue.isEmpty
            ? SessionStatus.draft
            : SessionStatus.ready,
        aiSummaryReady: false,
      );

      await _save(ended);
      await _local.writeActiveSessionId(null);
      return Success(ended.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> applyOcrResult({
    required String sessionId,
    required SessionOcrResult ocrResult,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      final syncedQueue = session.queue.map((item) {
        final captureOcr = ocrResult.captures
            .where((c) => c.captureId == item.id)
            .firstOrNull;
        final synced = captureOcr?.isSuccess ?? false;
        return CaptureQueueItemModel(
          id: item.id,
          localPath: item.localPath,
          thumbnailPath: item.thumbnailPath,
          capturedAt: item.capturedAt,
          status: synced ? CaptureItemStatus.synced : item.status,
        );
      }).toList();

      final updated = session.copyWith(
        status: SessionStatus.ready,
        queue: syncedQueue,
        ocrResult: SessionOcrResultModel.fromEntity(ocrResult),
      );

      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> applyAiSummary({
    required String sessionId,
    required SessionAiSummary summary,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      final updated = session.copyWith(
        status: SessionStatus.completed,
        aiSummaryReady: summary.isReady,
        aiSummary: SessionAiSummaryModel.fromEntity(summary),
      );

      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> applyFlashcardDeck({
    required String sessionId,
    required SessionFlashcardDeck deck,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      final updated = session.copyWith(
        flashcardsReady: deck.isReady,
        flashcardDeck: SessionFlashcardDeckModel.fromEntity(deck),
      );

      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> applySessionQuiz({
    required String sessionId,
    required SessionQuiz quiz,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      final updated = session.copyWith(
        quizReady: quiz.isReady,
        sessionQuiz: SessionQuizModel.fromEntity(quiz),
      );

      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> applySessionMindmap({
    required String sessionId,
    required SessionMindmap mindmap,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      final updated = session.copyWith(
        mindmapReady: mindmap.isReady,
        sessionMindmap: SessionMindmapModel.fromEntity(mindmap),
      );

      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> updateSessionSubject({
    required String sessionId,
    required Subject subject,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      final updated = session.copyWith(
        subjectId: subject.id,
        subjectName: subject.name,
        subjectColorValue: subject.colorValue,
        tags: _buildAutoTags(subject),
      );

      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> setSessionProcessing({
    required String sessionId,
    required bool processing,
  }) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }

      if (session.status == SessionStatus.active) {
        return Success(session.toEntity());
      }

      final updated = session.copyWith(
        status: processing ? SessionStatus.processing : _statusAfterProcessing(session),
      );

      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  SessionStatus _statusAfterProcessing(StudySessionModel session) {
    if (session.aiSummaryReady) return SessionStatus.completed;
    if (session.ocrResult != null) return SessionStatus.ready;
    return session.endedAt != null ? SessionStatus.ready : SessionStatus.draft;
  }

  @override
  Future<Result<StudySession>> appendCaptures({
    required String sessionId,
    required List<String> imagePaths,
  }) async {
    try {
      if (imagePaths.isEmpty) {
        return const Error(ValidationFailure('Không có ảnh để thêm.'));
      }

      var session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }
      if (session.status == SessionStatus.active) {
        return const Error(
          ValidationFailure('Buổi đang chụp — dùng màn hình buổi học đang diễn ra.'),
        );
      }

      final newItems = <CaptureQueueItemModel>[];
      for (final path in imagePaths) {
        final savedPath = await _files.saveCaptureFromPath(path, sessionId);
        final thumbPath = await _files.generateThumbnail(savedPath, sessionId);
        newItems.add(
          CaptureQueueItemModel(
            id: 'cap_${DateTime.now().millisecondsSinceEpoch}_${newItems.length}',
            localPath: savedPath,
            thumbnailPath: thumbPath,
            capturedAt: DateTime.now(),
            status: CaptureItemStatus.pending,
          ),
        );
      }

      session = session.copyWith(
        queue: [...session.queue, ...newItems],
        status: SessionStatus.processing,
      );
      await _save(session);
      return Success(session.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> beginStudyEngagement(String sessionId) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }
      if (session.timerRunningSince != null) {
        return Success(session.toEntity());
      }

      final updated = session.copyWith(timerRunningSince: DateTime.now());
      await _save(updated);
      return Success(updated.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<StudySession>> endStudyEngagement(String sessionId) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) {
        return const Error(ValidationFailure('Không tìm thấy buổi học.'));
      }
      if (session.timerRunningSince == null) {
        return Success(session.toEntity());
      }

      final flushed = _flushRunningTimer(session);
      await _save(flushed);
      return Success(flushed.toEntity());
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Result<void>> cancelSession(String sessionId) async {
    try {
      final session = await _local.readById(sessionId);
      if (session == null) return const Success(null);

      for (final item in session.queue) {
        await _files.deleteFile(item.localPath);
      }
      await _local.delete(sessionId);
      PerformanceCaches.invalidateAll();

      if (_local.readActiveSessionId() == sessionId) {
        await _local.writeActiveSessionId(null);
      }
      return const Success(null);
    } on AppException catch (e) {
      return Error(e.toFailure());
    } catch (e) {
      return Error(UnknownFailure(e.toString()));
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
