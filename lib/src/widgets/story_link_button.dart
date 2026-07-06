import 'package:flutter/material.dart';

import '../models/story_link.dart';

/// Renders a [StoryLink] as a tappable pill button over the story content.
class StoryLinkButton extends StatelessWidget {
  /// Creates a story link button.
  const StoryLinkButton({
    super.key,
    required this.link,
    required this.onTap,
  });

  /// The link to display.
  final StoryLink link;

  /// Called when the button is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background =
        link.backgroundColor ?? Colors.white.withValues(alpha: 0.92);
    final foreground = link.foregroundColor ?? Colors.black87;
    final textStyle = link.textStyle ??
        TextStyle(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        );

    return Align(
      alignment: link.alignment,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Material(
          color: background,
          borderRadius: BorderRadius.circular(24),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  if (link.icon != null) ...<Widget>[
                    Icon(link.icon, size: 18, color: foreground),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      link.label,
                      style: textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
