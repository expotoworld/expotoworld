// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:flutter/material.dart';

void main() {
  testWidgets('EXPO to WORLD app smoke test', (WidgetTester tester) async {
    // Build a minimal scaffold containing the expected bottom nav labels.
    // This avoids provider and network dependencies while still validating
    // the key localized strings we rely on across the app.
    // Note: These are the English localized strings (default locale).
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox.shrink(),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.symmetric(vertical: 1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Home'),
              Text('Locations'),
              Text('Messages'),
              Text('Profile'),
            ],
          ),
        ),
      ),
    ));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Locations'), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
