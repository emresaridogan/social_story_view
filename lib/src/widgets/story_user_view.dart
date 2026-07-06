import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../controllers/story_user_playback.dart';
import '../controllers/story_view_controller.dart' show StoryPauseReason;
import '../models/story_callbacks.dart';
import '../models/story_item.dart';
import '../models/story_media_type.dart';
import '../models/story_progress_style.dart';
import '../models/story_link.dart';
import '../models/story_user.dart';
import 'default_story_header.dart';
import 'story_image_content.dart';
import 'story_link_button.dart';
import 'story_progress_bar.dart';
import 'story_text_content.dart';
import 'story_video_content.dart';
import 'story_zoomable.dart';

/// Renders a single user's story group: the segmented progress bar, the active
/// story content, the header/footer overlays and all in-page gestures.
///
/// This widget is created by [StoryView] for each user page and is not meant to
/// be used directly.
class StoryUserView extends StatefulWidget {
  /// Creates a single-user story page.
  const StoryUserView({
    super.key,
    required this.user,
    required this.initialIndex,
    required this.isActive,
    required this.isMuted,
    required this.progressStyle,
    required this.imageDuration,
    required this.contentFit,
    required this.onRegister,
    required this.onUnregister,
    required this.onStoryShow,
    required this.onStoryComplete,
    required this.onAllStoriesComplete,
    required this.onRequestNextUser,
    required this.onRequestPreviousUser,
    required this.onPositionChanged,
    this.headerBuilder,
    this.footerBuilder,
    this.overlayBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onClosePressed,
    this.headerConfig = const StoryHeaderConfig(),
    this.headerStyle = const StoryHeaderStyle(),
    this.topScrimColor = const Color(0x73000000),
    this.bottomScrimColor = const Color(0x8C000000),
    this.onLinkTap,
  });

  /// The user whose stories are displayed.
  final StoryUser user;

  /// The story index to start from when this page first becomes active.
  final int initialIndex;

  /// Whether this is the currently visible page.
  final bool isActive;

  /// Whether video audio should be muted.
  final bool isMuted;

  /// Styling for the progress bar.
  final StoryProgressStyle progressStyle;

  /// Default display duration for image/text stories without an explicit one.
  final Duration imageDuration;

  /// How media is inscribed into the viewport.
  final BoxFit contentFit;

  /// Registers this page's playback handle with the parent.
  final void Function(StoryUserPlayback) onRegister;

  /// Unregisters this page's playback handle from the parent.
  final void Function(StoryUserPlayback) onUnregister;

  /// Fired when a story becomes visible.
  final OnStoryShow onStoryShow;

  /// Fired when a story finishes playing.
  final OnStoryComplete onStoryComplete;

  /// Fired when the user's last story completes.
  final OnAllStoriesComplete onAllStoriesComplete;

  /// Requests the parent to advance to the next user.
  final VoidCallback onRequestNextUser;

  /// Requests the parent to go back to the previous user.
  final VoidCallback onRequestPreviousUser;

  /// Reports the current story index to the parent (for controller sync).
  final void Function(int storyIndex) onPositionChanged;

  /// Optional custom header builder.
  final StoryHeaderBuilder? headerBuilder;

  /// Optional custom footer builder.
  final StoryFooterBuilder? footerBuilder;

  /// Optional custom overlay builder drawn over the media content.
  final StoryOverlayBuilder? overlayBuilder;

  /// Optional loading placeholder builder.
  final StoryLoadingBuilder? loadingBuilder;

  /// Optional error widget builder.
  final StoryErrorBuilder? errorBuilder;

  /// Fired when the default header close button is pressed.
  final VoidCallback? onClosePressed;

  /// Controls which user info elements the default header shows.
  final StoryHeaderConfig headerConfig;

  /// Color and text styling for the default header.
  final StoryHeaderStyle headerStyle;

  /// Color of the top gradient scrim (behind progress bar and header).
  final Color topScrimColor;

  /// Color of the bottom gradient scrim (behind footer and link button).
  final Color bottomScrimColor;

  /// Called when the story's link call-to-action is tapped.
  final void Function(StoryItem item, StoryLink link)? onLinkTap;

  @override
  State<StoryUserView> createState() => _StoryUserViewState();
}

class _StoryUserViewState extends State<StoryUserView>
    with SingleTickerProviderStateMixin
    implements StoryUserPlayback {
  late final AnimationController _animation;
  final ValueNotifier<double> _progress = ValueNotifier<double>(0);
  final Set<StoryPauseReason> _pauses = <StoryPauseReason>{};

  int _index = 0;
  bool _mediaLoaded = false;
  bool _started = false;
  // Incremented on every (re)start so media content widgets (notably the video
  // player, which owns initialization state) get a fresh State and re-run their
  // load/play logic even when the same story is shown again.
  int _playGeneration = 0;

  StoryItem get _item => widget.user.stories[_index];

  bool get _effectivePaused => !widget.isActive || _pauses.isNotEmpty;

  /// Whether the video controller itself should be paused.
  ///
  /// Crucially this ignores [StoryPauseReason.buffering]: pausing a controller
  /// while it is buffering can stop it from ever emitting the tick that clears
  /// the buffering state, which would leave the story frozen until it is
  /// reopened. Buffering naturally freezes progress (the position stops
  /// advancing) without us pausing the controller, so the player keeps working
  /// to finish buffering on its own.
  bool get _videoPaused =>
      !widget.isActive || _pauses.any((r) => r != StoryPauseReason.buffering);

  @override
  int get currentStoryIndex => _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.user.stories.length - 1);
    _animation = AnimationController(vsync: this)
      ..addListener(_onAnimationTick)
      ..addStatusListener(_onAnimationStatus);
    if (widget.isActive) {
      widget.onRegister(this);
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _startStory(notify: true));
    }
  }

  @override
  void didUpdateWidget(covariant StoryUserView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      widget.onRegister(this);
      // didUpdateWidget runs during the parent's build phase, so starting the
      // story synchronously here would call setState and user callbacks
      // (onStoryShow) mid-build. Defer the playback side effects to the end of
      // the frame, mirroring the initState behaviour.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isActive) return;
        if (!_started) {
          // Re-sync to the latest requested start index (e.g. resuming a
          // previous user from their last story).
          _index = widget.initialIndex.clamp(0, widget.user.stories.length - 1);
          _startStory(notify: true);
        } else {
          _applyPlayState();
        }
      });
    } else if (!widget.isActive && oldWidget.isActive) {
      widget.onUnregister(this);
      _animation.stop();
      _progress.value = 0;
      _started = false;
      _index = widget.initialIndex.clamp(0, widget.user.stories.length - 1);
    }
  }

  @override
  void dispose() {
    if (widget.isActive) widget.onUnregister(this);
    _animation
      ..removeListener(_onAnimationTick)
      ..removeStatusListener(_onAnimationStatus)
      ..dispose();
    _progress.dispose();
    super.dispose();
  }

  // --- Playback core -------------------------------------------------------

  void _startStory({bool notify = false}) {
    _started = true;
    _mediaLoaded = false;
    _playGeneration++;
    _progress.value = 0;
    _animation.stop();
    _animation.value = 0;

    final item = _item;
    widget.onPositionChanged(_index);
    if (notify) widget.onStoryShow(widget.user, item, _index);

    switch (item.type) {
      case StoryMediaType.text:
        _mediaLoaded = true;
        _animation.duration = item.duration ?? widget.imageDuration;
        _applyPlayState();
      case StoryMediaType.image:
        // Hold via buffering until the image is decoded; onLoaded releases it.
        _pauses.add(StoryPauseReason.buffering);
        _animation.duration = item.duration ?? widget.imageDuration;
        _applyPlayState();
      case StoryMediaType.video:
        // Video drives its own progress; initialization holds via buffering.
        _pauses.add(StoryPauseReason.buffering);
        _applyPlayState();
    }
  }

  void _applyPlayState() {
    if (!mounted) return;
    final item = _item;
    if (item.type == StoryMediaType.image || item.type == StoryMediaType.text) {
      if (_effectivePaused || !_mediaLoaded) {
        if (_animation.isAnimating) _animation.stop();
      } else if (!_animation.isAnimating && _animation.value < 1.0) {
        _animation.forward();
      }
    }
    // Trigger rebuild so video content receives the new paused/muted state.
    _safeRebuild();
  }

  /// Rebuilds the page. Child content widgets (e.g. the video player) can emit
  /// buffering/load notifications from their own `initState` while this widget
  /// (or an ancestor) is still building/laying out, so calling [setState]
  /// directly would throw. Defer to after the current frame when that happens.
  void _safeRebuild() {
    if (!mounted) return;
    final phase = WidgetsBinding.instance.schedulerPhase;
    // Only `idle` and `postFrameCallbacks` are safe phases to synchronously
    // mark the element dirty. Every other phase means a build/layout/paint pass
    // may currently be running, so we defer to the next post-frame callback.
    final isSafePhase = phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;
    if (isSafePhase) {
      setState(() {});
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  /// Updates the progress notifier. Progress ticks (from the animation or the
  /// video player) can fire while the widget tree is still building/laying out,
  /// which would mark the listening [ValueListenableBuilder] dirty mid-build.
  /// Defer the update to the next frame when that happens.
  void _setProgress(double value) {
    if (!mounted) return;
    final phase = WidgetsBinding.instance.schedulerPhase;
    final isSafePhase = phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;
    if (isSafePhase) {
      _progress.value = value;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _progress.value = value;
      });
    }
  }

  /// Runs a state-mutating [action] (e.g. story navigation) safely with respect
  /// to the current frame phase. Navigation can be triggered by a video tick or
  /// gesture that lands while a build/layout pass is running, so calling
  /// [setState] or consumer callbacks synchronously would throw. Defer to the
  /// next frame when that happens.
  void _runSafely(VoidCallback action) {
    if (!mounted) return;
    final phase = WidgetsBinding.instance.schedulerPhase;
    final isSafePhase = phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks;
    if (isSafePhase) {
      action();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });
    }
  }

  void _onAnimationTick() {
    _setProgress(_animation.value);
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _complete();
    }
  }

  void _complete() {
    _runSafely(() {
      widget.onStoryComplete(widget.user, _item, _index);
      _goNext(fromCompletion: true);
    });
  }

  void _goNext({bool fromCompletion = false}) {
    _runSafely(() {
      if (_index < widget.user.stories.length - 1) {
        setState(() => _index++);
        _startStory(notify: true);
      } else {
        _setProgress(1.0);
        widget.onAllStoriesComplete(widget.user);
        widget.onRequestNextUser();
      }
    });
  }

  void _goPrevious() {
    _runSafely(() {
      if (_index > 0) {
        setState(() => _index--);
        _startStory(notify: true);
      } else {
        widget.onRequestPreviousUser();
      }
    });
  }

  // --- StoryUserPlayback ---------------------------------------------------

  @override
  void pause(StoryPauseReason reason) {
    _pauses.add(reason);
    _applyPlayState();
  }

  @override
  void resume(StoryPauseReason reason) {
    _pauses.remove(reason);
    _applyPlayState();
  }

  @override
  void nextStory() => _goNext();

  @override
  void previousStory() => _goPrevious();

  @override
  void jumpToStory(int index) {
    _runSafely(() {
      final clamped = index.clamp(0, widget.user.stories.length - 1);
      setState(() => _index = clamped);
      _startStory(notify: true);
    });
  }

  // --- Media callbacks -----------------------------------------------------

  void _onMediaLoaded() {
    if (!mounted) return;
    _mediaLoaded = true;
    _pauses.remove(StoryPauseReason.buffering);
    _applyPlayState();
  }

  void _onMediaError(Object error) {
    if (!mounted) return;
    _pauses.remove(StoryPauseReason.buffering);
    _applyPlayState();
  }

  void _onVideoInitialized(Duration duration) {
    _mediaLoaded = true;
  }

  void _onVideoProgress(double value) {
    _setProgress(value);
  }

  void _onVideoBuffering(bool buffering) {
    if (buffering) {
      _pauses.add(StoryPauseReason.buffering);
    } else {
      _pauses.remove(StoryPauseReason.buffering);
    }
    _applyPlayState();
  }

  void _onVideoCompleted() {
    _runSafely(() {
      widget.onStoryComplete(widget.user, _item, _index);
      _goNext(fromCompletion: true);
    });
  }

  // --- Gestures ------------------------------------------------------------

  void _onTapUp(TapUpDetails details, BoxConstraints constraints) {
    // When the keyboard is open (e.g. typing a reply), a tap on the story
    // should just dismiss it instead of navigating between stories.
    if (MediaQuery.viewInsetsOf(context).bottom > 0) {
      FocusManager.instance.primaryFocus?.unfocus();
      return;
    }
    final dx = details.localPosition.dx;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final third = constraints.maxWidth / 3;
    final tappedStart = dx < third;
    // In RTL the visual "start" (left) is the next direction.
    final goPrevious = isRtl ? !tappedStart : tappedStart;
    if (goPrevious) {
      _goPrevious();
    } else {
      _goNext();
    }
  }

  // --- Build ---------------------------------------------------------------

  bool _isBottomAligned(Alignment alignment) => alignment.y > 0;

  Widget _buildContent() {
    final item = _item;
    switch (item.type) {
      case StoryMediaType.text:
        return StoryTextContent(item: item);
      case StoryMediaType.image:
        return StoryZoomable(
          onZoomStart: () => pause(StoryPauseReason.zoom),
          onZoomEnd: () => resume(StoryPauseReason.zoom),
          child: StoryImageContent(
            key: ValueKey<String>('img_${item.id}_$_playGeneration'),
            item: item,
            fit: widget.contentFit,
            onLoaded: _onMediaLoaded,
            onError: _onMediaError,
            loadingBuilder: widget.loadingBuilder == null
                ? null
                : (context) =>
                    widget.loadingBuilder!(context, widget.user, item),
            errorBuilder: widget.errorBuilder == null
                ? null
                : (context, error) =>
                    widget.errorBuilder!(context, widget.user, item, error),
          ),
        );
      case StoryMediaType.video:
        return StoryZoomable(
          onZoomStart: () => pause(StoryPauseReason.zoom),
          onZoomEnd: () => resume(StoryPauseReason.zoom),
          child: StoryVideoContent(
            key: ValueKey<String>('vid_${item.id}'),
            item: item,
            restartToken: _playGeneration,
            isPaused: _videoPaused,
            isMuted: widget.isMuted,
            onInitialized: _onVideoInitialized,
            onProgress: _onVideoProgress,
            onCompleted: _onVideoCompleted,
            onBuffering: _onVideoBuffering,
            onError: _onMediaError,
            loadingBuilder: widget.loadingBuilder == null
                ? null
                : (context) =>
                    widget.loadingBuilder!(context, widget.user, item),
            errorBuilder: widget.errorBuilder == null
                ? null
                : (context, error) =>
                    widget.errorBuilder!(context, widget.user, item, error),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = _item;
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _onTapUp(details, constraints),
          onLongPressStart: (_) => pause(StoryPauseReason.hold),
          onLongPressEnd: (_) => resume(StoryPauseReason.hold),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned.fill(child: _buildContent()),
              // Custom overlay drawn directly over the media (e.g. captions,
              // titles or marketing copy placed on top of the image/video).
              if (widget.overlayBuilder != null)
                Positioned.fill(
                  child: widget.overlayBuilder!(
                      context, widget.user, item, _index),
                ),
              // Tappable call-to-action link for non-bottom alignments.
              if (item.link != null &&
                  widget.onLinkTap != null &&
                  !_isBottomAligned(item.link!.alignment))
                Positioned.fill(
                  child: StoryLinkButton(
                    link: item.link!,
                    onTap: () => widget.onLinkTap!(item, item.link!),
                  ),
                ),
              // Overlays (do not absorb taps unless their own children do).
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        widget.topScrimColor,
                        widget.topScrimColor.withValues(alpha: 0),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SafeArea(
                        bottom: false,
                        child: StoryProgressBar(
                          itemCount: widget.user.stories.length,
                          currentIndex: _index,
                          progress: _progress,
                          style: widget.progressStyle,
                        ),
                      ),
                      widget.headerBuilder != null
                          ? widget.headerBuilder!(
                              context, widget.user, item, _index)
                          : DefaultStoryHeader(
                              user: widget.user,
                              item: item,
                              onClose: widget.onClosePressed,
                              style: widget.headerStyle,
                              showAvatar: widget.headerConfig.showUserInfo &&
                                  widget.headerConfig.showAvatar,
                              showUsername: widget.headerConfig.showUserInfo &&
                                  widget.headerConfig.showUsername,
                              showTimestamp: widget.headerConfig.showUserInfo &&
                                  widget.headerConfig.showTimestamp,
                              showCloseButton:
                                  widget.headerConfig.showCloseButton,
                            ),
                    ],
                  ),
                ),
              ),
              // Bottom-aligned call-to-action link sits above the footer
              // (reply bar) so it is never hidden behind the message input.
              if ((item.link != null &&
                      widget.onLinkTap != null &&
                      _isBottomAligned(item.link!.alignment)) ||
                  widget.footerBuilder != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: <Color>[
                          widget.bottomScrimColor,
                          widget.bottomScrimColor.withValues(alpha: 0),
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (item.link != null &&
                            widget.onLinkTap != null &&
                            _isBottomAligned(item.link!.alignment))
                          StoryLinkButton(
                            link: item.link!,
                            onTap: () => widget.onLinkTap!(item, item.link!),
                          ),
                        if (widget.footerBuilder != null)
                          widget.footerBuilder!(
                              context, widget.user, item, _index),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
