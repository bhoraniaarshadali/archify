import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_home_decor/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {

    // Build app with Firebase success state
    await tester.pumpWidget(const MyApp(firebaseError: false));

    // Allow first frame
    await tester.pump();

    // Verify MaterialApp loads
    expect(find.byType(MaterialApp), findsOneWidget);

  });

  testWidgets('Firebase error screen shows correctly', (WidgetTester tester) async {

    // Build app with Firebase failure state
    await tester.pumpWidget(const MyApp(firebaseError: true));

    await tester.pump();

    // Verify error UI
    expect(find.text('Service Unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);

  });
}
