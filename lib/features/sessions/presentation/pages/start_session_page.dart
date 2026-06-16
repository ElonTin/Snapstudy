import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/routing/route_paths.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/utils/icon_helper.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_empty_state.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';
import 'package:snapstudy/features/subjects/domain/entities/subject.dart';
import 'package:snapstudy/features/subjects/presentation/providers/subject_providers.dart';

/// Start a new study capture session.
class StartSessionPage extends HookConsumerWidget {
  const StartSessionPage({super.key, this.preselectedSubjectId});

  final String? preselectedSubjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final notesController = useTextEditingController();
    final selectedSubject = useState<Subject?>(null);
    final isStarting = useState(false);

    final subjectsAsync = ref.watch(subjectsControllerProvider);
    final hasActive = ref.watch(hasActiveSessionProvider);

    useEffect(() {
      if (hasActive) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) context.replace(RoutePaths.sessionActive);
        });
      }
      return null;
    }, [hasActive]);

    useEffect(() {
      subjectsAsync.whenData((subjects) {
        if (selectedSubject.value != null) return;
        if (preselectedSubjectId != null) {
          for (final s in subjects) {
            if (s.id == preselectedSubjectId) {
              selectedSubject.value = s;
              titleController.text = 'Buổi học ${s.name}';
              break;
            }
          }
        } else if (subjects.isNotEmpty) {
          selectedSubject.value = subjects.first;
          titleController.text = 'Buổi học ${subjects.first.name}';
        }
      });
      return null;
    }, [subjectsAsync]);

    Future<void> start() async {
      final subject = selectedSubject.value;
      if (subject == null) {
        context.showSnack('Chọn môn học trước', isError: true);
        return;
      }
      isStarting.value = true;
      final session = await ref.read(activeSessionProvider.notifier).startSession(
            subject: subject,
            title: titleController.text,
            notes: notesController.text,
          );
      isStarting.value = false;
      if (session != null && context.mounted) {
        context.go(RoutePaths.sessionActive);
      } else if (context.mounted) {
        final err = ref.read(activeSessionProvider).error;
        context.showSnack(
          err?.toString() ?? 'Không thể bắt đầu buổi học',
          isError: true,
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bắt đầu buổi học'),
        scrolledUnderElevation: 1,
      ),
      body: subjectsAsync.when(
        loading: () => const AppLoading(
          fullScreen: true,
          message: 'Đang tải môn học...',
        ),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (subjects) {
          if (subjects.isEmpty) {
            return AppEmptyState(
              title: 'Chưa có môn học',
              subtitle: 'Tạo môn học trước khi bắt đầu buổi chụp',
              icon: Icons.school_outlined,
              action: AppButton(
                label: 'Tạo môn học',
                icon: Icons.add,
                onPressed: () => context.push(RoutePaths.subjectCreate),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(
                      title: 'Chọn môn học',
                      subtitle: 'Môn học sẽ được gắn vào buổi chụp',
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: subjects.map((s) {
                        final selected = selectedSubject.value?.id == s.id;
                        final color = Color(s.colorValue);
                        return FilterChip(
                          selected: selected,
                          label: Text(s.name),
                          avatar: Icon(
                            iconFromCodePoint(s.iconCodePoint),
                            size: 18,
                            color: color,
                          ),
                          selectedColor: color.withValues(alpha: 0.15),
                          checkmarkColor: color,
                          side: BorderSide(
                            color: selected
                                ? color
                                : Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.5),
                          ),
                          onSelected: (_) {
                            selectedSubject.value = s;
                            if (titleController.text.isEmpty ||
                                titleController.text.startsWith('Buổi học ')) {
                              titleController.text = 'Buổi học ${s.name}';
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.sectionSpacing),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppSectionHeader(title: 'Thông tin buổi học'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Tiêu đề buổi học *',
                        hintText: 'VD: Chương 4 — Đạo hàm',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        labelText: 'Ghi chú (tuỳ chọn)',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Tự động gắn thẻ: môn học, ngày, snapstudy',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppConstants.sectionSpacing),
              AppButton(
                label: 'Bắt đầu chụp',
                icon: Icons.play_arrow_rounded,
                expand: true,
                isLoading: isStarting.value,
                onPressed: isStarting.value ? null : start,
              ),
            ],
          );
        },
      ),
    );
  }
}
