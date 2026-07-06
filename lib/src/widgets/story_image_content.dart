import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/story_item.dart';
import '../models/story_media_type.dart';

/// Renders an image [StoryItem], resolving the correct image provider for the
/// item's [StorySource] and reporting load/error state to the parent.
class StoryImageContent extends StatelessWidget {
  /// Creates an image content widget.
  const StoryImageContent({
    super.key,
    required this.item,
    required this.onLoaded,
    required this.onError,
    this.loadingBuilder,
    this.errorBuilder,
    this.fit = BoxFit.contain,
  });

  /// The image story to render.
  final StoryItem item;

  /// Called once the image has finished decoding.
  final VoidCallback onLoaded;

  /// Called when the image fails to load.
  final void Function(Object error) onError;

  /// Optional loading placeholder.
  final WidgetBuilder? loadingBuilder;

  /// Optional error widget builder.
  final Widget Function(BuildContext, Object)? errorBuilder;

  /// How the image is inscribed into the available space.
  final BoxFit fit;

  Widget _defaultLoading(BuildContext context) => const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );

  Widget _defaultError(BuildContext context, Object error) => ColoredBox(
        color: Colors.black,
        child: const Center(
          child: Icon(Icons.broken_image_outlined,
              color: Colors.white54, size: 48),
        ),
      );

  @override
  Widget build(BuildContext context) {
    switch (item.source) {
      case StorySource.network:
        return CachedNetworkImage(
          imageUrl: item.url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          fadeInDuration: const Duration(milliseconds: 150),
          imageBuilder: (context, imageProvider) {
            // Image is ready in cache.
            WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
            return Image(image: imageProvider, fit: fit);
          },
          placeholder: (context, _) =>
              loadingBuilder?.call(context) ?? _defaultLoading(context),
          errorWidget: (context, _, error) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onError(error));
            return errorBuilder?.call(context, error) ??
                _defaultError(context, error);
          },
        );
      case StorySource.asset:
        return Image.asset(
          item.url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          frameBuilder: (context, child, frame, wasSync) {
            if (frame != null || wasSync) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
            }
            return child;
          },
          errorBuilder: (context, error, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onError(error));
            return errorBuilder?.call(context, error) ??
                _defaultError(context, error);
          },
        );
      case StorySource.file:
        return Image.file(
          File(item.url),
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          frameBuilder: (context, child, frame, wasSync) {
            if (frame != null || wasSync) {
              WidgetsBinding.instance.addPostFrameCallback((_) => onLoaded());
            }
            return child;
          },
          errorBuilder: (context, error, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onError(error));
            return errorBuilder?.call(context, error) ??
                _defaultError(context, error);
          },
        );
    }
  }
}
