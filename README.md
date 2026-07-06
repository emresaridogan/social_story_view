# social_story_view

**🌍 Language / Dil:** **English** · [Türkçe](README.tr.md)

A customizable, production-ready **Instagram / WhatsApp style story (status) viewer** and avatar bar for Flutter.

Supports image, video and text stories, segmented auto-advancing progress bars, tap & swipe gestures, per-user grouping, light/dark theming, link call-to-actions, a rich customization API and zero forced state-management dependency.

[![pub package](https://img.shields.io/badge/pub-0.1.0-blue.svg)](https://pub.dev/packages/social_story_view)

---

## Table of contents

1. [Features](#features)
2. [Installation](#installation)
3. [Platform setup](#platform-setup)
4. [Quick start](#quick-start)
5. [Core concepts](#core-concepts)
6. [Data models](#data-models)
7. [The avatar bar](#the-avatar-bar)
8. [The story viewer](#the-story-viewer)
9. [Programmatic control](#programmatic-control)
10. [Callbacks](#callbacks)
11. [Theming (light & dark)](#theming-light--dark)
12. [Custom overlays](#custom-overlays)
13. [Reply bar](#reply-bar)
14. [Link call-to-action](#link-call-to-action)
15. [Progress bar styling](#progress-bar-styling)
16. [Transitions](#transitions)
17. [Gestures](#gestures)
18. [Performance & memory](#performance--memory)
19. [Full API reference](#full-api-reference)
20. [Example app](#example-app)
21. [License](#license)

---

## Features

- 📱 **Full-screen viewer** for image, video and text/gradient stories.
- 📊 **Segmented progress bar** — one auto-filling bar per story.
- 👆 **Tap gestures** — right third → next, left third → previous, hold → pause.
- 👋 **Swipe gestures** — down to dismiss, up for a custom action, left/right between users.
- 🔍 **Pinch-to-zoom** — zoom any image/video story with two fingers; it snaps back automatically when you lift them.
- 🧊 **Cube & other transitions** between users (`none`, `slide`, `cube`, `fade`, `scale`, `zoom`).
- 👥 **Automatic user-group transitions** — finishes one user, moves to the next; the next story never starts mid-swipe.
- ⏯️ **`StoryViewController`** for programmatic `pause` / `resume` / `next` / `previous` / `jumpTo` / `close`.
- 🎞️ **Video stories** with a buffering indicator, auto-duration and controller pooling for instant reopen.
- ⚡ **Lazy precaching** of upcoming media and safe disposal of video controllers.
- 🟣 **Avatar bar** with seen/unseen gradient rings and a "your story" add button.
- 🌗 **Light & dark themes** via `StoryViewTheme` — switch the whole UI with one parameter.
- 🔗 **Link / CTA** buttons attached to any story (`StoryLink`), opened in-browser or handled by you.
- 💬 **Minimalist reply bar** with quick reactions, fully styleable and replaceable via builder hooks.
- 🎨 **Highly customizable** — header / footer / overlay / loading / error builders, scrim colors, progress style.
- 🌍 **RTL aware**, responsive, null-safe and Dart 3 ready.

---

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  social_story_view: ^0.1.0
```

Then run:

```bash
flutter pub get
```

**Minimum requirements:** Flutter 3.19+, Dart 3.4+.

---

## Platform setup

This package depends on [`video_player`](https://pub.dev/packages/video_player),
[`cached_network_image`](https://pub.dev/packages/cached_network_image) and
[`url_launcher`](https://pub.dev/packages/url_launcher).

- **iOS** — to allow network video/images over HTTP add the appropriate
  `NSAppTransportSecurity` keys to `ios/Runner/Info.plist` (HTTPS works out of the box).
- **Android** — internet permission is included by default; for HTTP media set
  `android:usesCleartextTraffic="true"` in your `AndroidManifest.xml`.

---

## Quick start

```dart
import 'package:flutter/material.dart';
import 'package:social_story_view/social_story_view.dart';

final users = <StoryUser>[
  StoryUser(
    id: 'u1',
    username: 'alice',
    avatarUrl: 'https://i.pravatar.cc/150?img=5',
    stories: [
      StoryItem.image(id: '1', url: 'https://picsum.photos/seed/1/1080/1920'),
      StoryItem.text(id: '2', text: 'Hello stories! ✨'),
      StoryItem.video(id: '3', url: 'https://.../clip.mp4'),
    ],
  ),
  // ...more users
];

// Open the viewer at a specific user:
showStoryView(context, users: users, initialUserIndex: 0);
```

---

## Core concepts

The package has a few building blocks:

| Piece | What it is |
| --- | --- |
| **`StoryUser`** | One person and their ordered list of `StoryItem`s. |
| **`StoryItem`** | A single story: image, video or text/gradient. |
| **`StoryView`** / **`showStoryView`** | The full-screen viewer that plays a list of users. |
| **`StoryAvatarBar`** | The horizontal row of avatars with status rings. |
| **`StoryViewController`** | Optional handle to drive playback programmatically. |
| **`StoryViewTheme`** | A bundle of styles that themes the whole viewer (light/dark). |

Use `showStoryView(...)` for the common case (push a modal route), or embed
`StoryView(...)` directly inside your own route when you need full control.

---

## Data models

### StoryItem

Three factory constructors cover every story type:

```dart
// Image story (duration defaults to imageDuration on the viewer)
StoryItem.image(id: 'a', url: '...', duration: Duration(seconds: 8));

// Video story (duration is auto-detected from the file)
StoryItem.video(id: 'b', url: '...');

// Text / gradient story
StoryItem.text(
  id: 'c',
  text: 'Hi 👋',
  gradient: LinearGradient(colors: [Colors.purple, Colors.pink]),
);
```

Every `StoryItem` also accepts:

- `isViewed` — whether the story is already seen (drives the ring color).
- `metadata` — a free-form `Map<String, dynamic>` you can read in your overlay
  builder (e.g. campaign title, date range, body copy).
- `link` — an optional [`StoryLink`](#link-call-to-action) call-to-action.

`StoryItem` supports `copyWith`, `toJson` / `fromJson`.

### StoryUser

```dart
StoryUser(
  id: 'u1',
  username: 'alice',
  avatarUrl: '...',
  stories: [...],
  isCurrentUser: false, // shows the "+" add badge in the avatar bar
);
```

Helpers: `firstUnseenIndex`, `markStoryViewed`, `hasUnseen`, `isFullyViewed`,
plus `copyWith`, `toJson` / `fromJson`.

---

## The avatar bar

```dart
StoryAvatarBar(
  users: users,
  onAvatarTap: (user, index) => showStoryView(
    context,
    users: users,
    initialUserIndex: index,
  ),
  onAddTap: () => print('Add to your story'),
  style: const StoryAvatarStyle(
    radius: 32,
    ringThickness: 2.5,
    ringGap: 3,
    seenColor: Color(0xFFBDBDBD),
    unseenGradient: LinearGradient(
      colors: [Color(0xFFFEDA75), Color(0xFFFA7E1E), Color(0xFFD62976)],
    ),
    showLabel: true,
    currentUserLabel: 'Your story',
  ),
);
```

- Users with unseen stories get the **gradient ring**; fully-seen users get the
  flat `seenColor` ring.
- The user marked `isCurrentUser: true` shows a **"+" add badge**; tapping it
  fires `onAddTap`.

---

## The story viewer

`StoryView` is the full-screen player. Every parameter is optional except `users`:

```dart
StoryView(
  users: users,
  controller: controller,            // optional programmatic control
  initialUserIndex: 0,
  initialStoryIndex: null,           // null → first unseen story
  transition: StoryTransition.cube,
  imageDuration: const Duration(seconds: 10),
  contentFit: BoxFit.contain,
  muted: false,
  theme: StoryViewTheme.dark(),      // light/dark theming
  swipeDownToDismiss: true,
  headerConfig: const StoryHeaderConfig(),
  // ...builders & callbacks (see below)
);
```

For the common "open as a modal" case, use the convenience helper which pushes a
transparent route and pops it on dismiss:

```dart
showStoryView(context, users: users, initialUserIndex: index);
```

`showStoryView` accepts the **same parameters** as `StoryView`.

---

## Programmatic control

```dart
final controller = StoryViewController();

StoryView(users: users, controller: controller);

controller.pause();
controller.resume();
controller.next();
controller.previous();
controller.jumpTo(userIndex: 2, storyIndex: 1);
controller.close();

// Don't forget when you own it:
controller.dispose();
```

Pausing supports **independent reasons** (`StoryPauseReason.hold`, `buffering`,
`lifecycle`, `zoom`, `manual`), so playback only resumes once **every** reason is
cleared. This is why pausing for the keyboard and pausing for buffering never
fight each other.

---

## Callbacks

```dart
StoryView(
  users: users,
  onStoryShow: (user, item, index) {},     // story became visible
  onStoryComplete: (user, item, index) {},  // story fully played
  onAllStoriesComplete: (user) {},          // user finished all stories
  onSwipeUp: (user, item) {},               // swipe-up action
  onLinkTap: (user, item, link) {},         // a StoryLink was tapped
  onClose: () {},                           // viewer dismissed
);
```

If `onLinkTap` is omitted, tapping a `StoryLink` opens its `url` in the browser
automatically (and pauses/resumes around the launch).

---

## Theming (light & dark)

`StoryViewTheme` bundles every sub-style (progress bar, header, reply bar,
avatars) plus the background and the top/bottom readability scrims into one
object, so you can switch the **entire** viewer with a single value.

```dart
// Built-in presets:
StoryView(users: users, theme: StoryViewTheme.dark());   // default
StoryView(users: users, theme: StoryViewTheme.light());
```

Tweak any field from outside via `copyWith`:

```dart
StoryView(
  users: users,
  theme: StoryViewTheme.light().copyWith(
    backgroundColor: Colors.grey.shade100,
    topScrimColor: const Color(0x33FFFFFF),
  ),
);
```

`StoryViewTheme` fields:

| Field | Purpose |
| --- | --- |
| `brightness` | `Brightness.light` / `dark` — branch on it in your own overlays. |
| `backgroundColor` | Color behind the media (letterbox area). |
| `progressStyle` | The segmented progress bar style. |
| `headerStyle` | Colors/typography of the default header. |
| `replyBarStyle` | Style of the default reply bar. |
| `avatarStyle` | Style of the avatar bar / avatars. |
| `topScrimColor` | Top gradient scrim (behind progress bar + header). |
| `bottomScrimColor` | Bottom gradient scrim (behind footer + link). |

> **Precedence:** the explicit `progressStyle`, `backgroundColor` and
> `headerStyle` parameters on `StoryView` override the theme when provided.
> Leave them `null` to inherit from `theme`.

Each sub-style also has its own `.light()` preset:
`StoryProgressStyle.light()`, `StoryHeaderStyle.light()`,
`StoryReplyBarStyle.light()`.

---

## Custom overlays

Replace any part of the chrome with a builder. There are three layout slots:

```dart
StoryView(
  users: users,

  // Top bar (avatar, name, timestamp, close). Replaces DefaultStoryHeader.
  headerBuilder: (context, user, item, index) => MyHeader(user: user),

  // Bottom bar (reply input, reactions, link button live above it).
  footerBuilder: (context, user, item, index) => StoryReplyBar(
    onSubmitted: (text) => print('Reply: $text'),
  ),

  // Drawn over the whole media area — perfect for captions / marketing copy.
  overlayBuilder: (context, user, item, index) {
    final meta = item.metadata;
    if (meta?['title'] == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(meta!['title'] as String),
    );
  },

  // Shown while media loads / on failure.
  loadingBuilder: (context, user, item) => const CircularProgressIndicator(),
  errorBuilder: (context, user, item, error) => const Icon(Icons.error),
);
```

If you keep the default header, control which elements it shows with
`StoryHeaderConfig`, and its colors/typography with `StoryHeaderStyle`:

```dart
StoryView(
  users: users,
  headerConfig: const StoryHeaderConfig(
    showAvatar: true,
    showUsername: true,
    showTimestamp: true,
    showCloseButton: true,
  ),
  headerStyle: const StoryHeaderStyle(/* colors, fonts, shadow */),
);
```

> **Tip:** Interactive children inside `overlayBuilder` must wrap themselves in
> their own gesture detectors; otherwise taps pass through to the navigation
> layer.

---

## Reply bar

`StoryReplyBar` is a minimalist, ready-made footer with a rounded input and
quick reaction emojis. Use `onFocusChanged` to pause the story while typing:

```dart
footerBuilder: (context, user, item, index) {
  // Don't allow replying to your own story:
  if (user.isCurrentUser) return const SizedBox.shrink();

  return StoryReplyBar(
    hintText: 'Reply to ${user.username}...',
    reactions: const ['❤️', '😮', '😂', '👏', '🔥'],
    onFocusChanged: (focused) =>
        focused ? controller.pause() : controller.resume(),
    onReaction: (emoji) => print('Reacted $emoji'),
    onSubmitted: (text) => print('Replied: $text'),
    style: const StoryReplyBarStyle(/* fill, border, text colors... */),
  );
}
```

Toggle parts with `enableReply` / `enableReactions`, and fully replace sections
via the builder hooks:

- `inputBuilder` — replace the entire input pill + send button.
- `sendButtonBuilder` — replace only the trailing send affordance.
- `reactionBuilder` — replace a single reaction emoji widget.

Style it directly with `StoryReplyBarStyle` (or `StoryReplyBarStyle.light()`).

---

## Link call-to-action

Attach a tappable button to any story via `StoryItem.link`:

```dart
StoryItem.image(
  id: 'promo',
  url: '...',
  link: const StoryLink(
    url: 'https://flutter.dev',
    label: 'Learn more',
    icon: Icons.link,
    alignment: Alignment.bottomCenter,
  ),
);
```

The button renders as a pill at `link.alignment`. Bottom-aligned links sit
**above** the reply bar so they're never hidden behind the input. Handle taps
yourself with `onLinkTap`, or let the package open the URL in the browser
automatically.

---

## Progress bar styling

```dart
StoryView(
  users: users,
  progressStyle: const StoryProgressStyle(
    color: Colors.white,                       // filled portion
    backgroundColor: Color(0x55FFFFFF),         // remaining track
    height: 2.5,
    spacing: 4,
    borderRadius: BorderRadius.all(Radius.circular(8)),
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
  ),
);
```

Use `StoryProgressStyle.light()` for a dark-on-light variant.

---

## Transitions

Choose the per-user transition with `StoryTransition`:

| Value | Effect |
| --- | --- |
| `none` | Instant page change. |
| `slide` | Standard horizontal slide. |
| `cube` | 3D cube rotation (like Instagram). |
| `fade` | Cross-fade. |
| `scale` | Scale in/out. |
| `zoom` | Zoom-through. |

```dart
StoryView(users: users, transition: StoryTransition.cube);
```

---

## Gestures

| Gesture | Action |
| --- | --- |
| Tap right third | Next story |
| Tap left third | Previous story |
| Long press / hold | Pause (release to resume) |
| Pinch (two fingers) | Zoom the image/video (snaps back on release) |
| Swipe horizontally | Next / previous **user** |
| Swipe down | Dismiss viewer |
| Swipe up | `onSwipeUp` callback |

Tap zones are mirrored automatically in RTL layouts. The next user's story only
starts **after** the swipe settles, never mid-gesture. Pinch-zoom pauses the
story while active and resumes once you lift your fingers.

---

## Performance & memory

- Each video uses a `VideoPlayerController` from a **pool** that is reused for
  instant reopen and disposed when no longer needed.
- Only the **settled** user's page plays; off-screen pages are paused.
- The first image of the current and next user is **precached** to avoid jank.
- Progress is driven by a lightweight `ValueNotifier`, avoiding full rebuilds.
- Buffering pauses are tracked separately so a buffering video never deadlocks.

---

## Full API reference

### Exported types

- **Widgets:** `StoryView`, `showStoryView`, `StoryAvatarBar`, `StoryAvatar`,
  `StoryProgressBar`, `StoryReplyBar`, `StoryLinkButton`, `DefaultStoryHeader`.
- **Models:** `StoryUser`, `StoryItem`, `StoryLink`, `StoryMediaType`,
  `StoryTransition`, `StoryProgressStyle`, `StoryViewTheme`, `StoryHeaderStyle`,
  `StoryHeaderConfig`, `StoryReplyBarStyle`, `StoryAvatarStyle`.
- **Controller:** `StoryViewController`, `StoryPauseReason`.
- **Callbacks:** `StoryHeaderBuilder`, `StoryFooterBuilder`,
  `StoryOverlayBuilder`, `StoryLoadingBuilder`, `StoryErrorBuilder`,
  `OnStoryShow`, `OnStoryComplete`, `OnAllStoriesComplete`, `OnStorySwipeUp`,
  `OnStoryLinkTap`, `OnViewerClose`.
- **Utilities:** `StoryMediaCache`, `StoryVideoControllerPool`.

---

## Example app

A complete runnable demo (avatar bar + viewer with image, video and text
stories, a light/dark toggle, custom reply footer, link CTA, marketing overlay
and viewed-state tracking) lives in [`example/`](example/lib/main.dart):

```bash
cd example
flutter run
```

---

## License

MIT — see [LICENSE](LICENSE).
