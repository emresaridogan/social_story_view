import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/story_item.dart';
import '../models/story_user.dart';

/// Controls which elements the [DefaultStoryHeader] displays.
@immutable
class StoryHeaderConfig {
  /// Creates a header configuration.
  const StoryHeaderConfig({
    this.showUserInfo = true,
    this.showAvatar = true,
    this.showUsername = true,
    this.showTimestamp = true,
    this.showCloseButton = true,
  });

  /// Whether the user info block is shown (avatar + username + timestamp).
  ///
  /// When `false`, [showAvatar], [showUsername] and [showTimestamp] are
  /// ignored.
  final bool showUserInfo;

  /// Whether the user's avatar is shown.
  final bool showAvatar;

  /// Whether the user's name is shown.
  final bool showUsername;

  /// Whether the relative timestamp is shown.
  final bool showTimestamp;

  /// Whether the close button is shown.
  final bool showCloseButton;
}

/// Color and text styling for the [DefaultStoryHeader].
///
/// The defaults match a dark theme (white text/icons readable over the dark
/// top scrim). Use [StoryHeaderStyle.light] for a light theme, or [copyWith]
/// to tweak individual values from an external parameter.
@immutable
class StoryHeaderStyle {
  /// Creates a header style. Defaults are tuned for a dark theme.
  const StoryHeaderStyle({
    this.usernameColor = Colors.white,
    this.timestampColor = Colors.white70,
    this.iconColor = Colors.white,
    this.avatarBackgroundColor = Colors.white24,
    this.avatarTextColor = Colors.white,
    this.textShadow = const Shadow(blurRadius: 4, color: Colors.black54),
    this.usernameFontSize = 15,
    this.timestampFontSize = 12,
  });

  /// A light-theme preset: dark text/icons for use over a light scrim.
  const StoryHeaderStyle.light()
      : usernameColor = const Color(0xFF1A1A1A),
        timestampColor = const Color(0xFF5C5C5C),
        iconColor = const Color(0xFF1A1A1A),
        avatarBackgroundColor = const Color(0x1F000000),
        avatarTextColor = const Color(0xFF1A1A1A),
        textShadow = const Shadow(blurRadius: 4, color: Color(0x40FFFFFF)),
        usernameFontSize = 15,
        timestampFontSize = 12;

  /// Color of the username text.
  final Color usernameColor;

  /// Color of the relative timestamp text.
  final Color timestampColor;

  /// Color of the close button icon (and avatar placeholder glyph).
  final Color iconColor;

  /// Background color of the avatar placeholder.
  final Color avatarBackgroundColor;

  /// Text color of the avatar placeholder initial.
  final Color avatarTextColor;

  /// Shadow applied to the username/timestamp for readability over media.
  /// Set to `null` to remove it.
  final Shadow? textShadow;

  /// Font size of the username.
  final double usernameFontSize;

  /// Font size of the timestamp.
  final double timestampFontSize;

  /// Returns a copy with the given fields replaced.
  StoryHeaderStyle copyWith({
    Color? usernameColor,
    Color? timestampColor,
    Color? iconColor,
    Color? avatarBackgroundColor,
    Color? avatarTextColor,
    Shadow? textShadow,
    double? usernameFontSize,
    double? timestampFontSize,
  }) {
    return StoryHeaderStyle(
      usernameColor: usernameColor ?? this.usernameColor,
      timestampColor: timestampColor ?? this.timestampColor,
      iconColor: iconColor ?? this.iconColor,
      avatarBackgroundColor:
          avatarBackgroundColor ?? this.avatarBackgroundColor,
      avatarTextColor: avatarTextColor ?? this.avatarTextColor,
      textShadow: textShadow ?? this.textShadow,
      usernameFontSize: usernameFontSize ?? this.usernameFontSize,
      timestampFontSize: timestampFontSize ?? this.timestampFontSize,
    );
  }
}

/// The default header shown above the story content: avatar, username, a
/// relative timestamp and a close button.
///
/// Replace it entirely via [StoryView.headerBuilder] when you need a custom
/// look.
class DefaultStoryHeader extends StatelessWidget {
  /// Creates the default header.
  const DefaultStoryHeader({
    super.key,
    required this.user,
    required this.item,
    this.onClose,
    this.style = const StoryHeaderStyle(),
    this.showAvatar = true,
    this.showUsername = true,
    this.showTimestamp = true,
    this.showCloseButton = true,
  });

  /// The user that owns the visible story.
  final StoryUser user;

  /// The currently visible story.
  final StoryItem item;

  /// Called when the close button is tapped.
  final VoidCallback? onClose;

  /// Color and text styling for the header.
  final StoryHeaderStyle style;

  /// Whether the user's avatar is shown.
  final bool showAvatar;

  /// Whether the user's name is shown.
  final bool showUsername;

  /// Whether the relative timestamp is shown.
  final bool showTimestamp;

  /// Whether the close button is shown.
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final hasText = showUsername || showTimestamp;
    final shadows = style.textShadow == null
        ? const <Shadow>[]
        : <Shadow>[style.textShadow!];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 24),
      child: Row(
        children: <Widget>[
          if (showAvatar) ...<Widget>[
            CircleAvatar(
              radius: 18,
              backgroundColor: style.avatarBackgroundColor,
              backgroundImage: user.avatarUrl.isEmpty
                  ? null
                  : CachedNetworkImageProvider(user.avatarUrl),
              child: user.avatarUrl.isEmpty
                  ? Text(
                      user.username.isNotEmpty
                          ? user.username.characters.first.toUpperCase()
                          : '?',
                      style: TextStyle(color: style.avatarTextColor),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
          ],
          if (hasText)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (showUsername)
                    Text(
                      user.username,
                      style: TextStyle(
                        color: style.usernameColor,
                        fontWeight: FontWeight.w600,
                        fontSize: style.usernameFontSize,
                        shadows: shadows,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (showTimestamp)
                    Text(
                      _formatTimeAgo(item.createdAt),
                      style: TextStyle(
                        color: style.timestampColor,
                        fontSize: style.timestampFontSize,
                        shadows: shadows,
                      ),
                    ),
                ],
              ),
            )
          else
            const Spacer(),
          if (showCloseButton)
            IconButton(
              onPressed: onClose,
              icon: Icon(Icons.close, color: style.iconColor),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime time) {
    if (time.millisecondsSinceEpoch == 0) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
