import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_empty_state.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/home/presentation/utils/dashboard_formatters.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_status.dart';
import 'package:snapstudy/features/sessions/domain/entities/study_session.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/sessions/presentation/utils/append_images_flow.dart';
import 'package:snapstudy/features/sessions/presentation/utils/session_display_labels.dart';

final allSessionsProvider = FutureProvider<List<StudySession>>((ref) async {
  final result = await ref.read(sessionRepositoryProvider).getAllSessions();
  return result.fold(
    onSuccess: (list) => list
        .where((s) => s.status != SessionStatus.active)
        .toList(),
    onFailure: (_) => [],
  );
});

/// Danh sách toàn bộ buổi học đã OCR — tiếp tục học / thêm ảnh.
class SessionsHistoryPage extends ConsumerWidget {
  const SessionsHistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(allSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tất cả buổi học'),
        scrolledUnderElevation: 1,
      ),
      body: sessionsAsync.when(
        loading: () => const AppLoading(fullScreen: true),
        error: (e, _) => Center(child: Text('$e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const AppEmptyState(
              title: 'Chưa có buổi học',
              subtitle: 'Chụp hoặc import ảnh từ trang chủ để bắt đầu.',
              icon: Icons.history_edu_outlined,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allSessionsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: sessions.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppConstants.compactPadding),
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionHistoryTile(session: session);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SessionHistoryTile extends StatelessWidget {
  const _SessionHistoryTile({required this.session});

  final StudySession session;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final accent = Color(session.subjectColorValue);
    final title = SessionDisplayLabels.title(session);
    final subtitle = SessionDisplayLabels.subtitle(session);

    return AppCard(
      onTap: () => context.push(RoutePaths.sessionDetailPath(session.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                ),
                child: Icon(Icons.menu_book_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${session.photoCount} ảnh · '
                      '${DashboardFormatters.relativeTime(session.startedAt)}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              AppButton(
                label: 'Chụp thêm',
                icon: Icons.camera_alt_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () => runAppendCamera(context, session.id),
              ),
              AppButton(
                label: 'Import',
                icon: Icons.photo_library_outlined,
                variant: AppButtonVariant.outline,
                onPressed: () => runAppendGallery(context, session.id),
              ),
              if (session.flashcardsReady)
                AppButton(
                  label: 'Flashcard',
                  icon: Icons.style_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      context.push(RoutePaths.flashcardStudyPath(session.id)),
                ),
              if (session.quizReady)
                AppButton(
                  label: 'Quiz',
                  icon: Icons.quiz_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      context.push(RoutePaths.quizPlayPath(session.id)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
