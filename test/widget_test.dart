// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unop/main.dart';

void main() {
  testWidgets('Enhanced Flutter App Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Check if the Home Screen is present.
    expect(find.text('Home Screen'), findsOneWidget);

    // Assuming there's a navigation item to go to a 'Profile' screen.
    await tester.tap(find.byIcon(Icons.account_circle));
    await tester.pumpAndSettle(); // Waits for the animation to complete.

    // Verify that the 'Profile' screen is displayed.
    expect(find.text('Profile Screen'), findsOneWidget);

    // Check for the presence of specific widgets on the 'Profile' screen.
    expect(find.byType(TextField), findsWidgets);
    expect(find.byType(ElevatedButton), findsWidgets);

    // Interact with a text field and enter some text.
    await tester.enterText(find.byType(TextField).first, 'Sample text');
    await tester.pump(); // Rebuild the widget with the new text.

    // Tap a button which might increment a counter or trigger an action.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump(); // Rebuild the widget after the button tap.

    // Verify that the action has taken effect (e.g., counter increment, new widget display, etc.)

    // Navigate back to the home screen.
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle(); // Waits for the animation to complete.

    // Final verification to ensure we're back on the home screen.
    expect(find.text('Home Screen'), findsOneWidget);
  });
}
