// Smoke tests for the redesigned EarthShop Artisan seller app.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:seller_app/main.dart';

void main() {
  testWidgets('App boots and renders without throwing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const EarthShopSellerApp());
    // First frame should mount without errors.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}