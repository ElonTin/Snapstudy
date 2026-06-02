import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/features/ocr/domain/entities/ocr_status.dart';
import 'package:snapstudy/features/ocr/domain/entities/session_ocr_result.dart';
import 'package:snapstudy/features/ocr/presentation/providers/ocr_providers.dart';

class OcrResultSection extends ConsumerWidget {
  const OcrResultSection({
    super.key,
    required this.ocr,
    this.onReprocess,
    this.isReprocessing = false,
  });

  final SessionOcrResult ocr;
  final VoidCallback? onReprocess;
  final bool isReprocessing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final isMock = ref.watch(ocrUsesMockProvider);
    final looksLikeOldMock = ocr.fullText.contains('Chương 3: Đạo hàm') ||
        ocr.fullText.contains('DỮ LIỆU MẪU');

    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.document_scanner_outlined,
                    color: AppColors.aiGradientStart),
                const SizedBox(width: 8),
                Text(
                  'Văn bản nhận dạng (OCR)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                _ConfidenceChip(confidence: ocr.averageConfidence),
              ],
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
                child: Text(
                  ocr.fullText.isEmpty
                      ? 'Không trích xuất được văn bản.'
                      : ocr.fullText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.45,
                      ),
                ),
              ),
            ),
            if (onReprocess != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: isReprocessing ? null : onReprocess,
                icon: isReprocessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: Text(isReprocessing ? 'Đang OCR...' : 'Chạy lại OCR'),
              ),
            ],
          ],
        ),
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
        ? Colors.green
        : confidence >= 0.5
            ? Colors.orange
            : Colors.red;

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
