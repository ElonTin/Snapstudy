import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/widgets/app_dialog.dart';
import 'package:snapstudy/core/widgets/document_scan_overlay.dart';
import 'package:snapstudy/features/sessions/presentation/providers/image_ingest_provider.dart';
import 'package:snapstudy/features/sessions/presentation/utils/append_images_flow.dart';

/// Màn xử lý AI — có nút quay lại (ingest mới hoặc thêm ảnh buổi cũ).
class IngestProgressPage extends ConsumerStatefulWidget {
  const IngestProgressPage({
    super.key,
    this.sessionId,
    required this.imagePaths,
  });

  /// null = tạo buổi mới; có giá trị = thêm ảnh buổi cũ.
  final String? sessionId;
  final List<String> imagePaths;

  @override
  ConsumerState<IngestProgressPage> createState() => _IngestProgressPageState();
}

class _IngestProgressPageState extends ConsumerState<IngestProgressPage> {
  var _started = false;
  var _finished = false;
  var _popped = false;

  void _safePop<T extends Object?>([T? result]) {
    if (_popped || !mounted) return;
    _popped = true;
    context.pop(result);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;

    if (widget.sessionId != null) {
      final ok = await appendImagesToSession(
        ref,
        widget.sessionId!,
        widget.imagePaths,
      );
      if (!mounted) return;
      setState(() => _finished = true);
      _safePop(ok);
      return;
    }

    final sessionId =
        await ref.read(imageIngestProvider.notifier).ingest(widget.imagePaths);
    if (!mounted) return;
    setState(() => _finished = true);
    _safePop(sessionId);
  }

  String _stepLabel(ImageIngestStep? step) => switch (step) {
        ImageIngestStep.preparing => 'Đang chuẩn bị ảnh...',
        ImageIngestStep.classifyingSubject => 'Đang nhận diện môn học...',
        ImageIngestStep.savingImages => 'Đang lưu ảnh...',
        ImageIngestStep.runningAi => 'Đang phân tích OCR & tóm tắt...',
        ImageIngestStep.done => 'Hoàn tất!',
        null => 'Đang xử lý ${widget.imagePaths.length} ảnh...',
      };

  @override
  Widget build(BuildContext context) {
    final ingest = ref.watch(imageIngestProvider);
    final isAppend = widget.sessionId != null;
    final colors = Theme.of(context).colorScheme;
    final label = ingest.message ?? _stepLabel(ingest.step);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: _finished
              ? () => _safePop()
              : () async {
                  final ok = await AppDialog.confirm(
                    context,
                    title: 'Quay lại?',
                    message: isAppend
                        ? 'Ảnh có thể vẫn đang xử lý nền. Bạn có thể xem lại buổi học sau.'
                        : 'AI có thể vẫn đang xử lý nền. Bạn có thể xem buổi học trong «Buổi học gần đây».',
                    confirmLabel: 'Quay lại',
                    cancelLabel: 'Ở lại',
                  );
                  if (ok == true && mounted) {
                    _safePop(widget.sessionId != null ? false : null);
                  }
                },
        ),
        title: Text(isAppend ? 'Đang thêm ảnh' : 'Đang phân tích AI'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            children: [
              const Spacer(),
              DocumentScanCarousel(
                imagePaths: widget.imagePaths,
                label: label,
                subLabel: 'Bạn có thể quay lại — xử lý tiếp tục chạy nền',
              ),
              const Spacer(),
              if (ingest.error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius:
                        BorderRadius.circular(AppConstants.smallRadius),
                  ),
                  child: Text(
                    ingest.error!,
                    style: TextStyle(color: colors.onErrorContainer),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
