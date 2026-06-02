import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/notifications/notification_channels.dart';
import 'package:snapstudy/core/notifications/notification_payload.dart';
import 'package:snapstudy/core/utils/result.dart';
import 'package:snapstudy/features/notifications/data/datasources/notification_prefs_datasource.dart';
import 'package:snapstudy/features/notifications/data/services/fcm_service.dart';
import 'package:snapstudy/features/notifications/data/services/local_notification_service.dart';
import 'package:snapstudy/features/notifications/data/services/notification_history_service.dart';
import 'package:snapstudy/features/notifications/data/services/notification_scheduler_service.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_preferences.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_record.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_source.dart';
import 'package:snapstudy/features/notifications/domain/entities/notification_sync_snapshot.dart';
import 'package:snapstudy/features/notifications/domain/repositories/notification_repository.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/repositories/session_repository.dart';
import 'package:snapstudy/features/spaced_repetition/domain/repositories/spaced_repetition_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  NotificationRepositoryImpl({
    required SessionRepository sessions,
    required SpacedRepetitionRepository spacedRepetition,
    LocalNotificationService? local,
    FcmService? fcm,
    NotificationPrefsDataSource? prefs,
    NotificationHistoryService? history,
  })  : _sessions = sessions,
        _sr = spacedRepetition,
        _local = local ?? LocalNotificationService(),
        _prefs = prefs ?? NotificationPrefsDataSource(),
        _history = history ?? NotificationHistoryService(),
        _fcm = fcm {
    _scheduler = NotificationSchedulerService(local: _local);
  }

  final SessionRepository _sessions;
  final SpacedRepetitionRepository _sr;
  final LocalNotificationService _local;
  final NotificationPrefsDataSource _prefs;
  final NotificationHistoryService _history;
  late final NotificationSchedulerService _scheduler;
  final FcmService? _fcm;

  var _bootstrapped = false;

  @override
  Future<Result<void>> initialize() async {
    try {
      if (!_bootstrapped) {
        await _local.initialize();
        await _fcm?.initialize();
        _bootstrapped = true;
      }
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure('Không khởi tạo thông báo: $e'));
    }
  }

  @override
  Future<Result<bool>> requestPermission() async {
    try {
      final granted = await _local.requestPermissions();
      final current = _prefs.read();
      await _prefs.write(current.copyWith(permissionAsked: true));
      return Success(granted);
    } catch (e) {
      return Error(UnknownFailure('Không xin quyền thông báo: $e'));
    }
  }

  @override
  Future<Result<NotificationPreferences>> getPreferences() async {
    return Success(_prefs.read());
  }

  @override
  Future<Result<NotificationPreferences>> savePreferences(
    NotificationPreferences prefs,
  ) async {
    try {
      await _prefs.write(prefs);
      await syncScheduledReminders();
      return Success(prefs);
    } catch (e) {
      return Error(UnknownFailure('Không lưu cài đặt thông báo: $e'));
    }
  }

  @override
  Future<Result<void>> syncScheduledReminders() async {
    try {
      await initialize();
      final prefs = _prefs.read();
      final snapshot = await _buildSnapshot();
      await _scheduler.sync(prefs: prefs, snapshot: snapshot);
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure('Không lên lịch thông báo: $e'));
    }
  }

  @override
  Future<Result<void>> showInstantReviewReminder({
    required int dueCount,
    required int overdueCount,
  }) async {
    if (dueCount <= 0) return const Success(null);
    try {
      await initialize();
      final overdueLine =
          overdueCount > 0 ? ' ($overdueCount quá hạn)' : '';
      const title = 'Thẻ cần ôn ngay';
      final body = '$dueCount thẻ đang chờ$overdueLine';
      await _history.record(
        title: title,
        body: body,
        payloadType: NotificationPayload.review,
        source: NotificationSource.local,
      );
      await _local.show(
        id: 9001,
        title: title,
        body: body,
        channelId: NotificationChannels.review,
        payload: NotificationPayload.review,
      );
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure('Không hiện thông báo: $e'));
    }
  }

  Future<NotificationSyncSnapshot> _buildSnapshot() async {
    final statsResult = await _sr.getStats();
    final stats = statsResult.fold(
      onSuccess: (s) => s,
      onFailure: (_) => null,
    );

    final activeResult = await _sessions.getActiveSession();
    final active = activeResult.fold(
      onSuccess: (s) => s,
      onFailure: (_) => null,
    );

    final allResult = await _sessions.getAllSessions();
    var pending = 0;
    allResult.fold(
      onSuccess: (list) {
        pending = list
            .where(
              (s) =>
                  s.status == SessionStatus.processing ||
                  s.status == SessionStatus.ready,
            )
            .length;
      },
      onFailure: (_) {},
    );

    return NotificationSyncSnapshot(
      dueCards: stats?.dueNow ?? 0,
      overdueCards: stats?.overdue ?? 0,
      streakDays: stats?.studyStreakDays ?? 0,
      reviewedToday: stats?.reviewedToday ?? 0,
      hasActiveSession: active != null,
      pendingSessionCount: pending,
    );
  }

  @override
  Future<Result<List<NotificationRecord>>> getHistory() async {
    return Success(_history.getAll());
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    return Success(_history.unreadCount());
  }

  @override
  Future<Result<void>> markHistoryRead(String id) async {
    await _history.markRead(id);
    return const Success(null);
  }

  @override
  Future<Result<void>> markAllHistoryRead() async {
    await _history.markAllRead();
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteHistoryItem(String id) async {
    await _history.delete(id);
    return const Success(null);
  }

  @override
  Future<Result<void>> clearHistory() async {
    await _history.clear();
    return const Success(null);
  }

  @override
  Future<Result<void>> registerPushWithServer() async {
    try {
      await _fcm?.registerTokenWithServer();
      return const Success(null);
    } catch (e) {
      return Error(UnknownFailure('Đăng ký push: $e'));
    }
  }

  @override
  Future<Result<void>> handleNotificationOpened(String? payload) async {
    await _history.markOpenedByPayload(payload);
    return const Success(null);
  }
}
