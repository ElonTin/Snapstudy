import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/errors/failures.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_loading.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/features/subjects/domain/constants/subject_presets.dart';
import 'package:snapstudy/features/subjects/presentation/providers/subject_providers.dart';
import 'package:snapstudy/features/subjects/presentation/widgets/subject_appearance_picker.dart';

/// Create or edit a subject.
class SubjectFormPage extends HookConsumerWidget {
  const SubjectFormPage({super.key, this.subjectId});

  final String? subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEdit = subjectId != null;
    final nameController = useTextEditingController();
    final descController = useTextEditingController();
    final selectedColor = useState(SubjectPresets.colors.first);
    final selectedIcon = useState(SubjectPresets.icons.first);
    final selectedFolderId = useState<String?>(null);
    final isSaving = useState(false);
    final isLoading = useState(isEdit);

    final foldersAsync = ref.watch(subjectFoldersControllerProvider);
    final subjectsAsync = ref.watch(subjectsControllerProvider);

    useEffect(() {
      if (!isEdit || subjectId == null) {
        isLoading.value = false;
        return null;
      }
      subjectsAsync.whenData((subjects) {
        for (final s in subjects) {
          if (s.id == subjectId) {
            nameController.text = s.name;
            descController.text = s.description ?? '';
            selectedColor.value = Color(s.colorValue);
            selectedIcon.value = IconData(
              s.iconCodePoint,
              fontFamily: 'MaterialIcons',
            );
            selectedFolderId.value = s.folderId;
            isLoading.value = false;
            break;
          }
        }
      });
      return null;
    }, [subjectsAsync, subjectId]);

    Future<void> save() async {
      if (nameController.text.trim().isEmpty) {
        context.showSnack('Vui lòng nhập tên môn học', isError: true);
        return;
      }
      isSaving.value = true;

      final notifier = ref.read(subjectsControllerProvider.notifier);
      bool ok;

      if (isEdit) {
        final existing = subjectsAsync.valueOrNull
            ?.where((s) => s.id == subjectId)
            .first;
        if (existing == null) {
          context.showSnack('Không tìm thấy môn học', isError: true);
          isSaving.value = false;
          return;
        }
        ok = await notifier.updateSubject(
          existing.copyWith(
            name: nameController.text.trim(),
            description: descController.text.trim().isEmpty
                ? null
                : descController.text.trim(),
            colorValue: selectedColor.value.toARGB32(),
            iconCodePoint: selectedIcon.value.codePoint,
            folderId: selectedFolderId.value,
            clearFolderId: selectedFolderId.value == null,
          ),
        );
      } else {
        ok = await notifier.create(
          name: nameController.text.trim(),
          description: descController.text.trim().isEmpty
              ? null
              : descController.text.trim(),
          colorValue: selectedColor.value.toARGB32(),
          iconCodePoint: selectedIcon.value.codePoint,
          folderId: selectedFolderId.value,
        );
      }

      isSaving.value = false;
      if (ok && context.mounted) {
        context.pop();
        context.showSnack(isEdit ? 'Đã cập nhật môn học' : 'Đã tạo môn học');
      } else if (context.mounted) {
        final err = ref.read(subjectsControllerProvider).error;
        final msg = err is Failure ? err.message : 'Lưu thất bại';
        context.showSnack(msg, isError: true);
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Sửa môn học' : 'Môn học mới'),
        scrolledUnderElevation: 1,
      ),
      body: isLoading.value
          ? const AppLoading(fullScreen: true, message: 'Đang tải...')
          : ListView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              children: [
                AppCard(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: selectedColor.value.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AppConstants.largeRadius),
                        ),
                        child: Icon(
                          selectedIcon.value,
                          size: 40,
                          color: selectedColor.value,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên môn học *',
                          hintText: 'VD: Toán 12',
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: descController,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả (tuỳ chọn)',
                          hintText: 'Ghi chú ngắn về môn học',
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20),
                      foldersAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (folders) => DropdownButtonFormField<String?>(
                          initialValue: selectedFolderId.value,
                          decoration:
                              const InputDecoration(labelText: 'Thư mục'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('Không có thư mục'),
                            ),
                            ...folders.map(
                              (f) => DropdownMenuItem(
                                value: f.id,
                                child: Text(f.name),
                              ),
                            ),
                          ],
                          onChanged: (v) => selectedFolderId.value = v,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.sectionSpacing),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AppSectionHeader(
                        title: 'Giao diện môn học',
                        subtitle: 'Chọn màu và biểu tượng',
                      ),
                      const SizedBox(height: 16),
                      SubjectAppearancePicker(
                        selectedColor: selectedColor.value,
                        selectedIcon: selectedIcon.value,
                        onColorChanged: (c) => selectedColor.value = c,
                        onIconChanged: (i) => selectedIcon.value = i,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppConstants.sectionSpacing),
                AppButton(
                  label: isEdit ? 'Lưu thay đổi' : 'Tạo môn học',
                  expand: true,
                  isLoading: isSaving.value,
                  onPressed: isSaving.value ? null : save,
                ),
              ],
            ),
    );
  }
}
