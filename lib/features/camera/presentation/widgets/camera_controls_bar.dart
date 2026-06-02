import 'package:flutter/material.dart';

/// Bottom controls: gallery, shutter, flash, done.
class CameraControlsBar extends StatelessWidget {
  const CameraControlsBar({
    super.key,
    required this.onGallery,
    required this.onCapture,
    required this.onFlashToggle,
    required this.onDone,
    required this.flashEnabled,
    required this.captureCount,
    required this.isCapturing,
  });

  final VoidCallback onGallery;
  final VoidCallback onCapture;
  final VoidCallback onFlashToggle;
  final VoidCallback onDone;
  final bool flashEnabled;
  final int captureCount;
  final bool isCapturing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        children: [
          _SideButton(
            icon: Icons.photo_library_outlined,
            label: 'Album',
            onPressed: onGallery,
          ),
          Expanded(
            child: Center(
              child: GestureDetector(
                onTap: isCapturing ? null : onCapture,
                child: AnimatedOpacity(
                  opacity: isCapturing ? 0.5 : 1,
                  duration: const Duration(milliseconds: 150),
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _SideButton(
            icon: flashEnabled ? Icons.flash_on : Icons.flash_off_outlined,
            label: 'Flash',
            onPressed: onFlashToggle,
            highlighted: flashEnabled,
          ),
          if (captureCount > 0) ...[
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text('Xong ($captureCount)'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onPressed,
            icon: Icon(
              icon,
              color: highlighted ? Colors.amber : Colors.white,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }
}
