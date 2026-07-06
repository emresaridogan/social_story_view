import 'package:flutter/material.dart';
import 'package:social_story_view/social_story_view.dart';
import 'package:flutter_test/flutter_test.dart';

List<StoryUser> _users() => <StoryUser>[
      StoryUser(
        id: 'u1',
        username: 'alice',
        stories: <StoryItem>[
          StoryItem.text(
            id: 'a',
            text: 'one',
            duration: const Duration(seconds: 2),
          ),
          StoryItem.text(
            id: 'b',
            text: 'two',
            duration: const Duration(seconds: 2),
          ),
        ],
      ),
      StoryUser(
        id: 'u2',
        username: 'bob',
        stories: <StoryItem>[
          StoryItem.text(
            id: 'c',
            text: 'three',
            duration: const Duration(seconds: 2),
          ),
        ],
      ),
    ];

Widget _wrap(Widget child) => MaterialApp(home: child);

void main() {
  testWidgets('renders the first story and reports it via onStoryShow',
      (tester) async {
    StoryItem? shown;
    await tester.pumpWidget(
      _wrap(StoryView(
        users: _users(),
        onStoryShow: (user, item, index) => shown = item,
      )),
    );
    await tester.pump();
    expect(find.text('one'), findsOneWidget);
    expect(shown?.id, 'a');
  });

  testWidgets('tapping the right side advances to the next story',
      (tester) async {
    final controller = StoryViewController();
    await tester.pumpWidget(
      _wrap(StoryView(users: _users(), controller: controller)),
    );
    await tester.pump();
    expect(controller.currentStoryIndex, 0);

    final size = tester.getSize(find.byType(StoryView));
    await tester.tapAt(Offset(size.width * 0.8, size.height * 0.5));
    await tester.pump();
    await tester.pump();

    expect(find.text('two'), findsOneWidget);
    expect(controller.currentStoryIndex, 1);
  });

  testWidgets('a text story completes automatically after its duration',
      (tester) async {
    var completed = 0;
    await tester.pumpWidget(
      _wrap(StoryView(
        users: _users(),
        onStoryComplete: (user, item, index) => completed++,
      )),
    );
    await tester.pump();
    // Advance past the 2s duration of the first story.
    await tester.pump(const Duration(seconds: 3));
    expect(completed, greaterThanOrEqualTo(1));
    expect(find.text('two'), findsOneWidget);
  });

  testWidgets('controller.next() forwards to the active page', (tester) async {
    final controller = StoryViewController();
    await tester.pumpWidget(
      _wrap(StoryView(users: _users(), controller: controller)),
    );
    await tester.pump();
    controller.next();
    await tester.pump();
    await tester.pump();
    expect(find.text('two'), findsOneWidget);
  });
}
