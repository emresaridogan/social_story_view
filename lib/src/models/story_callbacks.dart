import 'package:flutter/material.dart';

import 'story_item.dart';
import 'story_link.dart';
import 'story_user.dart';

/// Builds a custom header overlay for the currently visible story.
///
/// Receives the active [user] and [item] plus the [index] of the story within
/// that user's list. Return any widget; it is laid out at the top of the
/// viewer above the gesture layer.
typedef StoryHeaderBuilder = Widget Function(
  BuildContext context,
  StoryUser user,
  StoryItem item,
  int index,
);

/// Builds a custom footer overlay (e.g. reply input, reactions).
typedef StoryFooterBuilder = Widget Function(
  BuildContext context,
  StoryUser user,
  StoryItem item,
  int index,
);

/// Builds a custom overlay drawn on top of the story media.
///
/// Unlike [StoryHeaderBuilder] / [StoryFooterBuilder] this is laid out over
/// the entire content area (between the media and the header/footer), making
/// it ideal for captions, titles or marketing copy placed directly on an
/// image or video. Wrap interactive children in their own gesture detectors;
/// otherwise taps pass through to the viewer's navigation layer.
typedef StoryOverlayBuilder = Widget Function(
  BuildContext context,
  StoryUser user,
  StoryItem item,
  int index,
);

/// Builds the loading placeholder shown while media is being fetched.
typedef StoryLoadingBuilder = Widget Function(
  BuildContext context,
  StoryUser user,
  StoryItem item,
);

/// Builds the error widget shown when media fails to load.
typedef StoryErrorBuilder = Widget Function(
  BuildContext context,
  StoryUser user,
  StoryItem item,
  Object error,
);

/// Called when a story becomes visible on screen.
typedef OnStoryShow = void Function(StoryUser user, StoryItem item, int index);

/// Called when a single story finishes playing to completion.
typedef OnStoryComplete = void Function(
  StoryUser user,
  StoryItem item,
  int index,
);

/// Called when all stories of a user have been viewed.
typedef OnAllStoriesComplete = void Function(StoryUser user);

/// Called when the viewer is fully closed.
typedef OnViewerClose = void Function();

/// Called when the user submits a text reply via the footer.
typedef OnStoryReply = void Function(
  StoryUser user,
  StoryItem item,
  String replyText,
);

/// Called when the user swipes up on a story (e.g. "see more").
typedef OnStorySwipeUp = void Function(StoryUser user, StoryItem item);

/// Called when the user taps a story's [StoryLink] call-to-action.
///
/// Return `true` if you handled the tap yourself; return `false` (or use the
/// default handler) to let the viewer open the link in the browser.
typedef OnStoryLinkTap = void Function(
  StoryUser user,
  StoryItem item,
  StoryLink link,
);
