# social_story_view example

A runnable demo of the [`social_story_view`](https://pub.dev/packages/social_story_view)
package.

It showcases:

- An **avatar bar** with seen/unseen status rings and a "your story" add badge.
- The full-screen **story viewer** with image, video and text/gradient stories.
- A **light / dark theme toggle** in the app bar that re-themes the whole viewer
  via `StoryViewTheme`.
- A custom **reply bar** footer (hidden on your own story) with quick reactions.
- A **link / CTA** button and a marketing **overlay** driven by story metadata.
- Viewed-state tracking that updates the rings after you watch a story.

## Run it

```bash
cd example
flutter run
```

## What to try

- Tap the right / left side to move between stories.
- Hold to pause, release to resume.
- Swipe left / right to move between users (cube transition).
- Swipe down to dismiss, swipe up for the swipe-up callback.
- Tap the sun/moon icon in the app bar to switch light / dark theme.

See [`lib/main.dart`](lib/main.dart) for the full, commented source.
