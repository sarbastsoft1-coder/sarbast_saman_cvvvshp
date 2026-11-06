import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:delivery_app/main.dart';

void main() {
  testWidgets('App boots and renders without throwing',
      (WidgetTester tester) async {
    // The splash screen reads the stored token after a one second delay, so
    // SharedPreferences must be mocked or the platform channel throws.
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EarthShopDeliveryApp());
    // First frame should mount without errors.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the splash delay elapse so its timer does not outlive the test.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  });
}
