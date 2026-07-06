import 'package:flutter/material.dart';

import 'story_link.dart';
import 'story_media_type.dart';

/// Default display duration for image and text stories.
const Duration kDefaultStoryDuration = Duration(seconds: 10);

/// A single story segment belonging to a [StoryUser].
///
/// A [StoryItem] is immutable except for its [isViewed] flag, which the
/// viewer updates as the user progresses through the stories. Use
/// [copyWith] when you need a modified copy.
@immutable
class StoryItem {
  /// Creates a story item.
  ///
  /// For [StoryMediaType.image] and [StoryMediaType.video] the [url] points
  /// to the media (network URL, asset path or file path depending on
  /// [source]). For [StoryMediaType.text] the [url] is ignored and [text]
  /// is rendered instead.
  const StoryItem({
    required this.id,
    required this.type,
    this.url = '',
    this.source = StorySource.network,
    this.duration,
    this.text,
    this.backgroundColor,
    this.gradient,
    this.textStyle,
    DateTime? createdAt,
    this.isViewed = false,
    this.headerData,
    this.metadata,
    this.link,
  }) : _createdAt = createdAt;

  /// Convenience constructor for an image story.
  factory StoryItem.image({
    required String id,
    required String url,
    StorySource source = StorySource.network,
    Duration duration = kDefaultStoryDuration,
    DateTime? createdAt,
    bool isViewed = false,
    Object? headerData,
    Map<String, Object?>? metadata,
    StoryLink? link,
  }) {
    return StoryItem(
      id: id,
      type: StoryMediaType.image,
      url: url,
      source: source,
      duration: duration,
      createdAt: createdAt,
      isViewed: isViewed,
      headerData: headerData,
      metadata: metadata,
      link: link,
    );
  }

  /// Convenience constructor for a video story.
  ///
  /// The display [duration] is optional; when omitted the viewer derives it
  /// from the actual video length once the controller is initialized.
  factory StoryItem.video({
    required String id,
    required String url,
    StorySource source = StorySource.network,
    Duration? duration,
    DateTime? createdAt,
    bool isViewed = false,
    Object? headerData,
    Map<String, Object?>? metadata,
    StoryLink? link,
  }) {
    return StoryItem(
      id: id,
      type: StoryMediaType.video,
      url: url,
      source: source,
      duration: duration,
      createdAt: createdAt,
      isViewed: isViewed,
      headerData: headerData,
      metadata: metadata,
      link: link,
    );
  }

  /// Convenience constructor for a text story.
  factory StoryItem.text({
    required String id,
    required String text,
    Color? backgroundColor,
    Gradient? gradient,
    TextStyle? textStyle,
    Duration duration = kDefaultStoryDuration,
    DateTime? createdAt,
    bool isViewed = false,
    Object? headerData,
    Map<String, Object?>? metadata,
    StoryLink? link,
  }) {
    return StoryItem(
      id: id,
      type: StoryMediaType.text,
      text: text,
      backgroundColor: backgroundColor,
      gradient: gradient,
      textStyle: textStyle,
      duration: duration,
      createdAt: createdAt,
      isViewed: isViewed,
      headerData: headerData,
      metadata: metadata,
      link: link,
    );
  }

  /// Unique identifier of this story item.
  final String id;

  /// The media type of this story.
  final StoryMediaType type;

  /// Location of the media. Empty for [StoryMediaType.text].
  final String url;

  /// Where [url] should be resolved from.
  final StorySource source;

  /// Display duration. For videos this may be `null` and resolved at runtime.
  final Duration? duration;

  /// Text content for [StoryMediaType.text] stories.
  final String? text;

  /// Background color for text stories (ignored when [gradient] is set).
  final Color? backgroundColor;

  /// Background gradient for text stories.
  final Gradient? gradient;

  /// Text style for text stories.
  final TextStyle? textStyle;

  final DateTime? _createdAt;

  /// When this story was created. Defaults to the epoch if not provided.
  DateTime get createdAt =>
      _createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether this story has already been seen by the current user.
  final bool isViewed;

  /// Arbitrary per-story data forwarded to header builders (e.g. caption).
  final Object? headerData;

  /// Free-form metadata for application use; never read by the package.
  final Map<String, Object?>? metadata;

  /// Optional tappable call-to-action link shown over the story.
  final StoryLink? link;

  /// Effective duration, falling back to [kDefaultStoryDuration] for non-video
  /// stories when none was provided.
  Duration get effectiveDuration {
    if (duration != null) return duration!;
    return type == StoryMediaType.video ? Duration.zero : kDefaultStoryDuration;
  }

  /// Returns a copy of this item with the given fields replaced.
  StoryItem copyWith({
    String? id,
    StoryMediaType? type,
    String? url,
    StorySource? source,
    Duration? duration,
    String? text,
    Color? backgroundColor,
    Gradient? gradient,
    TextStyle? textStyle,
    DateTime? createdAt,
    bool? isViewed,
    Object? headerData,
    Map<String, Object?>? metadata,
    StoryLink? link,
  }) {
    return StoryItem(
      id: id ?? this.id,
      type: type ?? this.type,
      url: url ?? this.url,
      source: source ?? this.source,
      duration: duration ?? this.duration,
      text: text ?? this.text,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradient: gradient ?? this.gradient,
      textStyle: textStyle ?? this.textStyle,
      createdAt: createdAt ?? _createdAt,
      isViewed: isViewed ?? this.isViewed,
      headerData: headerData ?? this.headerData,
      metadata: metadata ?? this.metadata,
      link: link ?? this.link,
    );
  }

  /// Deserializes a [StoryItem] from a JSON-like map.
  ///
  /// Color and gradient fields are not deserialized; provide them in code if
  /// needed for text stories.
  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'] as String,
      type: StoryMediaType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => StoryMediaType.image,
      ),
      url: (json['url'] as String?) ?? '',
      source: StorySource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => StorySource.network,
      ),
      duration: json['durationMs'] != null
          ? Duration(milliseconds: (json['durationMs'] as num).toInt())
          : null,
      text: json['text'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      isViewed: (json['isViewed'] as bool?) ?? false,
      metadata: (json['metadata'] as Map?)?.cast<String, Object?>(),
      link: json['link'] != null
          ? StoryLink.fromJson((json['link'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  /// Serializes this item to a JSON-like map.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'type': type.name,
      'url': url,
      'source': source.name,
      'durationMs': duration?.inMilliseconds,
      'text': text,
      'createdAt': _createdAt?.toIso8601String(),
      'isViewed': isViewed,
      'metadata': metadata,
      'link': link?.toJson(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoryItem &&
          other.id == id &&
          other.type == type &&
          other.url == url &&
          other.isViewed == isViewed;

  @override
  int get hashCode => Object.hash(id, type, url, isViewed);

  @override
  String toString() =>
      'StoryItem(id: $id, type: ${type.name}, isViewed: $isViewed)';
}
