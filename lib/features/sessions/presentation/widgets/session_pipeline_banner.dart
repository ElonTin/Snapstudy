import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snapstudy/core/theme/app_colors.dart';
import 'package:snapstudy/core/widgets/app_scaffold.dart';
import 'package:snapstudy/core/widgets/document_scan_overlay.dart';
import 'package:snapstudy/features/sessions/domain/entities/session_pipeline_step.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_pipeline_provider.dart';
import 'package:snapstudy/features/sessions/presentation/providers/session_providers.dart';

class SessionPipelineBanner extends ConsumerWidget {
  const SessionPipelineBanner({
    super.key,
    required this.sessionId,
    this.showScanPreview = true,
  });

  final String sessionId;
  final bool showScanPreview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(sessionPipelineProvider);
    if (!pipeline.isRunning || pipeline.sessionId != sessionId) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    final stepLabel = pipeline.currentStep?.label ?? 'Hoàn tất';
    final sessionAsync = ref.watch(sessionDetailProvider(sessionId));
    final previewPath = sessionAsync.whenOrNull(
      data: (s) =>
          s != null && s.queue.isNotEmpty ? s.queue.first.localPath : null,
    );

    return AppCard(
      color: colors.primaryContainer.withValues(alpha: 0.4),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showScanPreview && previewPath != null) ...[
            DocumentScanOverlay(
              imagePath: previewPath,
              label: stepLabel,
              compact: true,
              height: 140,
              progress: pipeline.progress,
            ),
            const SizedBox(height: 14),
          ] else ...[
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.aiGradientStart, AppColors.aiGradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.document_scanner_outlined,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Đang phân tích AI (OCR + tóm tắt)',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Text(
                  '${(pipeline.progress * 100).round()}%',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.secondary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pipeline.progress,
                minHeight: 5,
                backgroundColor: colors.surfaceContainerHighest,
                color: colors.secondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _StepChip(
                label: 'OCR',
                done: pipeline.completedSteps.contains(SessionPipelineStep.ocr),
                active: pipeline.currentStep == SessionPipelineStep.ocr,
              ),
              const SizedBox(width: 8),
              _StepChip(
                label: 'Tóm tắt',
                done: pipeline.completedSteps.contains(SessionPipelineStep.summary),
                active: pipeline.currentStep == SessionPipelineStep.summary,
              ),
            ],
          ),
          if (pipeline.error != null) ...[
            const SizedBox(height: 8),
            Text(
              pipeline.error!,
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.done,
    required this.active,
  });

  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bg = done
        ? colors.tertiaryContainer
        : active
            ? colors.secondaryContainer
            : colors.surfaceContainerHighest;
    final fg = done
        ? colors.onTertiaryContainer
        : active
            ? colors.onSecondaryContainer
            : colors.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (done)
            Icon(Icons.check_rounded, size: 14, color: fg)
          else if (active)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: fg),
            ),
          if (done || active) const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
