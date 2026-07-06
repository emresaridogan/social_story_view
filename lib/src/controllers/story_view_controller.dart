import 'package:flutter/foundation.dart';

/// Reasons the story playback can be paused.
enum StoryPauseReason {
  /// Paused programmatically through [StoryViewController.pause].
  manual,

  /// Paused because the user is holding their finger on the screen.
  hold,

  /// Paused while media (e.g. video) is buffering.
  buffering,

  /// Paused because the app went to the background.
  lifecycle,

  /// Paused because the user is pinch-zooming the story.
  zoom,
}

/// Internal contract implemented by the story viewer state so that a
/// [StoryViewController] can drive it.
///
/// This is intentionally not exported; consumers interact only through
/// [StoryViewController].
abstract class StoryViewControllerDelegate {
  /// Pauses playback for the given [reason].
  void onPause(StoryPauseReason reason);

  /// Resumes playback for the given [reason].
  void onResume(StoryPauseReason reason);

  /// Advances to the next story (or next user).
  void onNext();

  /// Goes back to the previous story (or previous user).
  void onPrevious();

  /// Jumps directly to a specific user and story index.
  void onJumpTo(int userIndex, int storyIndex);

  /// Closes the viewer.
  void onClose();
}

/// Public controller for programmatic control of a story viewer.
///
/// Pass the same instance to a story viewer widget and keep a reference to it
/// to drive playback from your own UI:
///
/// ```dart
/// final controller = StoryViewController();
/// // ...
/// controller.pause();
/// controller.next();
/// ```
///
/// Remember to [dispose] the controller when it is no longer needed.
class StoryViewController extends ChangeNotifier {
  StoryViewControllerDelegate? _delegate;

  /// Index of the currently visible user within the viewer.
  int get currentUserIndex => _currentUserIndex;
  int _currentUserIndex = 0;

  /// Index of the currently visible story within the current user.
  int get currentStoryIndex => _currentStoryIndex;
  int _currentStoryIndex = 0;

  /// Whether playback is currently paused for any reason.
  bool get isPaused => _pauseReasons.isNotEmpty;

  /// Whether the controller has been attached to a live viewer.
  bool get isAttached => _delegate != null;

  final Set<StoryPauseReason> _pauseReasons = <StoryPauseReason>{};

  /// Binds this controller to a viewer. Called by the widget; not for app use.
  void attach(StoryViewControllerDelegate delegate) {
    _delegate = delegate;
  }

  /// Unbinds this controller from its viewer. Called by the widget.
  void detach(StoryViewControllerDelegate delegate) {
    if (identical(_delegate, delegate)) {
      _delegate = null;
      _pauseReasons.clear();
    }
  }

  /// Updates the cached current position. Called by the widget.
  void syncPosition(int userIndex, int storyIndex) {
    if (_currentUserIndex == userIndex && _currentStoryIndex == storyIndex) {
      return;
    }
    _currentUserIndex = userIndex;
    _currentStoryIndex = storyIndex;
    notifyListeners();
  }

  /// Pauses playback. The optional [reason] lets multiple sources pause
  /// independently; playback only resumes once every reason is cleared.
  void pause([StoryPauseReason reason = StoryPauseReason.manual]) {
    final wasPaused = isPaused;
    _pauseReasons.add(reason);
    _delegate?.onPause(reason);
    if (!wasPaused) notifyListeners();
  }

  /// Resumes playback for the given [reason].
  void resume([StoryPauseReason reason = StoryPauseReason.manual]) {
    final wasPaused = isPaused;
    _pauseReasons.remove(reason);
    _delegate?.onResume(reason);
    if (wasPaused != isPaused) notifyListeners();
  }

  /// Advances to the next story, moving to the next user when needed.
  void next() => _delegate?.onNext();

  /// Goes back to the previous story, moving to the previous user when needed.
  void previous() => _delegate?.onPrevious();

  /// Jumps to a specific [userIndex] and [storyIndex].
  void jumpTo({required int userIndex, int storyIndex = 0}) =>
      _delegate?.onJumpTo(userIndex, storyIndex);

  /// Closes the viewer.
  void close() => _delegate?.onClose();

  @override
  void dispose() {
    _delegate = null;
    _pauseReasons.clear();
    super.dispose();
  }
}
