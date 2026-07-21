import 'package:flutter/material.dart';
import 'package:social_story_view/social_story_view.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'social_story_view demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFFD62976), useMaterial3: true),
      home: const FeedScreen(),
    );
  }
}

/// Mock data ------------------------------------------------------------------

List<StoryUser> buildMockUsers() {
  String img(int seed) => 'https://picsum.photos/seed/$seed/1080/1920';

  return <StoryUser>[
    StoryUser(
      id: 'me',
      username: 'You',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      isCurrentUser: true,
      stories: <StoryItem>[StoryItem.image(id: 'me-1', url: img(101))],
    ),
    StoryUser(
      id: 'u1',
      username: 'alice',
      avatarUrl: 'https://i.pravatar.cc/150?img=5',
      stories: <StoryItem>[
        StoryItem.image(
          id: 'u1-1',
          url: img(11),
          duration: const Duration(seconds: 5),
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          link: const StoryLink(url: 'https://flutter.dev', label: 'Detayları incele'),
          metadata: const <String, Object?>{
            'title': 'İkinci Periyodik Bakımınızda %5 İndirim!',
            'dateRange': '01.06.2025 - 01.06.2026',
            'body':
                'Bu yıl içinde yapacağınız ikinci periyodik bakımlarda '
                '%5 indirim kazanmak için lütfen kampanya detaylarını '
                'inceleyeniz!',
          },
        ),
        StoryItem.text(
          id: 'u1-2',
          text: 'Text stories work too! \u2728',
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFFFA7E1E), Color(0xFFD62976)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          duration: const Duration(seconds: 4),
        ),
        StoryItem.image(id: 'u1-3', url: img(12)),
      ],
    ),
    StoryUser(
      id: 'u2',
      username: 'bob',
      avatarUrl: 'https://i.pravatar.cc/150?img=8',
      stories: <StoryItem>[
        StoryItem.video(
          id: 'u2-1',
          url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        StoryItem.image(id: 'u2-2', url: img(22)),
      ],
    ),
    StoryUser(
      id: 'u3',
      username: 'carol',
      avatarUrl: 'https://i.pravatar.cc/150?img=20',
      stories: <StoryItem>[
        StoryItem.image(id: 'u3-1', url: img(31), isViewed: true),
        StoryItem.image(id: 'u3-2', url: img(32), isViewed: true),
      ],
    ),
  ];
}

/// Feed screen ----------------------------------------------------------------

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  late List<StoryUser> _users = buildMockUsers();
  bool _lightTheme = false;

  StoryViewTheme get _theme => _lightTheme ? StoryViewTheme.light() : StoryViewTheme.dark();

  void _openViewer(int index) {
    final controller = StoryViewController();
    final theme = _theme;
    showStoryView(
      context,
      users: _users,
      controller: controller,
      useRootNavigator: true,
      initialUserIndex: index,
      transition: StoryTransition.cube,
      theme: theme,
      onStoryShow: (user, item, i) => _markViewed(user.id, item.id),
      onStoryComplete: (user, item, i) => debugPrint('Completed ${user.username} / ${item.id}'),
      onAllStoriesComplete: (user) => debugPrint('All stories of ${user.username} complete'),
      onSwipeUp: (user, item) => debugPrint('Swiped up on ${user.username} / ${item.id}'),
      overlayBuilder: (context, user, item, i) {
        // Render a marketing-style text overlay only for items that carry
        // campaign metadata; other stories get no overlay.
        final meta = item.metadata;
        if (meta == null || meta['title'] == null) return const SizedBox();
        final onMedia = theme.brightness == Brightness.light ? const Color(0xFF1A1A1A) : Colors.white;
        final onMediaMuted = theme.brightness == Brightness.light ? const Color(0xFF5C5C5C) : Colors.white70;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 156, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  meta['title']! as String,
                  style: TextStyle(color: onMedia, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (meta['dateRange'] != null) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(meta['dateRange']! as String, style: TextStyle(color: onMediaMuted, fontSize: 14)),
                ],
                if (meta['body'] != null) ...<Widget>[
                  const SizedBox(height: 18),
                  Text(meta['body']! as String, style: TextStyle(color: onMedia, fontSize: 16, height: 1.4)),
                  ElevatedButton(
                    onPressed: () {
                      launchUrl(Uri.tryParse('https://flutter.dev') ?? Uri.parse('https://flutter.dev'));
                      debugPrint('CTA pressed');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: Text('İncele')),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      footerBuilder: (context, user, item, i) {
        // Don't allow replying or reacting to your own story.
        if (user.isCurrentUser) return const SizedBox.shrink();
        return StoryReplyBar(
          hintText: 'Reply to ${user.username}...',
          style: theme.replyBarStyle,
          onFocusChanged: (focused) => focused ? controller.pause() : controller.resume(),
          onReaction: (emoji) {
            controller.resume();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reacted $emoji to ${user.username}')));
          },
          onSubmitted: (text) {
            controller.resume();
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Replied "$text" to ${user.username}')));
          },
        );
      },
    ).whenComplete(() {
      controller.dispose();
      setState(() {}); // refresh rings after viewing
    });
  }

  void _markViewed(String userId, String storyId) {
    setState(() {
      _users = _users.map((u) {
        if (u.id != userId) return u;
        return u.copyWith(stories: u.stories.map((s) => s.id == storyId ? s.copyWith(isViewed: true) : s).toList());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stories'),
        actions: <Widget>[
          IconButton(
            tooltip: _lightTheme ? 'Switch to dark' : 'Switch to light',
            icon: Icon(_lightTheme ? Icons.dark_mode : Icons.light_mode),
            onPressed: () => setState(() => _lightTheme = !_lightTheme),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          StoryAvatarBar(
            users: _users,
            style: _theme.avatarStyle,
            onAvatarTap: (user, index) => _openViewer(index),
            onAddTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add to your story'))),
          ),
          const Divider(height: 1),
          const Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Tap an avatar above to open the story viewer.\n\n'
                  '\u2022 Tap right / left to move between stories\n'
                  '\u2022 Hold to pause\n'
                  '\u2022 Swipe left / right for the next / previous user\n'
                  '\u2022 Swipe down to dismiss\n'
                  '\u2022 Swipe up triggers the reply / swipe-up action',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
