import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Shared on-disk cache for story media (videos in particular).
///
/// Network videos are downloaded once and then replayed from the local file,
/// so reopening a story no longer shows a loading spinner. Images are cached
/// separately by `cached_network_image`.
class StoryMediaCache {
  StoryMediaCache._();

  /// Cache key used by the underlying [CacheManager].
  static const String key = 'flutterStoryViewMediaCache';

  /// The shared cache manager instance.
  static final CacheManager instance = CacheManager(
    Config(
      key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 200,
    ),
  );

  /// Returns the already-cached file for [url], or `null` when it has not been
  /// downloaded yet. Never triggers a network request.
  static Future<FileInfo?> getCached(String url) {
    return instance.getFileFromCache(url);
  }

  /// Returns the cached file for [url], downloading it first if necessary.
  static Future<FileInfo> resolve(String url) {
    return instance.downloadFile(url);
  }

  /// Pre-downloads [url] into the cache, ignoring any errors. Safe to call for
  /// media that may already be cached.
  static Future<void> prefetch(String url) async {
    if (url.isEmpty) return;
    try {
      final cached = await instance.getFileFromCache(url);
      if (cached != null) return;
      await instance.downloadFile(url);
    } catch (_) {
      // Prefetch is best-effort; ignore failures.
    }
  }
}
