import 'package:flutter/material.dart';

import '../widgets/default_story_header.dart';
import '../widgets/story_avatar_bar.dart';
import '../widgets/story_reply_bar.dart';
import 'story_progress_style.dart';

/// A single, coordinated theme for the whole story experience.
///
/// Bundles every sub-style ([progressStyle], [headerStyle], [replyBarStyle],
/// [avatarStyle]) plus the surrounding colors (background and the top/bottom
/// readability scrims) into one object so the entire viewer can be switched
/// between light and dark with a single value.
///
/// Use the [StoryViewTheme.dark] (default) or [StoryViewTheme.light] presets
/// and tweak any field from outside via [copyWith]:
///
/// ```dart
/// StoryView(
///   users: users,
///   theme: StoryViewTheme.light().copyWith(
///     backgroundColor: Colors.grey.shade100,
///   ),
/// );
/// ```
@immutable
class StoryViewTheme {
  /// Creates a theme. Individual fields default to their dark-theme values.
  const StoryViewTheme({
    this.brightness = Brightness.dark,
    this.backgroundColor = Colors.black,
    this.progressStyle = const StoryProgressStyle(),
    this.headerStyle = const StoryHeaderStyle(),
    this.replyBarStyle = const StoryReplyBarStyle(),
    this.avatarStyle = const StoryAvatarStyle(),
    this.topScrimColor = const Color(0x73000000),
    this.bottomScrimColor = const Color(0x8C000000),
  });

  /// The built-in dark theme (white controls over a black background).
  factory StoryViewTheme.dark() => const StoryViewTheme();

  /// The built-in light theme (dark controls over a light background).
  factory StoryViewTheme.light() => const StoryViewTheme(
        brightness: Brightness.light,
        backgroundColor: Color(0xFFF5F5F5),
        progressStyle: StoryProgressStyle.light(),
        headerStyle: StoryHeaderStyle.light(),
        replyBarStyle: StoryReplyBarStyle.light(),
        avatarStyle: StoryAvatarStyle(seenColor: Color(0xFFBDBDBD)),
        topScrimColor: Color(0x40FFFFFF),
        bottomScrimColor: Color(0x59FFFFFF),
      );

  /// Overall brightness of the theme. Informational; lets consumers branch on
  /// [Brightness] when building their own overlays.
  final Brightness brightness;

  /// Color behind the media (the letterbox area).
  final Color backgroundColor;

  /// Styling for the segmented progress bar.
  final StoryProgressStyle progressStyle;

  /// Color and text styling for the default header.
  final StoryHeaderStyle headerStyle;

  /// Styling for the default reply bar.
  final StoryReplyBarStyle replyBarStyle;

  /// Styling for the avatar bar / avatars.
  final StoryAvatarStyle avatarStyle;

  /// Top gradient scrim color used behind the progress bar and header for
  /// readability over bright media. Fades to transparent downward.
  final Color topScrimColor;

  /// Bottom gradient scrim color used behind the footer / link button for
  /// readability over bright media. Fades to transparent upward.
  final Color bottomScrimColor;

  /// Returns a copy with the given fields replaced.
  StoryViewTheme copyWith({
    Brightness? brightness,
    Color? backgroundColor,
    StoryProgressStyle? progressStyle,
    StoryHeaderStyle? headerStyle,
    StoryReplyBarStyle? replyBarStyle,
    StoryAvatarStyle? avatarStyle,
    Color? topScrimColor,
    Color? bottomScrimColor,
  }) {
    return StoryViewTheme(
      brightness: brightness ?? this.brightness,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      progressStyle: progressStyle ?? this.progressStyle,
      headerStyle: headerStyle ?? this.headerStyle,
      replyBarStyle: replyBarStyle ?? this.replyBarStyle,
      avatarStyle: avatarStyle ?? this.avatarStyle,
      topScrimColor: topScrimColor ?? this.topScrimColor,
      bottomScrimColor: bottomScrimColor ?? this.bottomScrimColor,
    );
  }
}
