/// A customizable, production-ready Instagram/WhatsApp style story (status)
/// viewer and avatar bar for Flutter.
///
/// Import this single library to access the public API:
///
/// ```dart
/// import 'package:social_story_view/social_story_view.dart';
/// ```
///
/// See [StoryView] for the full-screen viewer, [StoryAvatarBar] for the
/// horizontal avatar list, and [StoryViewController] for programmatic control.
library;

// Models
export 'src/models/story_callbacks.dart';
export 'src/models/story_item.dart';
export 'src/models/story_link.dart';
export 'src/models/story_media_type.dart';
export 'src/models/story_progress_style.dart';
export 'src/models/story_transition.dart';
export 'src/models/story_user.dart';
export 'src/models/story_view_theme.dart';

// Controllers
export 'src/controllers/story_view_controller.dart'
    show StoryViewController, StoryViewControllerDelegate, StoryPauseReason;

// Utilities
export 'src/utils/story_media_cache.dart' show StoryMediaCache;
export 'src/utils/story_video_controller_pool.dart'
    show StoryVideoControllerPool;

// Widgets
export 'src/widgets/default_story_header.dart';
export 'src/widgets/show_story_view.dart';
export 'src/widgets/story_avatar_bar.dart';
export 'src/widgets/story_link_button.dart';
export 'src/widgets/story_progress_bar.dart';
export 'src/widgets/story_reply_bar.dart';
export 'src/widgets/story_view.dart';
