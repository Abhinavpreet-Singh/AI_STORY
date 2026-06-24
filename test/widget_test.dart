import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_story_buddy/screens/story_buddy_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    dotenv.testLoad(
      fileInput:
          'ELEVENLABS_API_KEY=test_key\nELEVENLABS_VOICE_ID=test_voice\n',
    );
  });

  testWidgets('App loads with story content', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: StoryBuddyScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('AI Story Buddy'), findsOneWidget);
    expect(find.text('Read Me a Story'), findsOneWidget);
    expect(find.text('Pip and the Whispering Woods'), findsOneWidget);
  });
}
