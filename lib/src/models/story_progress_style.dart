import 'package:flutter/material.dart';

/// Visual configuration for the segmented progress bar shown at the top of the
/// story viewer.
@immutable
class StoryProgressStyle {
  /// Creates a progress bar style.
  const StoryProgressStyle({
    this.color = Colors.white,
    this.backgroundColor = const Color(0x55FFFFFF),
    this.height = 2.5,
    this.spacing = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  });

  /// A light-theme preset: dark fill over a translucent dark track.
  const StoryProgressStyle.light()
      : color = const Color(0xFF1A1A1A),
        backgroundColor = const Color(0x33000000),
        height = 2.5,
        spacing = 4.0,
        borderRadius = const BorderRadius.all(Radius.circular(8)),
        padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 8);

  /// Color of the filled (elapsed) portion.
  final Color color;

  /// Color of the unfilled (remaining) track.
  final Color backgroundColor;

  /// Height/thickness of each segment.
  final double height;

  /// Horizontal gap between segments.
  final double spacing;

  /// Corner radius applied to each segment.
  final BorderRadius borderRadius;

  /// Padding around the whole progress bar.
  final EdgeInsets padding;

  /// Returns a copy with the given fields replaced.
  StoryProgressStyle copyWith({
    Color? color,
    Color? backgroundColor,
    double? height,
    double? spacing,
    BorderRadius? borderRadius,
    EdgeInsets? padding,
  }) {
    return StoryProgressStyle(
      color: color ?? this.color,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      height: height ?? this.height,
      spacing: spacing ?? this.spacing,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
    );
  }
}
