# Changelog

All notable changes to this project are documented here. This project adheres to
[Semantic Versioning](https://semver.org/).

## 0.1.0

Initial release.

### Added
- Full-screen `StoryView` supporting image, video and text/gradient stories.
- Segmented, auto-advancing `StoryProgressBar`.
- Tap (next/previous), long-press (pause/resume), swipe-down (dismiss),
  swipe-up (callback) and horizontal swipe (between users) gestures.
- Automatic transition between user story groups.
- `StoryViewController` for `pause`, `resume`, `next`, `previous`, `jumpTo`,
  `close`, with independent pause reasons.
- `StoryAvatarBar` / `StoryAvatar` with seen/unseen gradient rings and a
  current-user "add" badge.
- `StoryReplyBar` WhatsApp-style footer with quick reactions.
- Customization API: `StoryProgressStyle`, `StoryAvatarStyle`, `StoryTransition`
  (none, slide, cube, fade, scale, zoom) and header/footer/loading/error
  builders.
- Lifecycle-aware pausing, neighbour image precaching and safe video controller
  disposal.
- RTL-aware tap zones.
- Immutable `StoryItem` / `StoryUser` models with `copyWith`, JSON
  serialization and viewed-state helpers.
- `showStoryView` convenience launcher.
- Unit and widget test suite; runnable example app.
