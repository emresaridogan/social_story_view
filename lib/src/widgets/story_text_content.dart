import 'package:flutter/material.dart';

import '../models/story_item.dart';

/// Renders a text-only [StoryItem] on a solid color or gradient background.
class StoryTextContent extends StatelessWidget {
  /// Creates a text content widget.
  const StoryTextContent({super.key, required this.item});

  /// The text story to render.
  final StoryItem item;

  @override
  Widget build(BuildContext context) {
    final gradient = item.gradient;
    final background = item.backgroundColor ?? Colors.black;
    final textStyle = item.textStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          height: 1.3,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? background : null,
        gradient: gradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Center(
            child: Text(
              item.text ?? '',
              textAlign: TextAlign.center,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}
