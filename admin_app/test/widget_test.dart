import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:admin_app/main.dart';

void main() {
  testWidgets('App boots and renders without throwing',
      (WidgetTester tester) async {
    // No stored token, so the splash settles on the login screen instead of
    // opening a session (and starting the notification poller).
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const EarthShopAdminApp());
    // First frame should mount without errors.
    expect(find.byType(MaterialApp), findsOneWidget);

    // Let the splash hand over, so no timer is left pending at teardown.
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('Admin Portal Login'), findsOneWidget);
  });
}
