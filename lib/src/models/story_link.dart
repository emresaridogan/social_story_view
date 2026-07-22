import 'package:flutter/material.dart';

/// A tappable call-to-action attached to a [StoryItem].
///
/// Renders as a pill/button overlay above the story content. Tapping it opens
/// [url] in the browser (or is handled by `StoryView.OnStoryButtonTap` when provided).
@immutable
class StoryLink {
  /// Creates a story link.
  const StoryLink({
    required this.url,
    this.label = 'Learn more',
    this.icon = Icons.link,
    this.alignment = Alignment.bottomCenter,
    this.backgroundColor,
    this.foregroundColor,
    this.textStyle,
  });

  /// The destination opened when the link is tapped.
  final String url;

  /// Text shown on the button.
  final String label;

  /// Optional leading icon. Pass `null` to hide it.
  final IconData? icon;

  /// Where the button is positioned within the story area.
  final Alignment alignment;

  /// Button background color. Defaults to a translucent white.
  final Color? backgroundColor;

  /// Button text/icon color. Defaults to black.
  final Color? foregroundColor;

  /// Optional text style override for [label].
  final TextStyle? textStyle;

  /// Returns a copy with the given fields replaced.
  StoryLink copyWith({
    String? url,
    String? label,
    IconData? icon,
    Alignment? alignment,
    Color? backgroundColor,
    Color? foregroundColor,
    TextStyle? textStyle,
  }) {
    return StoryLink(
      url: url ?? this.url,
      label: label ?? this.label,
      icon: icon ?? this.icon,
      alignment: alignment ?? this.alignment,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      textStyle: textStyle ?? this.textStyle,
    );
  }

  /// Deserializes a [StoryLink] from a JSON-like map. Visual fields are not
  /// deserialized; set them in code when needed.
  factory StoryLink.fromJson(Map<String, dynamic> json) {
    return StoryLink(
      url: (json['url'] as String?) ?? '',
      label: (json['label'] as String?) ?? 'Learn more',
    );
  }

  /// Serializes this link to a JSON-like map (url and label only).
  Map<String, dynamic> toJson() => <String, dynamic>{
        'url': url,
        'label': label,
      };

  @override
  bool operator ==(Object other) => identical(this, other) || other is StoryLink && other.url == url && other.label == label;

  @override
  int get hashCode => Object.hash(url, label);

  @override
  String toString() => 'StoryLink(url: $url, label: $label)';
}
