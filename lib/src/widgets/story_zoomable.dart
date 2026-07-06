import 'package:flutter/material.dart';

/// Wraps story media so it can be pinch-zoomed with two fingers.
///
/// Single-finger gestures (tap to advance, hold to pause, horizontal swipe
/// between users, swipe down to dismiss) are intentionally left to the parent:
/// panning is disabled so only a two-finger pinch scales the content. When the
/// fingers are lifted the content animates smoothly back to its original size.
///
/// While a zoom gesture is active [onZoomStart] fires (pause the story) and
/// once it settles back [onZoomEnd] fires (resume).
class StoryZoomable extends StatefulWidget {
  /// Creates a pinch-to-zoom wrapper around [child].
  const StoryZoomable({
    super.key,
    required this.child,
    this.onZoomStart,
    this.onZoomEnd,
    this.maxScale = 4.0,
  });

  /// The media to make zoomable.
  final Widget child;

  /// Called when a two-finger zoom gesture begins.
  final VoidCallback? onZoomStart;

  /// Called once every finger is lifted and the content starts snapping back.
  final VoidCallback? onZoomEnd;

  /// Maximum zoom factor.
  final double maxScale;

  @override
  State<StoryZoomable> createState() => _StoryZoomableState();
}

class _StoryZoomableState extends State<StoryZoomable>
    with SingleTickerProviderStateMixin {
  final TransformationController _controller = TransformationController();
  late final AnimationController _resetController;
  Animation<Matrix4>? _resetAnimation;
  bool _zooming = false;
  int _pointerCount = 0;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        final animation = _resetAnimation;
        if (animation != null) _controller.value = animation.value;
      });
  }

  @override
  void dispose() {
    _resetController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    _pointerCount++;
    if (_pointerCount >= 2 && !_zooming) {
      if (_resetController.isAnimating) _resetController.stop();
      _zooming = true;
      widget.onZoomStart?.call();
    }
  }

  void _onPointerUp(PointerEvent event) {
    if (_pointerCount > 0) _pointerCount--;
    // Snap back only once every finger has left the screen, so a slow
    // finger-by-finger release still resets reliably.
    if (_pointerCount == 0) {
      if (_zooming) {
        _zooming = false;
        widget.onZoomEnd?.call();
      }
      _animateReset();
    }
  }

  void _animateReset() {
    if (_controller.value == Matrix4.identity()) return;
    _resetAnimation = Matrix4Tween(
      begin: _controller.value,
      end: Matrix4.identity(),
    ).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOut),
    );
    _resetController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerUp,
      child: InteractiveViewer(
        transformationController: _controller,
        panEnabled: false,
        scaleEnabled: true,
        minScale: 1,
        maxScale: widget.maxScale,
        clipBehavior: Clip.none,
        child: widget.child,
      ),
    );
  }
}
