import 'package:flutter/foundation.dart';

import 'story_item.dart';

/// A user (or "status owner") that groups a list of [StoryItem]s.
@immutable
class StoryUser {
  /// Creates a story user.
  const StoryUser({
    required this.id,
    required this.username,
    this.avatarUrl = '',
    this.stories = const <StoryItem>[],
    this.isCurrentUser = false,
    this.metadata,
  });

  /// Unique identifier of the user.
  final String id;

  /// Display name shown in the header and avatar bar.
  final String username;

  /// Avatar image URL shown in the avatar bar and viewer header.
  final String avatarUrl;

  /// The ordered stories belonging to this user.
  final List<StoryItem> stories;

  /// Whether this entry represents the current/local user ("Your story").
  final bool isCurrentUser;

  /// Free-form metadata for application use; never read by the package.
  final Map<String, Object?>? metadata;

  /// `true` when every story of this user has been viewed.
  bool get isFullyViewed =>
      stories.isNotEmpty && stories.every((s) => s.isViewed);

  /// `true` when the user has at least one unseen story.
  bool get hasUnseen => stories.any((s) => !s.isViewed);

  /// Index of the first unseen story, or `0` when all are seen.
  int get firstUnseenIndex {
    final index = stories.indexWhere((s) => !s.isViewed);
    return index == -1 ? 0 : index;
  }

  /// Returns a copy of this user with the given fields replaced.
  StoryUser copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    List<StoryItem>? stories,
    bool? isCurrentUser,
    Map<String, Object?>? metadata,
  }) {
    return StoryUser(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      stories: stories ?? this.stories,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Marks the story at [index] as viewed and returns an updated user.
  StoryUser markStoryViewed(int index) {
    if (index < 0 || index >= stories.length) return this;
    if (stories[index].isViewed) return this;
    final updated = List<StoryItem>.of(stories);
    updated[index] = updated[index].copyWith(isViewed: true);
    return copyWith(stories: updated);
  }

  /// Deserializes a [StoryUser] from a JSON-like map.
  factory StoryUser.fromJson(Map<String, dynamic> json) {
    return StoryUser(
      id: json['id'] as String,
      username: (json['username'] as String?) ?? '',
      avatarUrl: (json['avatarUrl'] as String?) ?? '',
      stories: ((json['stories'] as List?) ?? const [])
          .map((e) => StoryItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(growable: false),
      isCurrentUser: (json['isCurrentUser'] as bool?) ?? false,
      metadata: (json['metadata'] as Map?)?.cast<String, Object?>(),
    );
  }

  /// Serializes this user to a JSON-like map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'avatarUrl': avatarUrl,
      'stories': stories.map((e) => e.toJson()).toList(growable: false),
      'isCurrentUser': isCurrentUser,
      'metadata': metadata,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryUser &&
          other.id == id &&
          other.username == username &&
          other.avatarUrl == avatarUrl &&
          listEquals(other.stories, stories);

  @override
  int get hashCode =>
      Object.hash(id, username, avatarUrl, Object.hashAll(stories));

  @override
  String toString() =>
      'StoryUser(id: $id, username: $username, stories: ${stories.length})';
}
