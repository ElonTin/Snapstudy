import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:snapstudy/core/widgets/cached_file_image.dart';
import 'package:snapstudy/features/sessions/domain/entities/capture_queue_item.dart';

/// Xem ảnh gốc toàn màn hình (pinch zoom).
class CaptureImageViewer extends StatelessWidget {
  const CaptureImageViewer({
    super.key,
    required this.items,
    this.initialIndex = 0,
  });

  final List<CaptureQueueItem> items;
  final int initialIndex;

  static Future<void> show(
    BuildContext context, {
    required List<CaptureQueueItem> items,
    int initialIndex = 0,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => CaptureImageViewer(
        items: items,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _CaptureImageViewerBody(
      items: items,
      initialIndex: initialIndex,
    );
  }
}

class _CaptureImageViewerBody extends StatefulWidget {
  const _CaptureImageViewerBody({
    required this.items,
    required this.initialIndex,
  });

  final List<CaptureQueueItem> items;
  final int initialIndex;

  @override
  State<_CaptureImageViewerBody> createState() =>
      _CaptureImageViewerBodyState();
}

class _CaptureImageViewerBodyState extends State<_CaptureImageViewerBody> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.items[_index];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Ảnh ${_index + 1}/${widget.items.length}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_outlined),
            tooltip: 'Sao chép đường dẫn',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: item.localPath));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã sao chép đường dẫn file ảnh')),
              );
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.items.length,
        onPageChanged: (i) => setState(() => _index = i),
        itemBuilder: (context, index) {
          final capture = widget.items[index];
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: CachedFileImage(
                path: capture.localPath,
                fit: BoxFit.contain,
                fullResolution: true,
              ),
            ),
          );
        },
      ),
    );
  }
}
