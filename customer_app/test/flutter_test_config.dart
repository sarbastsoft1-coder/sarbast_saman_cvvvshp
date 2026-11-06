import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The store shell loops a coin shimmer and a floating nav coin. Those
/// tickers never go idle, so `pumpAndSettle` cannot finish unless motion is
/// reduced the same way the widgets already do for the system setting.
Future<void> testExecutable(Future<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  await testMain();
}
