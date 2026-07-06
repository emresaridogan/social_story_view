/// The kind of media a [StoryItem] represents.
enum StoryMediaType {
  /// A static image, loaded from the network, an asset or a file.
  image,

  /// A video, loaded from the network, an asset or a file.
  video,

  /// A text-only story rendered on a solid color or gradient background.
  text,
}

/// Describes where the media of a [StoryItem] is loaded from.
enum StorySource {
  /// Loaded from a remote URL (cached for images, streamed for video).
  network,

  /// Loaded from a bundled Flutter asset.
  asset,

  /// Loaded from a local file path.
  file,
}
