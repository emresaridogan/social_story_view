import 'story_view_controller.dart' show StoryPauseReason;

/// Internal contract that a single user's story page exposes so the parent
/// [StoryView] can drive whichever page is currently active.
///
/// Not exported; consumers use [StoryViewController] instead.
abstract class StoryUserPlayback {
  /// Pauses playback for the given [reason].
  void pause(StoryPauseReason reason);

  /// Resumes playback for the given [reason].
  void resume(StoryPauseReason reason);

  /// Advances to the next story, requesting the next user at the boundary.
  void nextStory();

  /// Goes back one story, requesting the previous user at the boundary.
  void previousStory();

  /// Jumps directly to the story at [index] within this user.
  void jumpToStory(int index);

  /// The index of the story currently shown for this user.
  int get currentStoryIndex;
}
