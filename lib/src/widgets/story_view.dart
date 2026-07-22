import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/story_user_playback.dart';
import '../controllers/story_view_controller.dart';
import '../models/story_callbacks.dart';
import '../models/story_item.dart';
import '../models/story_link.dart';
import '../models/story_media_type.dart';
import '../models/story_progress_style.dart';
import '../models/story_transition.dart';
import '../models/story_user.dart';
import '../models/story_view_theme.dart';
import '../utils/story_media_cache.dart';
import 'default_story_header.dart';
import 'story_transitions.dart';
import 'story_user_view.dart';

/// A full-screen, Instagram/WhatsApp style story viewer for a list of
/// [StoryUser]s.
///
/// Each user's stories are shown in sequence with a segmented progress bar.
/// Tap the right side to advance, the left side to go back, hold to pause, and
/// swipe horizontally to move between users. Drag down to dismiss.
///
/// Drive it programmatically by passing a [StoryViewController].
class StoryView extends StatefulWidget {
  /// Creates a story viewer.
  const StoryView({
    super.key,
    required this.users,
    this.controller,
    this.initialUserIndex = 0,
    this.initialStoryIndex,
    this.transition = StoryTransition.cube,
    this.progressStyle,
    this.imageDuration = const Duration(seconds: 10),
    this.contentFit = BoxFit.contain,
    this.muted = false,
    this.backgroundColor,
    this.theme = const StoryViewTheme(),
    this.swipeDownToDismiss = true,
    this.headerConfig = const StoryHeaderConfig(),
    this.headerStyle,
    this.headerBuilder,
    this.footerBuilder,
    this.overlayBuilder,
    this.loadingBuilder,
    this.errorBuilder,
    this.onStoryShow,
    this.onStoryComplete,
    this.onAllStoriesComplete,
    this.onSwipeUp,
    this.onStoryButtonTap,
    this.onClose,
  }) : assert(users.length > 0, 'StoryView requires at least one user');

  /// The users (and their stories) to display.
  final List<StoryUser> users;

  /// Optional external controller for programmatic playback control.
  final StoryViewController? controller;

  /// Index of the user to open initially.
  final int initialUserIndex;

  /// Story index to open within the initial user. When `null` the first unseen
  /// story is used.
  final int? initialStoryIndex;

  /// Animation used when moving between users.
  final StoryTransition transition;

  /// Styling for the segmented progress bar. When `null`, [theme]'s
  /// `progressStyle` is used.
  final StoryProgressStyle? progressStyle;

  /// Default duration for image/text stories without an explicit duration.
  final Duration imageDuration;

  /// How media is inscribed into the viewport.
  final BoxFit contentFit;

  /// Whether video audio starts muted.
  final bool muted;

  /// Background color behind the content. When `null`, [theme]'s
  /// `backgroundColor` is used.
  final Color? backgroundColor;

  /// The coordinated light/dark theme for the viewer. Supplies defaults for the
  /// progress bar, header, scrims and background. Override the whole thing with
  /// [StoryViewTheme.light]/[StoryViewTheme.dark] or tweak it via
  /// [StoryViewTheme.copyWith]. Individual params like [progressStyle],
  /// [backgroundColor] and [headerStyle] take precedence when provided.
  final StoryViewTheme theme;

  /// Whether dragging down dismisses the viewer.
  final bool swipeDownToDismiss;

  /// Controls which user info elements the default header shows. Ignored when a
  /// custom [headerBuilder] is provided.
  final StoryHeaderConfig headerConfig;

  /// Color and text styling for the default header. When `null`, [theme]'s
  /// `headerStyle` is used. Ignored when a custom [headerBuilder] is provided.
  final StoryHeaderStyle? headerStyle;

  /// Builds a custom header overlay.
  final StoryHeaderBuilder? headerBuilder;

  /// Builds a custom footer overlay (e.g. reply bar).
  final StoryFooterBuilder? footerBuilder;

  /// Builds a custom overlay drawn over the media content.
  final StoryOverlayBuilder? overlayBuilder;

  /// Builds a custom loading placeholder.
  final StoryLoadingBuilder? loadingBuilder;

  /// Builds a custom error widget.
  final StoryErrorBuilder? errorBuilder;

  /// Called when a story becomes visible.
  final OnStoryShow? onStoryShow;

  /// Called when a single story finishes playing.
  final OnStoryComplete? onStoryComplete;

  /// Called when a user's last story completes.
  final OnAllStoriesComplete? onAllStoriesComplete;

  /// Called when the user swipes up on a story.
  final OnStorySwipeUp? onSwipeUp;

  /// Called when a story's [StoryLink] is tapped. When omitted the link is
  /// opened in the device browser.
  final OnStoryButtonTap? onStoryButtonTap;

  /// Called when the viewer is closed. When omitted, the viewer tries to pop
  /// the enclosing route.
  final OnViewerClose? onClose;

  @override
  State<StoryView> createState() => _StoryViewState();
}

class _StoryViewState extends State<StoryView> with WidgetsBindingObserver implements StoryViewControllerDelegate {
  late final PageController _pageController;
  late final StoryViewController _controller;
  bool _ownsController = false;

  StoryUserPlayback? _activePlayback;
  late int _currentUserIndex;
  // The page whose story is allowed to play. Only updated once a swipe/scroll
  // has fully settled, so the next user's story never starts mid-gesture.
  late int _settledUserIndex;
  final Map<int, int> _startIndices = <int, int>{};
  int? _pendingStoryIndex;
  bool _closed = false;

  double _dragDy = 0;

  // Theme-resolved values (explicit params win over the theme).
  StoryProgressStyle get _progressStyle => widget.progressStyle ?? widget.theme.progressStyle;
  Color get _backgroundColor => widget.backgroundColor ?? widget.theme.backgroundColor;
  StoryHeaderStyle get _headerStyle => widget.headerStyle ?? widget.theme.headerStyle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentUserIndex = widget.initialUserIndex.clamp(0, widget.users.length - 1);
    _settledUserIndex = _currentUserIndex;
    _pageController = PageController(initialPage: _currentUserIndex);

    _controller = widget.controller ?? StoryViewController();
    _ownsController = widget.controller == null;
    _controller.attach(this);

    // Resolve initial story index for the first user.
    _startIndices[_currentUserIndex] = widget.initialStoryIndex ?? widget.users[_currentUserIndex].firstUnseenIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) => _precacheNeighbors());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.detach(this);
    if (_ownsController) _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _activePlayback?.resume(StoryPauseReason.lifecycle);
    } else {
      _activePlayback?.pause(StoryPauseReason.lifecycle);
    }
  }

  int _startIndexFor(int userIndex) => _startIndices[userIndex] ?? widget.users[userIndex].firstUnseenIndex;

  // --- StoryViewControllerDelegate -----------------------------------------

  @override
  void onPause(StoryPauseReason reason) => _activePlayback?.pause(reason);

  @override
  void onResume(StoryPauseReason reason) => _activePlayback?.resume(reason);

  @override
  void onNext() => _activePlayback?.nextStory();

  @override
  void onPrevious() => _activePlayback?.previousStory();

  @override
  void onJumpTo(int userIndex, int storyIndex) {
    final clampedUser = userIndex.clamp(0, widget.users.length - 1);
    if (clampedUser == _currentUserIndex) {
      _activePlayback?.jumpToStory(storyIndex);
    } else {
      _pendingStoryIndex = storyIndex;
      _startIndices[clampedUser] = storyIndex;
      _animateToUser(clampedUser);
    }
  }

  @override
  void onClose() => _close();

  // --- Navigation between users --------------------------------------------

  void _animateToUser(int index) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOut,
    );
  }

  void _requestNextUser() {
    if (_currentUserIndex < widget.users.length - 1) {
      _startIndices[_currentUserIndex + 1] = 0;
      _animateToUser(_currentUserIndex + 1);
    } else {
      _close();
    }
  }

  void _requestPreviousUser() {
    if (_currentUserIndex > 0) {
      final previousIndex = _currentUserIndex - 1;
      // Resume the previous user from their last story instead of restarting
      // from the beginning.
      _startIndices[previousIndex] = widget.users[previousIndex].stories.length - 1;
      _animateToUser(previousIndex);
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentUserIndex = index);
    _precacheNeighbors();
  }

  /// Called once a swipe or programmatic page animation has fully settled.
  /// Only here do we promote the centered page to the active one, so the
  /// destination story starts after the transition completes rather than
  /// mid-gesture.
  void _onSettled() {
    if (_settledUserIndex != _currentUserIndex) {
      setState(() => _settledUserIndex = _currentUserIndex);
      _controller.syncPosition(_currentUserIndex, _startIndexFor(_currentUserIndex));
    } else {
      // The page snapped back to where it started; resume the current story.
      _activePlayback?.resume(StoryPauseReason.hold);
    }
    if (_pendingStoryIndex != null) {
      final pending = _pendingStoryIndex!;
      _pendingStoryIndex = null;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _activePlayback?.jumpToStory(pending),
      );
    }
  }

  void _onRegister(StoryUserPlayback playback) {
    _activePlayback = playback;
  }

  void _onUnregister(StoryUserPlayback playback) {
    if (identical(_activePlayback, playback)) _activePlayback = null;
  }

  // --- Precaching ----------------------------------------------------------

  void _precacheNeighbors() {
    if (!mounted) return;
    final candidates = <StoryUser>[
      widget.users[_currentUserIndex],
      if (_currentUserIndex + 1 < widget.users.length) widget.users[_currentUserIndex + 1],
      if (_currentUserIndex - 1 >= 0) widget.users[_currentUserIndex - 1],
    ];
    for (final user in candidates) {
      for (final story in user.stories) {
        if (story.source != StorySource.network || story.url.isEmpty) continue;
        switch (story.type) {
          case StoryMediaType.image:
            precacheImage(CachedNetworkImageProvider(story.url), context).catchError((_) {});
          case StoryMediaType.video:
            // Pre-download the video file so it plays instantly without a
            // loading spinner when the story is opened.
            StoryMediaCache.prefetch(story.url);
          case StoryMediaType.text:
            break;
        }
      }
    }
  }

  // --- Dismiss / swipe gestures --------------------------------------------

  void _onVerticalDragStart(DragStartDetails details) {
    _activePlayback?.pause(StoryPauseReason.hold);
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    final dy = _dragDy + details.delta.dy;
    setState(() => _dragDy = dy.clamp(0.0, double.infinity));
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -300) {
      // Swipe up.
      _activePlayback?.resume(StoryPauseReason.hold);
      _resetDrag();
      final user = widget.users[_currentUserIndex];
      final index = _activePlayback?.currentStoryIndex ?? 0;
      widget.onSwipeUp?.call(user, user.stories[index]);
      return;
    }
    if (widget.swipeDownToDismiss && (_dragDy > 120 || velocity > 700)) {
      _close();
      return;
    }
    _activePlayback?.resume(StoryPauseReason.hold);
    _resetDrag();
  }

  void _resetDrag() {
    if (_dragDy != 0) setState(() => _dragDy = 0);
  }

  void _close() {
    if (_closed) return;
    _closed = true;
    _activePlayback?.pause(StoryPauseReason.manual);
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollStartNotification && notification.dragDetails != null) {
      _activePlayback?.pause(StoryPauseReason.hold);
    } else if (notification is ScrollEndNotification) {
      _onSettled();
    }
    return false;
  }

  // --- Build ---------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final dismissProgress = (_dragDy / (size.height * 0.6)).clamp(0.0, 1.0);

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Stack(
          children: <Widget>[
            // Full-screen backdrop that fades out as the viewer is dragged
            // down, so the screen underneath shows through instead of black.
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: _backgroundColor.withValues(alpha: 1 - dismissProgress),
                ),
              ),
            ),
            Transform.translate(
              offset: Offset(0, _dragDy),
              child: Transform.scale(
                scale: 1 - dismissProgress * 0.1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(dismissProgress > 0 ? 16 : 0),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: _onScrollNotification,
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: widget.users.length,
                      itemBuilder: (context, index) {
                        return AnimatedBuilder(
                          animation: _pageController,
                          builder: (context, child) {
                            double page = index.toDouble();
                            if (_pageController.hasClients && _pageController.position.haveDimensions) {
                              page = _pageController.page ?? page;
                            }
                            final offset = index - page;
                            return applyStoryTransition(
                              transition: widget.transition,
                              pageOffset: offset,
                              child: child!,
                            );
                          },
                          child: StoryUserView(
                            key: ValueKey<String>(widget.users[index].id),
                            user: widget.users[index],
                            initialIndex: _startIndexFor(index),
                            isActive: index == _settledUserIndex,
                            isMuted: widget.muted,
                            progressStyle: _progressStyle,
                            imageDuration: widget.imageDuration,
                            contentFit: widget.contentFit,
                            onRegister: _onRegister,
                            onUnregister: _onUnregister,
                            onStoryShow: _handleStoryShow,
                            onStoryComplete: _handleStoryComplete,
                            onAllStoriesComplete: _handleAllStoriesComplete,
                            onRequestNextUser: _requestNextUser,
                            onRequestPreviousUser: _requestPreviousUser,
                            onPositionChanged: (storyIndex) => _controller.syncPosition(_currentUserIndex, storyIndex),
                            headerBuilder: widget.headerBuilder,
                            footerBuilder: widget.footerBuilder,
                            overlayBuilder: widget.overlayBuilder,
                            loadingBuilder: widget.loadingBuilder,
                            errorBuilder: widget.errorBuilder,
                            onClosePressed: _close,
                            headerConfig: widget.headerConfig,
                            headerStyle: _headerStyle,
                            topScrimColor: widget.theme.topScrimColor,
                            bottomScrimColor: widget.theme.bottomScrimColor,
                            onStoryButtonTap: (item, link) => _handleLinkTap(widget.users[index], item, link),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleStoryShow(StoryUser user, StoryItem item, int index) {
    widget.onStoryShow?.call(user, item, index);
  }

  void _handleStoryComplete(StoryUser user, StoryItem item, int index) {
    widget.onStoryComplete?.call(user, item, index);
  }

  void _handleAllStoriesComplete(StoryUser user) {
    widget.onAllStoriesComplete?.call(user);
  }

  void _handleLinkTap(StoryUser user, StoryItem item, StoryLink link) {
    if (widget.onStoryButtonTap != null) {
      widget.onStoryButtonTap!(user, item, link);
      return;
    }
    // Default behaviour: pause playback and open the link in the browser.
    _activePlayback?.pause(StoryPauseReason.manual);
    final uri = Uri.tryParse(link.url);
    if (uri == null) {
      _activePlayback?.resume(StoryPauseReason.manual);
      return;
    }
    launchUrl(uri, mode: LaunchMode.externalApplication).whenComplete(() {
      _activePlayback?.resume(StoryPauseReason.manual);
    });
  }
}
