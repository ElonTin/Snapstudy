import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/latex_text_widget.dart';
import 'package:snapstudy/core/utils/extensions.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/ocr/presentation/providers/ocr_providers.dart';
import 'package:snapstudy/features/ocr/presentation/widgets/ocr_rich_text_widget.dart';
import 'package:snapstudy/core/widgets/app_button.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';

class OcrResultSection extends ConsumerWidget {
  const OcrResultSection({
    super.key,
    required this.ocr,
    this.onReprocess,
    this.isReprocessing = false,
    this.onApplySuggestedSubject,
    this.canApplySuggestedSubject = false,
  });

  final SessionOcrResult ocr;
  final VoidCallback? onReprocess;
  final bool isReprocessing;
  final VoidCallback? onApplySuggestedSubject;
  final bool canApplySuggestedSubject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isMock = ref.watch(ocrUsesMockProvider);
    final looksLikeOldMock = ocr.fullText.contains('Chương 3: Đạo hàm') ||
        ocr.fullText.contains('DỮ LIỆU MẪU');

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeader(
            title: 'Văn bản nhận dạng (OCR)',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  tooltip: 'Sao chép văn bản OCR',
                  onPressed: ocr.fullText.trim().isEmpty
                      ? null
                      : () {
                          Clipboard.setData(
                            ClipboardData(text: ocr.fullText),
                          );
                          context.showSnack('Đã sao chép văn bản OCR');
                        },
                ),
                _ConfidenceChip(confidence: ocr.averageConfidence),
              ],
            ),
          ),
            const SizedBox(height: 8),
            Text(
              _statusLabel(ocr.status),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Engine: ${ref.watch(ocrEngineLabelProvider)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.aiGradientStart,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (isMock || looksLikeOldMock) ...[
              const SizedBox(height: 12),
              MaterialBanner(
                backgroundColor: colors.errorContainer,
                content: Text(
                  looksLikeOldMock && !isMock
                      ? 'Kết quả cũ từ OCR giả lập. Bấm «Chạy lại OCR» trên điện thoại để nhận dạng ảnh thật.'
                      : 'Đang dùng OCR mẫu (máy tính). Chạy trên Android với OCR_DEV_MODE=false.',
                  style: TextStyle(color: colors.onErrorContainer),
                ),
                actions: const [SizedBox.shrink()],
              ),
            ],
            if (ocr.hasEquations) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.functions_outlined, size: 18),
                  SizedBox(width: 6),
                  Text('Phát hiện công thức / phương trình'),
                ],
              ),
            ],
            if (ocr.suggestedSubjectName != null) ...[
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.lightbulb_outline),
                title: const Text('Gợi ý môn học'),
                subtitle: Text(
                  '${ocr.suggestedSubjectName} '
                  '(${(ocr.suggestedSubjectConfidence * 100).round()}%)',
                ),
                dense: true,
              ),
              if (canApplySuggestedSubject && onApplySuggestedSubject != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton(
                    label: 'Áp dụng môn «${ocr.suggestedSubjectName}»',
                    icon: Icons.check,
                    variant: AppButtonVariant.secondary,
                    onPressed: onApplySuggestedSubject,
                  ),
                ),
            ],
            if (ocr.latexEquations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Công thức (LaTeX)', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...ocr.latexEquations.take(8).map(
                    (eq) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: LatexTextWidget(
                          latex: eq,
                          onCopy: () => context.showSnack('Đã sao chép LaTeX'),
                        ),
                      ),
                    ),
                  ),
            ],
            if (ocr.keywords.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Từ khoá', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ocr.keywords
                    .map((k) => Chip(label: Text(k), visualDensity: VisualDensity.compact))
                    .toList(),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Nội dung (${ocr.successCount}/${ocr.captures.length} ảnh)',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
                border: Border.all(color: colors.outlineVariant),
              ),
              constraints: const BoxConstraints(maxHeight: 220),
              child: SingleChildScrollView(
                child: ocr.fullText.isEmpty
                    ? Text(
                        'Không trích xuất được văn bản.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : OcrRichTextWidget(
                        text: ocr.fullText,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
              ),
            ),
            if (onReprocess != null) ...[
              const SizedBox(height: 12),
              AppButton(
                label: isReprocessing ? 'Đang OCR...' : 'Chạy lại OCR',
                icon: Icons.refresh,
                variant: AppButtonVariant.outline,
                isLoading: isReprocessing,
                onPressed: isReprocessing ? null : onReprocess,
              ),
            ],
          ],
        ),
    );
  }

  String _statusLabel(OcrStatus status) => switch (status) {
        OcrStatus.completed =>
          'Hoàn tất — ${ocr.captures.length} ảnh đã xử lý',
        OcrStatus.partial =>
          'Một phần — ${ocr.successCount}/${ocr.captures.length} ảnh thành công',
        OcrStatus.failed => 'Thất bại — thử chạy lại',
        OcrStatus.pending => 'Đang chờ',
      };
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final pct = (confidence * 100).round();
    final color = confidence >= 0.8
        ? AppColors.success
        : confidence >= 0.5
            ? AppColors.warning
            : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'Tin cậy $pct%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
