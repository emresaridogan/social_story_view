import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/story_user.dart';

/// Visual styling for [StoryAvatar] / [StoryAvatarBar].
@immutable
class StoryAvatarStyle {
  /// Creates an avatar style.
  const StoryAvatarStyle({
    this.radius = 32,
    this.ringThickness = 2.5,
    this.ringGap = 3,
    this.unseenGradient = const LinearGradient(
      colors: <Color>[
        Color(0xFFFEDA75),
        Color(0xFFFA7E1E),
        Color(0xFFD62976),
        Color(0xFF962FBF)
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.seenColor = const Color(0xFFBDBDBD),
    this.backgroundColor = Colors.white,
    this.labelStyle = const TextStyle(fontSize: 12),
    this.spacing = 12,
    this.showLabel = true,
    this.currentUserLabel = 'Your story',
  });

  /// Radius of the avatar image.
  final double radius;

  /// Thickness of the status ring.
  final double ringThickness;

  /// Gap between the ring and the avatar image.
  final double ringGap;

  /// Gradient used for users with unseen stories.
  final Gradient unseenGradient;

  /// Color used for the ring when all stories are seen.
  final Color seenColor;

  /// Background color behind the avatar (the gap fill).
  final Color backgroundColor;

  /// Text style for the username label.
  final TextStyle labelStyle;

  /// Horizontal spacing between avatars in the bar.
  final double spacing;

  /// Whether to show the username label under the avatar.
  final bool showLabel;

  /// Label shown under the current user's avatar (the "Your story" entry).
  final String currentUserLabel;
}

/// A single avatar with an Instagram-style status ring.
class StoryAvatar extends StatelessWidget {
  /// Creates a story avatar.
  const StoryAvatar({
    super.key,
    required this.user,
    this.onTap,
    this.onAddTap,
    this.style = const StoryAvatarStyle(),
    this.showAddBadge = true,
  });

  /// The user this avatar represents.
  final StoryUser user;

  /// Called when the avatar is tapped.
  final VoidCallback? onTap;

  /// Called when the "add" badge of the current user is tapped.
  final VoidCallback? onAddTap;

  /// Visual styling.
  final StoryAvatarStyle style;

  /// Whether the "add" badge is shown on the current user's avatar.
  final bool showAddBadge;

  @override
  Widget build(BuildContext context) {
    final ringSize = (style.radius + style.ringThickness + style.ringGap) * 2;
    final hasUnseen = user.hasUnseen;
    final showRing = user.stories.isNotEmpty;

    Widget avatar = Container(
      width: ringSize,
      height: ringSize,
      padding: EdgeInsets.all(style.ringThickness + style.ringGap),
      decoration: showRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              gradient: hasUnseen ? style.unseenGradient : null,
              color: hasUnseen ? null : style.seenColor,
            )
          : null,
      child: Container(
        padding: EdgeInsets.all(showRing ? style.ringGap : 0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: style.backgroundColor,
        ),
        child: CircleAvatar(
          radius: style.radius,
          backgroundColor: Colors.grey.shade300,
          backgroundImage: user.avatarUrl.isEmpty
              ? null
              : CachedNetworkImageProvider(user.avatarUrl),
          child: user.avatarUrl.isEmpty
              ? Text(
                  user.username.isNotEmpty
                      ? user.username.characters.first.toUpperCase()
                      : '?',
                )
              : null,
        ),
      ),
    );

    if (user.isCurrentUser && showAddBadge) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          avatar,
          PositionedDirectional(
            bottom: style.showLabel ? 0 : -2,
            end: 0,
            child: GestureDetector(
              onTap: onAddTap ?? onTap,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
                  border: Border.all(color: style.backgroundColor, width: 2),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          avatar,
          if (style.showLabel) ...<Widget>[
            const SizedBox(height: 4),
            SizedBox(
              width: ringSize,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                child: Text(
                  user.isCurrentUser ? style.currentUserLabel : user.username,
                  style: style.labelStyle.copyWith(
                    color: style.labelStyle.color ?? Colors.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A horizontally scrollable bar of [StoryAvatar]s, like the row at the top of
/// an Instagram or WhatsApp feed.
class StoryAvatarBar extends StatelessWidget {
  /// Creates a story avatar bar.
  const StoryAvatarBar({
    super.key,
    required this.users,
    required this.onAvatarTap,
    this.onAddTap,
    this.style = const StoryAvatarStyle(),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    this.height,
    this.scrollController,
    this.showCurrentUser = true,
    this.showAddBadge = true,
  });

  /// The users to show.
  final List<StoryUser> users;

  /// Called with the tapped user and its index.
  final void Function(StoryUser user, int index) onAvatarTap;

  /// Called when the current user's "add" badge is tapped.
  final VoidCallback? onAddTap;

  /// Visual styling for each avatar.
  final StoryAvatarStyle style;

  /// Padding around the bar.
  final EdgeInsets padding;

  /// Optional fixed height; computed from [style] when omitted.
  final double? height;

  /// Optional scroll controller for the horizontal list.
  final ScrollController? scrollController;

  /// Whether the current user's ("Your story") avatar is shown in the bar.
  /// When `false` any user with [StoryUser.isCurrentUser] set is omitted.
  final bool showCurrentUser;

  /// Whether the "add" badge is shown on the current user's avatar.
  final bool showAddBadge;

  @override
  Widget build(BuildContext context) {
    final ringSize = (style.radius + style.ringThickness + style.ringGap) * 2;
    final computedHeight =
        (height ?? ringSize + (style.showLabel ? 32 : 0)) + padding.vertical;

    final visibleUsers = showCurrentUser
        ? users
        : users.where((u) => !u.isCurrentUser).toList(growable: false);

    return SizedBox(
      height: computedHeight,
      child: ListView.separated(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: visibleUsers.length,
        separatorBuilder: (_, __) => SizedBox(width: style.spacing),
        itemBuilder: (context, index) {
          final user = visibleUsers[index];
          return StoryAvatar(
            user: user,
            style: style,
            showAddBadge: showAddBadge,
            onTap: () => onAvatarTap(user, users.indexOf(user)),
            onAddTap: user.isCurrentUser ? onAddTap : null,
          );
        },
      ),
    );
  }
}
