import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/story_progress_style.dart';

/// A segmented progress indicator drawn across the top of the story viewer.
///
/// One segment is rendered per story. Segments before [currentIndex] are
/// full, segments after it are empty, and the segment at [currentIndex] is
/// driven by [progress] (a value between `0.0` and `1.0`).
class StoryProgressBar extends StatelessWidget {
  /// Creates a segmented progress bar.
  const StoryProgressBar({
    super.key,
    required this.itemCount,
    required this.currentIndex,
    required this.progress,
    this.style = const StoryProgressStyle(),
  });

  /// Total number of segments (stories) for the current user.
  final int itemCount;

  /// Index of the currently playing segment.
  final int currentIndex;

  /// Live progress (`0.0`–`1.0`) of the segment at [currentIndex].
  final ValueListenable<double> progress;

  /// Visual styling for the bar.
  final StoryProgressStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: style.padding,
      child: Row(
        children: List<Widget>.generate(itemCount, (index) {
          double value;
          if (index < currentIndex) {
            value = 1.0;
          } else if (index > currentIndex) {
            value = 0.0;
          } else {
            value = -1.0; // sentinel: use the live listenable
          }
          return Expanded(
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                end: index == itemCount - 1 ? 0 : style.spacing,
              ),
              child: value == -1.0
                  ? ValueListenableBuilder<double>(
                      valueListenable: progress,
                      builder: (context, p, _) => _Segment(
                        value: p.clamp(0.0, 1.0),
                        style: style,
                      ),
                    )
                  : _Segment(value: value, style: style),
            ),
          );
        }),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.value, required this.style});

  final double value;
  final StoryProgressStyle style;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: style.borderRadius,
      child: SizedBox(
        height: style.height,
        child: Stack(
          children: <Widget>[
            DecoratedBox(
              decoration: BoxDecoration(color: style.backgroundColor),
              child: const SizedBox.expand(),
            ),
            FractionallySizedBox(
              alignment: AlignmentDirectional.centerStart,
              widthFactor: value,
              child: DecoratedBox(
                decoration: BoxDecoration(color: style.color),
                child: const SizedBox.expand(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
