import 'package:social_story_view/social_story_view.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StoryItem', () {
    test('json round-trip preserves core fields', () {
      final item = StoryItem.image(
        id: 'a',
        url: 'https://example.com/a.jpg',
        duration: const Duration(seconds: 7),
        isViewed: true,
      );
      final decoded = StoryItem.fromJson(item.toJson());
      expect(decoded.id, 'a');
      expect(decoded.type, StoryMediaType.image);
      expect(decoded.url, 'https://example.com/a.jpg');
      expect(decoded.duration, const Duration(seconds: 7));
      expect(decoded.isViewed, isTrue);
    });

    test('effectiveDuration falls back for non-video stories', () {
      final text = StoryItem.text(id: 't', text: 'hi', duration: kDefaultStoryDuration);
      expect(text.effectiveDuration, kDefaultStoryDuration);
      final video = StoryItem.video(id: 'v', url: 'x');
      expect(video.effectiveDuration, Duration.zero);
    });

    test('copyWith replaces only the requested fields', () {
      final item = StoryItem.text(id: 't', text: 'a');
      final copy = item.copyWith(isViewed: true);
      expect(copy.id, 't');
      expect(copy.text, 'a');
      expect(copy.isViewed, isTrue);
    });
  });

  group('StoryUser', () {
    StoryUser user() => StoryUser(
          id: 'u',
          username: 'u',
          stories: <StoryItem>[
            StoryItem.text(id: '1', text: 'a', isViewed: true),
            StoryItem.text(id: '2', text: 'b'),
            StoryItem.text(id: '3', text: 'c'),
          ],
        );

    test('firstUnseenIndex finds the first unseen story', () {
      expect(user().firstUnseenIndex, 1);
    });

    test('markStoryViewed sets the flag immutably', () {
      final u = user();
      final updated = u.markStoryViewed(1);
      expect(u.stories[1].isViewed, isFalse);
      expect(updated.stories[1].isViewed, isTrue);
    });

    test('isFullyViewed reflects all stories seen', () {
      final u = user()
          .markStoryViewed(1)
          .markStoryViewed(2);
      expect(u.isFullyViewed, isTrue);
      expect(u.hasUnseen, isFalse);
    });
  });

  group('StoryViewController', () {
    test('pause/resume tracks independent reasons', () {
      final c = StoryViewController();
      expect(c.isPaused, isFalse);
      c.pause(StoryPauseReason.hold);
      c.pause(StoryPauseReason.buffering);
      expect(c.isPaused, isTrue);
      c.resume(StoryPauseReason.hold);
      expect(c.isPaused, isTrue); // buffering still active
      c.resume(StoryPauseReason.buffering);
      expect(c.isPaused, isFalse);
      c.dispose();
    });

    test('forwards navigation calls to the delegate', () {
      final delegate = _FakeDelegate();
      final c = StoryViewController()..attach(delegate);
      c.next();
      c.previous();
      c.jumpTo(userIndex: 2, storyIndex: 1);
      c.close();
      expect(delegate.nextCount, 1);
      expect(delegate.previousCount, 1);
      expect(delegate.jumpTo, const <int>[2, 1]);
      expect(delegate.closed, isTrue);
      c.dispose();
    });

    test('syncPosition updates indices and notifies', () {
      final c = StoryViewController();
      var notified = 0;
      c.addListener(() => notified++);
      c.syncPosition(1, 2);
      expect(c.currentUserIndex, 1);
      expect(c.currentStoryIndex, 2);
      expect(notified, 1);
      c.dispose();
    });
  });
}

class _FakeDelegate implements StoryViewControllerDelegate {
  int nextCount = 0;
  int previousCount = 0;
  List<int> jumpTo = const <int>[];
  bool closed = false;

  @override
  void onNext() => nextCount++;

  @override
  void onPrevious() => previousCount++;

  @override
  void onJumpTo(int userIndex, int storyIndex) =>
      jumpTo = <int>[userIndex, storyIndex];

  @override
  void onClose() => closed = true;

  @override
  void onPause(StoryPauseReason reason) {}

  @override
  void onResume(StoryPauseReason reason) {}
}
