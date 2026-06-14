import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:snapstudy/features/mindmap/domain/entities/session_mindmap.dart';
import 'package:snapstudy/features/mindmap/domain/services/mindmap_tree_layout.dart';
import 'package:snapstudy/features/mindmap/presentation/utils/mindmap_viewport_transform.dart';
import 'package:snapstudy/features/mindmap/presentation/widgets/mindmap_edge_painter.dart';
import 'package:snapstudy/features/mindmap/presentation/widgets/mindmap_node_chip.dart';

/// Interactive mindmap — pinch, kéo, chạm đúp zoom thông minh tại điểm chạm.
class MindmapCanvas extends StatefulWidget {
  const MindmapCanvas({
    super.key,
    required this.mindmap,
    this.onNodeSelected,
  });

  final SessionMindmap mindmap;
  final ValueChanged<String>? onNodeSelected;

  @override
  State<MindmapCanvas> createState() => MindmapCanvasState();
}

class MindmapCanvasState extends State<MindmapCanvas> {
  final _transformationController = TransformationController();
  final _collapsedIds = <String>{};
  Size? _lastViewport;
  Size? _lastCanvasSize;
  var _userAdjustedView = false;
  final _zoomPercent = ValueNotifier(100);
  Offset? _lastDoubleTapFocal;
  var _showZoomHud = false;
  Timer? _hideHudTimer;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _hideHudTimer?.cancel();
    _transformationController.removeListener(_onTransformChanged);
    _transformationController.dispose();
    _zoomPercent.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final next = MindmapViewportTransform.zoomPercent(
      _transformationController.value,
    );
    if (_zoomPercent.value != next) {
      _zoomPercent.value = next;
    }
  }

  @override
  void didUpdateWidget(MindmapCanvas oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mindmap != widget.mindmap) {
      _userAdjustedView = false;
      _scheduleFit();
    }
  }

  void _toggleCollapse(String id) {
    setState(() {
      if (_collapsedIds.contains(id)) {
        _collapsedIds.remove(id);
      } else {
        _collapsedIds.add(id);
      }
    });
    _userAdjustedView = false;
    _scheduleFit();
  }

  void _scheduleFit() {
    WidgetsBinding.instance.addPostFrameCallback((_) => fitToView());
  }

  void _flashZoomHud() {
    if (!_showZoomHud) setState(() => _showZoomHud = true);
    _hideHudTimer?.cancel();
    _hideHudTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _showZoomHud = false);
    });
  }

  /// Thu nhỏ/phóng to để thấy toàn bộ sơ đồ trong khung nhìn.
  void fitToView() {
    final viewport = _lastViewport;
    final canvas = _lastCanvasSize;
    if (viewport == null || canvas == null) return;

    _transformationController.value = MindmapViewportTransform.fit(
      viewport: viewport,
      canvas: canvas,
    );
    _userAdjustedView = false;
    _flashZoomHud();
  }

  void zoomBy(double factor, {Offset? focal}) {
    final viewport = _lastViewport;
    if (viewport == null) return;

    final focalPoint = focal ??
        Offset(viewport.width / 2, viewport.height / 2);

    _transformationController.value = MindmapViewportTransform.zoomAt(
      current: _transformationController.value,
      focal: focalPoint,
      factor: factor,
    );
    _userAdjustedView = true;
    _flashZoomHud();
  }

  void _handleDoubleTap() {
    final viewport = _lastViewport;
    if (viewport == null) return;

    final focal = _lastDoubleTapFocal ??
        Offset(viewport.width / 2, viewport.height / 2);
    final currentScale = MindmapViewportTransform.readScale(
      _transformationController.value,
    );

    // Chạm đúp: phóng to tại điểm chạm; nếu đã phóng lớn thì về fit-to-view.
    if (currentScale < 1.05) {
      zoomBy(1.85, focal: focal);
    } else if (currentScale < 1.8) {
      zoomBy(1.5, focal: focal);
    } else {
      fitToView();
    }
    _userAdjustedView = true;
  }

  void _handlePointerScroll(PointerScrollEvent event) {
    // Chuột / trackpad: cuộn để zoom tại vị trí con trỏ.
    final delta = event.scrollDelta.dy;
    if (delta == 0) return;
    final factor = delta < 0 ? 1.08 : 1 / 1.08;
    zoomBy(factor, focal: event.localPosition);
    _userAdjustedView = true;
  }

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.sizeOf(context).width;
    final metrics = MindmapLayoutMetrics(
      nodeWidth: screenW < 380 ? 136 : MindmapTreeLayout.nodeWidth,
      nodeHeight: screenW < 380 ? 48 : MindmapTreeLayout.nodeHeight,
    );

    final layout = MindmapTreeLayout.compute(
      mindmap: widget.mindmap,
      collapsedIds: _collapsedIds,
      metrics: metrics,
    );
    final lineColor =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.45);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final viewportChanged = _lastViewport != viewport;
        final canvasChanged = _lastCanvasSize != layout.canvasSize;

        if (viewportChanged || canvasChanged) {
          _lastViewport = viewport;
          _lastCanvasSize = layout.canvasSize;
          if (!_userAdjustedView || canvasChanged) {
            _scheduleFit();
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Listener(
              onPointerSignal: (event) {
                if (event is PointerScrollEvent) {
                  _handlePointerScroll(event);
                }
              },
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onDoubleTapDown: (details) {
                  _lastDoubleTapFocal = details.localPosition;
                },
                onDoubleTap: _handleDoubleTap,
                child: InteractiveViewer(
                  transformationController: _transformationController,
                  boundaryMargin: const EdgeInsets.all(160),
                  minScale: MindmapViewportTransform.minScale,
                  maxScale: MindmapViewportTransform.maxScale,
                  clipBehavior: Clip.none,
                  panEnabled: true,
                  scaleEnabled: true,
                  onInteractionStart: (_) {
                    _userAdjustedView = true;
                    _flashZoomHud();
                  },
                  onInteractionEnd: (_) => _flashZoomHud(),
                  child: RepaintBoundary(
                    child: SizedBox(
                      width: layout.canvasSize.width,
                      height: layout.canvasSize.height,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: layout.canvasSize,
                            painter: MindmapEdgePainter(
                              edges: layout.edges,
                              lineColor: lineColor,
                            ),
                          ),
                          ...layout.nodes.map((ln) {
                            final cluster =
                                widget.mindmap.clusterFor(ln.node.clusterId);
                            final isCollapsed =
                                _collapsedIds.contains(ln.node.id);
                            return Positioned(
                              left: ln.position.dx,
                              top: ln.position.dy,
                              child: MindmapNodeChip(
                                node: ln.node,
                                cluster: cluster,
                                isCollapsed: isCollapsed,
                                isRoot: ln.node.id == widget.mindmap.rootId,
                                nodeWidth: metrics.nodeWidth,
                                nodeHeight: metrics.nodeHeight,
                                onTap: () =>
                                    widget.onNodeSelected?.call(ln.node.id),
                                onToggleCollapse: ln.node.hasChildren
                                    ? () => _toggleCollapse(ln.node.id)
                                    : null,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 8,
              child: AnimatedOpacity(
                opacity: _showZoomHud ? 1 : 0.65,
                duration: const Duration(milliseconds: 200),
                child: ValueListenableBuilder<int>(
                  valueListenable: _zoomPercent,
                  builder: (context, percent, _) => _ZoomHud(percent: percent),
                ),
              ),
            ),
            Positioned(
              right: 8,
              bottom: 8,
              child: _ZoomControls(
                onFit: fitToView,
                onZoomIn: () => zoomBy(1.22),
                onZoomOut: () => zoomBy(1 / 1.22),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ZoomHud extends StatelessWidget {
  const _ZoomHud({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 1,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          '$percent%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ),
    );
  }
}

class _ZoomControls extends StatelessWidget {
  const _ZoomControls({
    required this.onFit,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final VoidCallback onFit;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      color: colors.surfaceContainerHighest.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Xem toàn bộ',
            onPressed: onFit,
            icon: const Icon(Icons.fit_screen_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Phóng to',
            onPressed: onZoomIn,
            icon: const Icon(Icons.add, size: 20),
          ),
          IconButton(
            tooltip: 'Thu nhỏ',
            onPressed: onZoomOut,
            icon: const Icon(Icons.remove, size: 20),
          ),
        ],
      ),
    );
  }
}

/// Cluster legend for topic grouping.
class MindmapClusterLegend extends StatelessWidget {
  const MindmapClusterLegend({super.key, required this.mindmap});

  final SessionMindmap mindmap;

  @override
  Widget build(BuildContext context) {
    if (mindmap.clusters.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: mindmap.clusters.map((c) {
        final color = Color(c.colorValue);
        return Chip(
          avatar: CircleAvatar(backgroundColor: color, radius: 8),
          label: Text(c.label),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }
}
