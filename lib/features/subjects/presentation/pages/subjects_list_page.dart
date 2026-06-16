import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/utils/icon_helper.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_empty_state.dart';
import 'package:snapstudy/core/widgets/app_error_view.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject_folder.dart';
import 'package:snapstudy/features/subjects/presentation/providers/subject_providers.dart';

/// All subjects grouped by folder.
class SubjectsListPage extends ConsumerWidget {
  const SubjectsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjectsAsync = ref.watch(subjectsControllerProvider);
    final foldersAsync = ref.watch(subjectFoldersControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Môn học'),
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Thêm thư mục',
            onPressed: () => _showFolderDialog(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RoutePaths.subjectCreate),
        icon: const Icon(Icons.add),
        label: const Text('Môn mới'),
      ),
      body: subjectsAsync.when(
        loading: () => const AppLoading(
          fullScreen: true,
          message: 'Đang tải môn học...',
        ),
        error: (e, _) => AppErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.read(subjectsControllerProvider.notifier).refresh(),
        ),
        data: (subjects) {
          return foldersAsync.when(
            loading: () => const AppLoading(fullScreen: true),
            error: (e, _) => AppErrorView(message: e.toString()),
            data: (folders) {
              if (subjects.isEmpty) {
                return AppEmptyState(
                  title: 'Chưa có môn học',
                  subtitle: 'Tạo môn học để tổ chức buổi chụp và tài liệu AI',
                  icon: Icons.school_outlined,
                  action: AppButton(
                    label: 'Tạo môn học',
                    icon: Icons.add,
                    onPressed: () => context.push(RoutePaths.subjectCreate),
                  ),
                );
              }

              final grouped = _groupByFolder(subjects, folders);
              final entries = _flattenGrouped(grouped);

              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(subjectsControllerProvider.notifier).refresh();
                  await ref.read(subjectFoldersControllerProvider.notifier).refresh();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return switch (entry) {
                      _SubjectFolderRow(:final folder, :final count) =>
                        _FolderHeader(
                          title: folder.name,
                          count: count,
                          onDelete: folder.id != null
                              ? () => _confirmDeleteFolder(
                                    context,
                                    ref,
                                    folder.id!,
                                    folder.name,
                                  )
                              : null,
                        ),
                      _SubjectTileRow(:final subject) => _SubjectListTile(
                          subject: subject,
                          onTap: () => context.push(
                            RoutePaths.subjectEditPath(subject.id),
                          ),
                          onEdit: () => context.push(
                            RoutePaths.subjectEditPath(subject.id),
                          ),
                          onDelete: () => _confirmDeleteSubject(
                            context,
                            ref,
                            subject,
                          ),
                        ),
                      _SubjectSectionGap() => const SizedBox(height: 16),
                    };
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  List<_SubjectListRow> _flattenGrouped(
    Map<_FolderGroup, List<Subject>> grouped,
  ) {
    final rows = <_SubjectListRow>[];
    for (final entry in grouped.entries) {
      rows.add(_SubjectFolderRow(folder: entry.key, count: entry.value.length));
      for (final subject in entry.value) {
        rows.add(_SubjectTileRow(subject: subject));
      }
      rows.add(const _SubjectSectionGap());
    }
    return rows;
  }

  Map<_FolderGroup, List<Subject>> _groupByFolder(
    List<Subject> subjects,
    List<SubjectFolder> folders,
  ) {
    final map = <_FolderGroup, List<Subject>>{};
    final folderById = {for (final f in folders) f.id: f};

    for (final folder in folders) {
      map[_FolderGroup(folder.id, folder.name)] = [];
    }
    map[_FolderGroup(null, 'Không phân loại')] = [];

    for (final subject in subjects) {
      final folder = subject.folderId != null
          ? folderById[subject.folderId]
          : null;
      final key = folder != null
          ? _FolderGroup(folder.id, folder.name)
          : _FolderGroup(null, 'Không phân loại');
      map.putIfAbsent(key, () => []).add(subject);
    }

    map.removeWhere((_, list) => list.isEmpty);
    return map;
  }

  Future<void> _showFolderDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Thư mục mới'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Tên thư mục'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
    if (ok == true && controller.text.trim().isNotEmpty && context.mounted) {
      final success = await ref
          .read(subjectFoldersControllerProvider.notifier)
          .create(controller.text.trim());
      if (context.mounted) {
        context.showSnack(
          success ? 'Đã tạo thư mục' : 'Tạo thư mục thất bại',
          isError: !success,
        );
      }
    }
    controller.dispose();
  }

  Future<void> _confirmDeleteSubject(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá môn học?'),
        content: Text(
          'Môn "${subject.name}" sẽ bị xoá. Buổi học liên quan vẫn được giữ (Phase 5).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success =
          await ref.read(subjectsControllerProvider.notifier).delete(subject.id);
      if (context.mounted) {
        context.showSnack(
          success ? 'Đã xoá môn học' : 'Xoá thất bại',
          isError: !success,
        );
      }
    }
  }

  Future<void> _confirmDeleteFolder(
    BuildContext context,
    WidgetRef ref,
    String folderId,
    String folderName,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá thư mục?'),
        content: Text(
          'Thư mục "$folderName" sẽ bị xoá. Các môn học bên trong chuyển sang "Không phân loại".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      final success = await ref
          .read(subjectFoldersControllerProvider.notifier)
          .delete(folderId);
      if (context.mounted) {
        context.showSnack(
          success ? 'Đã xoá thư mục' : 'Xoá thất bại',
          isError: !success,
        );
      }
    }
  }
}

sealed class _SubjectListRow {
  const _SubjectListRow();
}

final class _SubjectFolderRow extends _SubjectListRow {
  const _SubjectFolderRow({required this.folder, required this.count});

  final _FolderGroup folder;
  final int count;
}

final class _SubjectTileRow extends _SubjectListRow {
  const _SubjectTileRow({required this.subject});

  final Subject subject;
}

final class _SubjectSectionGap extends _SubjectListRow {
  const _SubjectSectionGap();
}

class _FolderGroup {
  const _FolderGroup(this.id, this.name);

  final String? id;
  final String name;

  @override
  bool operator ==(Object other) =>
      other is _FolderGroup && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

class _FolderHeader extends StatelessWidget {
  const _FolderHeader({
    required this.title,
    required this.count,
    this.onDelete,
  });

  final String title;
  final int count;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: AppSectionHeader(
        title: title,
        subtitle: '$count môn',
        trailing: onDelete != null
            ? IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: colors.onSurfaceVariant),
                onPressed: onDelete,
                tooltip: 'Xoá thư mục',
              )
            : null,
      ),
    );
  }
}

class _SubjectListTile extends StatelessWidget {
  const _SubjectListTile({
    required this.subject,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Subject subject;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Color(subject.colorValue);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppConstants.compactPadding),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppConstants.smallRadius),
              ),
              child: Icon(
                iconFromCodePoint(subject.iconCodePoint),
                color: color,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject.name,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (subject.description != null &&
                      subject.description!.isNotEmpty)
                    Text(
                      subject.description!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  Text(
                    '${subject.sessionCount} buổi · ${subject.pendingReviews} ôn tập',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onEdit,
            ),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: colors.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
