import 'package:flutter/material.dart';

import '../models/story_callbacks.dart';
import '../models/story_progress_style.dart';
import '../models/story_transition.dart';
import '../models/story_user.dart';
import '../models/story_view_theme.dart';
import 'default_story_header.dart';
import 'story_view.dart';

import '../controllers/story_view_controller.dart';

/// Pushes a full-screen [StoryView] as a modal route and returns a future that
/// completes when the viewer is dismissed.
///
/// This is a thin convenience wrapper around [Navigator.push] + [StoryView];
/// use [StoryView] directly when you need to embed it inside your own route.
Future<void> showStoryView(
  BuildContext context, {
  required List<StoryUser> users,
  StoryViewController? controller,
  int initialUserIndex = 0,
  int? initialStoryIndex,
  StoryTransition transition = StoryTransition.cube,
  StoryProgressStyle? progressStyle,
  Duration imageDuration = const Duration(seconds: 10),
  BoxFit contentFit = BoxFit.contain,
  bool muted = false,
  Color? backgroundColor,
  StoryViewTheme theme = const StoryViewTheme(),
  bool swipeDownToDismiss = true,
  StoryHeaderConfig headerConfig = const StoryHeaderConfig(),
  StoryHeaderStyle? headerStyle,
  StoryHeaderBuilder? headerBuilder,
  StoryFooterBuilder? footerBuilder,
  StoryOverlayBuilder? overlayBuilder,
  StoryLoadingBuilder? loadingBuilder,
  StoryErrorBuilder? errorBuilder,
  OnStoryShow? onStoryShow,
  OnStoryComplete? onStoryComplete,
  OnAllStoriesComplete? onAllStoriesComplete,
  OnStorySwipeUp? onSwipeUp,
  OnStoryLinkTap? onLinkTap,
}) {
  return Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: StoryView(
            users: users,
            controller: controller,
            initialUserIndex: initialUserIndex,
            initialStoryIndex: initialStoryIndex,
            transition: transition,
            progressStyle: progressStyle,
            imageDuration: imageDuration,
            contentFit: contentFit,
            muted: muted,
            backgroundColor: backgroundColor,
            theme: theme,
            swipeDownToDismiss: swipeDownToDismiss,
            headerConfig: headerConfig,
            headerStyle: headerStyle,
            headerBuilder: headerBuilder,
            footerBuilder: footerBuilder,
            overlayBuilder: overlayBuilder,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder,
            onStoryShow: onStoryShow,
            onStoryComplete: onStoryComplete,
            onAllStoriesComplete: onAllStoriesComplete,
            onSwipeUp: onSwipeUp,
            onLinkTap: onLinkTap,
            onClose: () => Navigator.of(context).maybePop(),
          ),
        );
      },
    ),
  );
}
