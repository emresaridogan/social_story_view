import 'package:video_player/video_player.dart';

/// A small LRU pool of already-initialized [VideoPlayerController]s, keyed by
/// the media URL.
///
/// Reopening a story reuses its initialized controller instead of creating and
/// initializing a new one, so no loading spinner is shown on the second (and
/// later) open. Controllers are only disposed when evicted from the pool.
class StoryVideoControllerPool {
  StoryVideoControllerPool._();

  /// Maximum number of initialized controllers kept alive at once.
  static int maxControllers = 4;

  // Insertion-ordered so the first key is the least-recently released.
  static final Map<String, VideoPlayerController> _cache =
      <String, VideoPlayerController>{};

  /// Removes and returns a cached controller for [key], or `null` when none is
  /// available. The caller takes ownership until it calls [release].
  static VideoPlayerController? acquire(String key) {
    if (key.isEmpty) return null;
    return _cache.remove(key);
  }

  /// Returns [controller] to the pool for future reuse, paused and rewound.
  ///
  /// The controller must have no listeners attached. When the pool is full the
  /// least-recently used controller is evicted and disposed.
  static void release(String key, VideoPlayerController controller) {
    if (key.isEmpty) {
      controller.dispose();
      return;
    }
    // A controller is never displayed while cached, so a duplicate key means a
    // separate instance for the same URL; dispose the extra one.
    if (_cache.containsKey(key)) {
      controller.dispose();
      return;
    }
    controller.pause();
    controller.seekTo(Duration.zero);
    _cache[key] = controller;
    while (_cache.length > maxControllers) {
      final oldestKey = _cache.keys.first;
      _cache.remove(oldestKey)?.dispose();
    }
  }

  /// Disposes every cached controller and empties the pool.
  static void clear() {
    for (final controller in _cache.values) {
      controller.dispose();
    }
    _cache.clear();
  }
}
