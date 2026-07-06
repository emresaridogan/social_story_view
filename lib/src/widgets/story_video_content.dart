import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/story_item.dart';
import '../models/story_media_type.dart';
import '../utils/story_media_cache.dart';
import '../utils/story_video_controller_pool.dart';

/// Renders a video [StoryItem] using `video_player`.
///
/// The widget owns its [VideoPlayerController], reports buffering/initialization
/// state to the parent, drives playback progress and notifies completion. The
/// controller is always disposed when the widget is removed to avoid leaks.
class StoryVideoContent extends StatefulWidget {
  /// Creates a video content widget.
  const StoryVideoContent({
    super.key,
    required this.item,
    required this.isPaused,
    required this.isMuted,
    required this.onInitialized,
    required this.onProgress,
    required this.onCompleted,
    required this.onBuffering,
    required this.onError,
    this.restartToken = 0,
    this.loadingBuilder,
    this.errorBuilder,
  });

  /// The video story to render.
  final StoryItem item;

  /// Changes whenever the parent wants the same video to replay from the start.
  /// Lets an already-initialized controller restart in place without showing a
  /// loading spinner.
  final int restartToken;

  /// Whether the parent currently wants playback paused.
  final bool isPaused;

  /// Whether the video audio should be muted.
  final bool isMuted;

  /// Called with the real video duration once initialized.
  final void Function(Duration duration) onInitialized;

  /// Called continuously with playback progress (`0.0`–`1.0`).
  final void Function(double progress) onProgress;

  /// Called once the video reaches its end.
  final VoidCallback onCompleted;

  /// Called when buffering starts (`true`) or ends (`false`).
  final void Function(bool isBuffering) onBuffering;

  /// Called when the video fails to load.
  final void Function(Object error) onError;

  /// Optional loading placeholder builder.
  final WidgetBuilder? loadingBuilder;

  /// Optional error widget builder.
  final Widget Function(BuildContext, Object)? errorBuilder;

  @override
  State<StoryVideoContent> createState() => _StoryVideoContentState();
}

class _StoryVideoContentState extends State<StoryVideoContent> {
  VideoPlayerController? _controller;
  Object? _error;
  bool _initialized = false;
  bool _completed = false;
  bool _wasBuffering = false;
  // Becomes true once we observe the controller actually playing since the
  // last (re)start. Completion is only detected after real playback has begun,
  // so a stale `position == duration` value (e.g. just after reusing a pooled
  // controller, before the async seek-to-zero lands) can't fire a false end.
  bool _hasPlayed = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  /// Pool key for reusable controllers. Only network videos are pooled.
  String? get _poolKey =>
      widget.item.source == StorySource.network && widget.item.url.isNotEmpty
          ? widget.item.url
          : null;

  void _setup() {
    // Reuse an already-initialized controller from the pool when available so
    // reopening the story is instant (no loading spinner).
    final poolKey = _poolKey;
    if (poolKey != null) {
      final pooled = StoryVideoControllerPool.acquire(poolKey);
      if (pooled != null && pooled.value.isInitialized) {
        _attachReady(pooled);
        return;
      }
      pooled?.dispose();
    }
    _createAndInit();
  }

  void _attachReady(VideoPlayerController controller) {
    _controller = controller;
    _initialized = true;
    _completed = false;
    _hasPlayed = false;
    controller.addListener(_onTick);
    controller.setVolume(widget.isMuted ? 0 : 1);
    controller.seekTo(Duration.zero);
    // Release the buffering pause the parent added on (re)start: nothing to
    // wait for since the controller is already initialized.
    widget.onBuffering(false);
    widget.onInitialized(controller.value.duration);
    if (!widget.isPaused) {
      controller.play();
    }
    if (mounted) setState(() {});
  }

  Future<void> _createAndInit() async {
    final item = widget.item;
    VideoPlayerController controller;
    switch (item.source) {
      case StorySource.network:
        // Play from the on-disk cache so reopening the story is instant. When
        // the file is not cached yet, download it first, then play from file.
        File? cachedFile;
        try {
          final cached = await StoryMediaCache.getCached(item.url);
          cachedFile =
              cached?.file ?? (await StoryMediaCache.resolve(item.url)).file;
        } catch (_) {
          cachedFile = null;
        }
        if (!mounted) return;
        controller = cachedFile != null
            ? VideoPlayerController.file(cachedFile)
            : VideoPlayerController.networkUrl(Uri.parse(item.url));
      case StorySource.asset:
        controller = VideoPlayerController.asset(item.url);
      case StorySource.file:
        controller = VideoPlayerController.file(File(item.url));
    }
    _controller = controller;
    controller.addListener(_onTick);
    widget.onBuffering(true);
    try {
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      await controller.setVolume(widget.isMuted ? 0 : 1);
      _initialized = true;
      widget.onBuffering(false);
      widget.onInitialized(controller.value.duration);
      if (!widget.isPaused) {
        await controller.play();
      }
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      widget.onBuffering(false);
      setState(() => _error = error);
      widget.onError(error);
    }
  }

  void _onTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final value = controller.value;

    final buffering = value.isBuffering;
    if (buffering != _wasBuffering) {
      _wasBuffering = buffering;
      widget.onBuffering(buffering);
    }

    if (value.isPlaying) _hasPlayed = true;

    final total = value.duration.inMilliseconds;
    if (total > 0) {
      final progress = value.position.inMilliseconds / total;
      widget.onProgress(progress.clamp(0.0, 1.0));
    }

    final reachedEnd = _hasPlayed &&
        value.position >= value.duration &&
        value.duration > Duration.zero &&
        !value.isPlaying;
    if (reachedEnd && !_completed) {
      _completed = true;
      widget.onCompleted();
    }
  }

  @override
  void didUpdateWidget(covariant StoryVideoContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final controller = _controller;
    if (controller == null || !_initialized) return;

    // Same video asked to replay from the start (e.g. resuming a user from
    // their last story): restart in place instead of re-initializing.
    if (widget.restartToken != oldWidget.restartToken) {
      _completed = false;
      _hasPlayed = false;
      controller.seekTo(Duration.zero);
      // Release the buffering pause the parent set on restart.
      widget.onBuffering(false);
      widget.onInitialized(controller.value.duration);
      if (widget.isPaused) {
        controller.pause();
      } else {
        controller.play();
      }
      return;
    }

    if (widget.isMuted != oldWidget.isMuted) {
      controller.setVolume(widget.isMuted ? 0 : 1);
    }
    if (widget.isPaused != oldWidget.isPaused) {
      if (widget.isPaused) {
        controller.pause();
      } else if (!_completed) {
        controller.play();
      }
    }
  }

  @override
  void dispose() {
    final controller = _controller;
    controller?.removeListener(_onTick);
    final poolKey = _poolKey;
    if (controller != null &&
        _initialized &&
        _error == null &&
        poolKey != null) {
      // Keep the initialized controller alive for instant reopen.
      StoryVideoControllerPool.release(poolKey, controller);
    } else {
      controller?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorBuilder?.call(context, _error!) ??
          const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.videocam_off_outlined,
                  color: Colors.white54, size: 48),
            ),
          );
    }

    final controller = _controller;
    if (!_initialized || controller == null) {
      return widget.loadingBuilder?.call(context) ??
          const ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}
