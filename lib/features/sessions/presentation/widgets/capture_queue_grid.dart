import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/widgets/cached_file_image.dart';
import 'package:snapstudy/features/sessions/domain/entities/capture_queue_item.dart';

class CaptureQueueGrid extends StatelessWidget {
  const CaptureQueueGrid({
    super.key,
    required this.items,
    this.onRemove,
    this.onAddTap,
  });

  final List<CaptureQueueItem> items;
  final void Function(CaptureQueueItem item)? onRemove;
  final VoidCallback? onAddTap;

  @override
  Widget build(BuildContext context) {
    final cellCount = items.length + (onAddTap != null ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: cellCount,
      itemBuilder: (context, index) {
        if (onAddTap != null && index == items.length) {
          return _AddCell(onTap: onAddTap!);
        }
        final item = items[index];
        return _CaptureCell(
          item: item,
          onRemove: onRemove != null ? () => onRemove!(item) : null,
        );
      },
    );
  }
}

class _AddCell extends StatelessWidget {
  const _AddCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, color: colors.primary, size: 32),
            const SizedBox(height: 8),
            Text(
              'Thêm ảnh',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CaptureCell extends StatelessWidget {
  const _CaptureCell({required this.item, this.onRemove});

  final CaptureQueueItem item;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedFileImage(
          path: item.localPath,
          fit: BoxFit.cover,
          borderRadius: BorderRadius.circular(AppConstants.defaultRadius),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
