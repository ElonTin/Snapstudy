import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/env/env_config.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/features/feedback/presentation/providers/feedback_providers.dart';

class FeedbackPage extends ConsumerStatefulWidget {
  const FeedbackPage({super.key});

  @override
  ConsumerState<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends ConsumerState<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _messageCtrl = TextEditingController();
  String _selectedType = 'Góp ý';
  final List<File> _images = [];
  final _picker = ImagePicker();

  static const _feedbackTypes = [
    'Góp ý',
    'Báo lỗi (Bug)',
    'Khen ngợi',
    'Câu hỏi',
    'Khác',
  ];

  static const _maxImages = 3;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  String get _platform {
    if (Platform.isIOS) return 'iOS';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isMacOS) return 'macOS';
    return 'Unknown';
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_images.length >= _maxImages) {
      context.showSnack('Chỉ đính kèm tối đa $_maxImages ảnh');
      return;
    }
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (picked != null && mounted) {
        setState(() => _images.add(File(picked.path)));
      }
    } catch (_) {
      if (mounted) context.showSnack('Không thể chọn ảnh', isError: true);
    }
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(ctx).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Chụp ảnh'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Chọn từ thư viện'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (!EnvConfig.isEmailJsConfigured) {
      context.showSnack(
        'EmailJS chưa được cấu hình — thêm key vào file .env',
        isError: true,
      );
      return;
    }

    await ref.read(feedbackProvider.notifier).send(
          feedbackType: _selectedType,
          message: _messageCtrl.text.trim(),
          images: _images,
          platform: _platform,
        );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Lắng nghe trạng thái để hiển thị snackbar / pop
    ref.listen<FeedbackState>(feedbackProvider, (prev, next) {
      if (next.isSuccess) {
        _showSuccessDialog();
      } else if (next.isError && next.errorMessage != null) {
        context.showSnack(next.errorMessage!, isError: true);
        ref.read(feedbackProvider.notifier).reset();
      }
    });

    final state = ref.watch(feedbackProvider);
    final isSending = state.isSending;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gửi phản hồi'),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          children: [
            // ── Header info ──────────────────────────────────────────────
            _InfoBanner(colors: colors),
            const SizedBox(height: 24),

            // ── Loại phản hồi ────────────────────────────────────────────
            Text(
              'Loại phản hồi',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            _TypeSelector(
              selected: _selectedType,
              types: _feedbackTypes,
              enabled: !isSending,
              onChanged: (v) => setState(() => _selectedType = v),
            ),
            const SizedBox(height: 20),

            // ── Nội dung ─────────────────────────────────────────────────
            Text(
              'Nội dung *',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              key: const Key('feedback_message_field'),
              controller: _messageCtrl,
              enabled: !isSending,
              maxLines: 6,
              maxLength: 2000,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                hintText:
                    'Mô tả chi tiết phản hồi của bạn...\n\nVí dụ: Khi tôi nhấn nút X thì ứng dụng bị...',
                alignLabelWithHint: true,
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Vui lòng nhập nội dung phản hồi';
                }
                if (v.trim().length < 10) {
                  return 'Nội dung quá ngắn (tối thiểu 10 ký tự)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // ── Đính kèm ảnh ─────────────────────────────────────────────
            Row(
              children: [
                Text(
                  'Ảnh đính kèm',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(width: 8),
                Text(
                  '(${_images.length}/$_maxImages)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ImageGrid(
              images: _images,
              maxImages: _maxImages,
              enabled: !isSending,
              onAdd: _showImageSourceSheet,
              onRemove: _removeImage,
            ),
            const SizedBox(height: 32),

            // ── Submit button ─────────────────────────────────────────────
            AppButton(
              label: isSending ? 'Đang gửi...' : 'Gửi phản hồi',
              variant: AppButtonVariant.primary,
              icon: isSending ? null : Icons.send_outlined,
              expand: true,
              size: AppButtonSize.large,
              isLoading: isSending,
              onPressed: isSending ? null : _submit,
            ),
            const SizedBox(height: 12),
            Text(
              'Phản hồi sẽ được gửi đến email của nhà phát triển',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_outline, size: 56, color: Color(0xFF4CAF50)),
        title: const Text('Đã gửi thành công!'),
        content: const Text(
          'Cảm ơn bạn đã gửi phản hồi. Nhà phát triển sẽ đọc và phản hồi sớm nhất có thể.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // quay lại Settings
            },
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.colors});
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: colors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Phản hồi của bạn giúp SnapStudy ngày càng tốt hơn! '
              'Hãy mô tả chi tiết để nhà phát triển hiểu và hỗ trợ bạn nhanh nhất.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({
    required this.selected,
    required this.types,
    required this.enabled,
    required this.onChanged,
  });

  final String selected;
  final List<String> types;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final isSelected = type == selected;
        return ChoiceChip(
          label: Text(type),
          selected: isSelected,
          onSelected: enabled ? (_) => onChanged(type) : null,
          selectedColor: Theme.of(context).colorScheme.primaryContainer,
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : null,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.maxImages,
    required this.enabled,
    required this.onAdd,
    required this.onRemove,
  });

  final List<File> images;
  final int maxImages;
  final bool enabled;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final canAdd = images.length < maxImages && enabled;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Existing images
        for (int i = 0; i < images.length; i++)
          _ImageThumbnail(
            file: images[i],
            onRemove: enabled ? () => onRemove(i) : null,
          ),

        // Add button
        if (canAdd)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppConstants.smallRadius),
                border: Border.all(
                  color: colors.outline.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      color: colors.primary, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    'Thêm ảnh',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.primary,
                        ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  const _ImageThumbnail({required this.file, this.onRemove});
  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppConstants.smallRadius),
          child: Image.file(
            file,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
