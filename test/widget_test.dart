// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:magical_community/main.dart';

void main() {
  testWidgets('App boots to SplashScreen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify Splash content is present immediately.
    expect(find.text('Magical Community'), findsOneWidget);
    expect(find.text('Loading...'), findsOneWidget);

    // Let the splash timer (2s) elapse so there are no pending timers.
    await tester.pump(const Duration(seconds: 3));

    // App should still be mounted without throwing; MaterialApp remains.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
