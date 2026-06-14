import 'dart:io';

import 'package:flutter/material.dart';
import 'package:snapstudy/core/performance/performance_config.dart';

/// Decodes local session photos with resize + avoids sync IO on every build.
class CachedFileImage extends StatefulWidget {
  CachedFileImage({
    super.key,
    required this.path,
    this.fit = BoxFit.cover,
    this.borderRadius,
    int? cacheWidth,
    this.fullResolution = false,
  }) : cacheWidth = fullResolution
            ? null
            : (cacheWidth ?? PerformanceConfig.captureThumbnailCacheWidth);

  final String path;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Khi null → decode full resolution (viewer, preview sau chụp).
  final int? cacheWidth;
  final bool fullResolution;

  @override
  State<CachedFileImage> createState() => _CachedFileImageState();
}

class _CachedFileImageState extends State<CachedFileImage> {
  static final _existsCache = <String, bool>{};

  late Future<bool> _existsFuture;

  @override
  void initState() {
    super.initState();
    _existsFuture = _resolveExists(widget.path);
  }

  @override
  void didUpdateWidget(CachedFileImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _existsFuture = _resolveExists(widget.path);
    }
  }

  Future<bool> _resolveExists(String path) async {
    final cached = _existsCache[path];
    if (cached != null) return cached;

    final exists = await File(path).exists();
    _existsCache[path] = exists;
    if (_existsCache.length > 500) {
      _existsCache.remove(_existsCache.keys.first);
    }
    return exists;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _existsFuture,
      builder: (context, snapshot) {
        final exists = snapshot.data == true;
        Widget child;

        if (!exists) {
          child = ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: Icon(Icons.broken_image_outlined)),
          );
        } else {
          child = Image.file(
            File(widget.path),
            fit: widget.fit,
            cacheWidth: widget.cacheWidth,
            filterQuality: widget.fullResolution
                ? FilterQuality.high
                : FilterQuality.medium,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
          );
        }

        if (widget.borderRadius != null) {
          child = ClipRRect(
            borderRadius: widget.borderRadius!,
            child: child,
          );
        }

        return RepaintBoundary(child: child);
      },
    );
  }
}
