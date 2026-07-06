/// The animation used when moving between two users' story groups.
enum StoryTransition {
  /// No animation; pages are swapped instantly.
  none,

  /// Horizontal slide (default page view behaviour).
  slide,

  /// The classic Instagram-style 3D cube rotation.
  cube,

  /// Cross-fade between pages.
  fade,

  /// Depth-style scale + fade.
  scale,

  /// Parallax slide with a subtle offset on the incoming page.
  zoom,
}
