import 'package:flutter/material.dart';
import 'package:snapstudy/core/constants/app_constants.dart';
import 'package:snapstudy/core/widgets/cached_file_image.dart';

/// Horizontal strip of captured shots in the current camera session.
class CaptureThumbnailStrip extends StatelessWidget {
  const CaptureThumbnailStrip({
    super.key,
    required this.paths,
    required this.selectedIndex,
    required this.onSelect,
    required this.onRemove,
  });

  final List<String> paths;
  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: paths.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = paths[index];
          final selected = index == selectedIndex;

          return GestureDetector(
            onTap: () => onSelect(index),
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: AppConstants.animationDuration,
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultRadius),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius:
                        BorderRadius.circular(AppConstants.defaultRadius - 2),
                    child: CachedFileImage(
                      path: path,
                      fit: BoxFit.cover,
                      cacheWidth: 160,
                    ),
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => onRemove(index),
                    child: const CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 12, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
