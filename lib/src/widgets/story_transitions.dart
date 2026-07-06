import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/story_transition.dart';

/// Applies the configured [StoryTransition] to a page in the viewer's
/// [PageView], based on its [pageOffset] relative to the centered page.
///
/// [pageOffset] is `0` when the page is centered, negative when it is to the
/// leading side and positive when it is to the trailing side.
Widget applyStoryTransition({
  required StoryTransition transition,
  required double pageOffset,
  required Widget child,
}) {
  switch (transition) {
    case StoryTransition.none:
    case StoryTransition.slide:
      return child;

    case StoryTransition.fade:
      final opacity = (1 - pageOffset.abs()).clamp(0.0, 1.0);
      return Opacity(opacity: opacity, child: child);

    case StoryTransition.scale:
      final scale = (1 - pageOffset.abs() * 0.25).clamp(0.0, 1.0);
      final opacity = (1 - pageOffset.abs()).clamp(0.0, 1.0);
      return Opacity(
        opacity: opacity,
        child: Transform.scale(scale: scale, child: child),
      );

    case StoryTransition.zoom:
      final dx = -pageOffset * 60;
      final scale = (1 - pageOffset.abs() * 0.1).clamp(0.0, 1.0);
      return Transform.translate(
        offset: Offset(dx, 0),
        child: Transform.scale(scale: scale, child: child),
      );

    case StoryTransition.cube:
      // Convex cube: the centered page is the front face and the neighbour
      // rotates in like the right/left face of a real cube. The shared edge
      // stays closest to the viewer, so the leaving page hinges on its right
      // edge and the incoming page hinges on its left edge.
      final offset = pageOffset.clamp(-1.0, 1.0);
      final isLeaving = offset <= 0;
      final angle = offset.abs() * (math.pi / 2);
      final alignment =
          isLeaving ? Alignment.centerRight : Alignment.centerLeft;
      // Darken the face as it rotates away to enhance the 3D depth.
      final shade = (offset.abs() * 0.55).clamp(0.0, 0.55);
      return Transform(
        alignment: alignment,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.0015)
          ..rotateY(isLeaving ? angle : -angle),
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: ColoredBox(
                  color: Color.fromRGBO(0, 0, 0, shade),
                ),
              ),
            ),
          ],
        ),
      );
  }
}
