import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/home/domain/entities/ai_activity_item.dart';
import 'package:snapstudy/features/home/domain/entities/dashboard_data.dart';
import 'package:snapstudy/features/home/domain/entities/recent_session.dart'
    as home;
import 'package:snapstudy/features/home/domain/entities/study_progress.dart';
import 'package:snapstudy/features/home/domain/entities/subject_summary.dart';
import 'package:snapstudy/features/home/domain/entities/upcoming_review.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart'
    as sessions;
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_display_labels.dart';
import 'package:snapstudy/features/spaced_repetition/domain/repositories/spaced_repetition_repository.dart';
import 'package:snapstudy/features/subjects/domain/repositories/subject_repository.dart';

/// Dashboard data — subjects & sessions from local repositories.
class DashboardLocalDataSource {
  DashboardLocalDataSource(
    this._subjectRepository,
    this._sessionRepository,
    this._spacedRepetition,
  );

  final SubjectRepository _subjectRepository;
  final SessionRepository _sessionRepository;
  final SpacedRepetitionRepository _spacedRepetition;

  Future<DashboardData> fetchDashboard() async {
    final now = DateTime.now();
    final subjectsResult = await _subjectRepository.getSubjects();
    final subjects = subjectsResult.fold(
      onSuccess: (list) => list
          .map(
            (s) => SubjectSummary(
              id: s.id,
              name: s.name,
              colorValue: s.colorValue,
              iconCodePoint: s.iconCodePoint,
              sessionCount: s.sessionCount,
              pendingReviews: s.pendingReviews,
            ),
          )
          .toList(),
      onFailure: (_) => <SubjectSummary>[],
    );

    final allSessionsResult = await _sessionRepository.getAllSessions();
    final allSessions =
        allSessionsResult.fold(onSuccess: (list) => list, onFailure: (_) => <StudySession>[]);

    final recentSessions = allSessions
        .where((s) => s.status != sessions.SessionStatus.active)
        .take(5)
        .map(
          (s) => home.RecentSession(
            id: s.id,
            title: SessionDisplayLabels.title(s),
            subjectName: s.subjectName,
            subtitle: SessionDisplayLabels.subtitle(s),
            subjectColorValue: s.subjectColorValue,
            photoCount: s.photoCount,
            startedAt: s.startedAt,
            status: _mapStatus(s.status),
            aiSummaryReady: s.aiSummaryReady,
          ),
        )
        .toList();

    final sessionsThisWeek = allSessionsResult.fold(
      onSuccess: (list) => list
          .where(
            (s) => s.startedAt.isAfter(
              now.subtract(const Duration(days: 7)),
            ),
          )
          .length,
      onFailure: (_) => 0,
    );

    final srStats = await _spacedRepetition.getStats();
    final stats = srStats.fold(
      onSuccess: (s) => s,
      onFailure: (_) => null,
    );

    return DashboardData(
      progress: StudyProgress(
        sessionsThisWeek: sessionsThisWeek,
        cardsReviewed: stats?.reviewedToday ?? 0,
        studyMinutesToday: stats?.reviewedToday ?? 0,
        streakDays: stats?.studyStreakDays ?? 0,
        weeklyGoalPercent: (stats?.retentionPercent ?? 72) / 100,
      ),
      subjects: subjects,
      recentSessions: recentSessions,
      aiActivities: _buildAiActivities(recentSessions, allSessions, now),
      upcomingReviews: _buildUpcomingReviews(allSessions, now),
    );
  }

  List<AiActivityItem> _buildAiActivities(
    List<home.RecentSession> recent,
    List<StudySession> allSessions,
    DateTime now,
  ) {
    final byId = {for (final s in allSessions) s.id: s};

    final withMindmap = recent.where((r) {
      final full = byId[r.id];
      return full?.mindmapReady == true;
    }).toList();
    if (withMindmap.isNotEmpty) {
      final r = withMindmap.first;
      final map = byId[r.id]?.sessionMindmap;
      return [
        AiActivityItem(
          id: 'mindmap-${r.id}',
          title: 'Mindmap: ${map?.title ?? r.title}',
          subtitle:
              '${map?.nodes.length ?? 0} nút · ${map?.clusters.length ?? 0} cụm',
          type: AiActivityType.mindmap,
          createdAt: map?.generatedAt ?? r.startedAt,
          isCompleted: true,
        ),
      ];
    }

    final withQuiz = recent.where((r) {
      final full = byId[r.id];
      return full?.quizReady == true;
    }).toList();
    if (withQuiz.isNotEmpty) {
      final r = withQuiz.first;
      final quiz = byId[r.id]?.sessionQuiz;
      final last = quiz?.lastResult;
      return [
        AiActivityItem(
          id: 'quiz-${r.id}',
          title: 'Quiz: ${quiz?.title ?? r.title}',
          subtitle: last != null
              ? 'Điểm ${last.scorePercent}% · ${quiz?.questions.length ?? 0} câu'
              : '${quiz?.questions.length ?? 0} câu · sẵn sàng làm bài',
          type: AiActivityType.quiz,
          createdAt: quiz?.generatedAt ?? r.startedAt,
          isCompleted: last != null,
        ),
      ];
    }

    final withFlashcards = recent.where((r) {
      final full = byId[r.id];
      return full?.flashcardsReady == true;
    }).toList();
    if (withFlashcards.isNotEmpty) {
      final r = withFlashcards.first;
      final deck = byId[r.id]?.flashcardDeck;
      return [
        AiActivityItem(
          id: 'flashcards-${r.id}',
          title: 'Flashcard: ${deck?.title ?? r.title}',
          subtitle:
              '${deck?.cards.length ?? 0} thẻ · ${deck?.dueCount ?? 0} cần ôn',
          type: AiActivityType.flashcards,
          createdAt: deck?.generatedAt ?? r.startedAt,
          isCompleted: true,
        ),
      ];
    }

    final withSummary = recent.where((r) => r.aiSummaryReady).toList();
    if (withSummary.isNotEmpty) {
      final r = withSummary.first;
      final full = byId[r.id];
      final summary = full?.aiSummary;
      return [
        AiActivityItem(
          id: 'summary-${r.id}',
          title: 'Tóm tắt: ${summary?.detectedTopic ?? r.title}',
          subtitle: summary?.overview ??
              '${r.subjectName} · tóm tắt AI đã sẵn sàng',
          type: AiActivityType.summary,
          createdAt: summary?.generatedAt ?? r.startedAt,
          isCompleted: true,
        ),
        AiActivityItem(
          id: 'flashcards-pending-${r.id}',
          title: 'Flashcard',
          subtitle: 'Đang chờ hoặc tạo từ buổi học',
          type: AiActivityType.flashcards,
          createdAt: now,
          isCompleted: false,
        ),
        AiActivityItem(
          id: 'quiz-pending-${r.id}',
          title: 'Quiz trắc nghiệm',
          subtitle: 'Tự động sau flashcard hoặc tạo thủ công',
          type: AiActivityType.quiz,
          createdAt: now,
          isCompleted: false,
        ),
        AiActivityItem(
          id: 'mindmap-pending-${r.id}',
          title: 'Mindmap',
          subtitle: 'Tự động sau quiz hoặc tạo thủ công',
          type: AiActivityType.mindmap,
          createdAt: now,
          isCompleted: false,
        ),
      ];
    }

    final withOcr = recent
        .where((s) => s.status == home.SessionStatus.ready)
        .toList();
    if (withOcr.isNotEmpty) {
      final s = withOcr.first;
      return [
        AiActivityItem(
          id: 'ocr-${s.id}',
          title: 'OCR: ${s.title}',
          subtitle: '${s.photoCount} ảnh · văn bản đã trích xuất',
          type: AiActivityType.ocr,
          createdAt: s.startedAt,
          isCompleted: true,
        ),
        AiActivityItem(
          id: 'ai-summary-${s.id}',
          title: 'Tóm tắt AI',
          subtitle: 'Đang chờ hoặc chưa tạo — mở buổi học để tạo',
          type: AiActivityType.summary,
          createdAt: now,
          isCompleted: false,
        ),
      ];
    }

    return [
      AiActivityItem(
        id: 'ai-ocr-hint',
        title: 'Nhận dạng văn bản',
        subtitle: 'Kết thúc buổi học để chạy OCR',
        type: AiActivityType.ocr,
        createdAt: now,
        isCompleted: false,
      ),
    ];
  }

  List<UpcomingReview> _buildUpcomingReviews(
    List<StudySession> sessions,
    DateTime now,
  ) {
    final reviews = <UpcomingReview>[];
    for (final s in sessions) {
      final deck = s.flashcardDeck;
      if (deck == null || !deck.isReady) continue;
      final due = deck.dueCount;
      if (due == 0) continue;
      final earliest = deck.cards
          .where((c) => c.isDue)
          .map((c) => c.nextReviewAt ?? now)
          .fold<DateTime>(now, (a, b) => a.isBefore(b) ? a : b);
      reviews.add(
        UpcomingReview(
          id: 'rev-${s.id}',
          sessionId: s.id,
          deckName: deck.title,
          subjectName: s.subjectName,
          cardCount: due,
          dueAt: earliest,
          subjectColorValue: s.subjectColorValue,
        ),
      );
    }
    reviews.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    if (reviews.isNotEmpty) return reviews.take(3).toList();

    return [
      UpcomingReview(
        id: 'rev-hint',
        sessionId: '',
        deckName: 'Chưa có thẻ đến hạn',
        subjectName: 'Hoàn tất OCR + AI để tạo flashcard',
        cardCount: 0,
        dueAt: now.add(const Duration(days: 1)),
        subjectColorValue: AppColors.primary.toARGB32(),
      ),
    ];
  }

  home.SessionStatus _mapStatus(sessions.SessionStatus status) {
    switch (status) {
      case sessions.SessionStatus.processing:
        return home.SessionStatus.processing;
      case sessions.SessionStatus.ready:
      case sessions.SessionStatus.completed:
        return home.SessionStatus.ready;
      case sessions.SessionStatus.draft:
      case sessions.SessionStatus.active:
        return home.SessionStatus.draft;
    }
  }
}
