import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/boutique/boutique_app.dart';
import 'package:customer_app/boutique/models/product.dart';
import 'package:customer_app/boutique/providers/cart_provider.dart';
import 'package:customer_app/boutique/providers/navigation_provider.dart';
import 'package:customer_app/boutique/providers/wishlist_provider.dart';
import 'package:customer_app/boutique/services/commerce_api.dart';
import 'package:customer_app/boutique/widgets/main_shell.dart';

import 'support/settle.dart';

/// Layout audit harness.
///
/// Renders every customer destination at several viewport sizes and collects
/// **all** layout exceptions instead of stopping at the first one, so a single
/// run lists every overflow site in the app with its source location.
///
/// Run with:
///   flutter test test/layout_audit_test.dart --no-pub
///
/// The summary is written to `build/layout-audit.txt` and printed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    await (FontLoader('Vazirmatn')
          ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf')))
        .load();
  });

  const sizes = [
    Size(320, 568),
    Size(390, 844),
    Size(844, 390),
  ];

  const routes = [
    '/cart',
    '/checkout',
    '/product-details?id=2',
    '/wishlist',
    '/search',
    '/addresses',
    '/auth',
    '/settings',
    '/help',
    '/coins',
    '/auction',
    '/coin-shop',
    '/membership',
    '/gives',
    '/notifications',
    '/recently-viewed',
    '/write-review?id=1',
    '/splash',
    '/deals',
    '/challenges',
    '/winners',
    '/how',
    '/invite',
    '/chats',
    '/store?id=1',
    '/orders',
    '/profile',
    '/products',
  ];

  final findings = <String, Set<String>>{};

  for (final size in sizes) {
    testWidgets('audit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1.2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 34);
      addTearDown(tester.view.resetPadding);

      final api = CommerceApi(
        client: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'data': request.url.path.endsWith('/auctions') ? [] : {},
              'notifications': [],
              'latest_id': 0,
            }),
            200,
          ),
        ),
      );
      addTearDown(api.dispose);

      await tester.pumpWidget(
        BoutiqueApp(api: api, catalogLoader: () async => sampleProducts),
      );
      await settle(tester);

      void collect(String where) {
        Object? error;
        while ((error = tester.takeException()) != null) {
          final text = error.toString();
          final source = RegExp(
            r'file:///C:[^\s]+?\.dart:\d+:\d+',
          ).firstMatch(text)?.group(0) ?? 'unknown';
          final short = text.split('\n').first;
          findings.putIfAbsent(source, () => <String>{}).add('$where :: $short');
        }
      }

      final context = tester.element(find.byType(BoutiqueMainShell));
      context.read<CartProvider>().add(sampleProducts[1], size: 'M', qty: 2);
      context.read<WishlistProvider>().toggle(sampleProducts[1]);

      for (var tab = 0; tab < 5; tab++) {
        context.read<BoutiqueNavProvider>().switchTab(tab);
        await settle(tester);
        collect('tab $tab');
        final scrolls = find.byType(Scrollable);
        if (scrolls.evaluate().isNotEmpty) {
          await tester.drag(scrolls.first, const Offset(0, -600));
          await settle(tester);
          collect('tab $tab scrolled');
        }
      }

      final nav = Navigator.of(context);
      for (final route in routes) {
        nav.pushNamed(route);
        await settle(tester);
        collect(route);
        final scrolls = find.byType(Scrollable);
        if (scrolls.evaluate().isNotEmpty) {
          await tester.drag(scrolls.first, const Offset(0, -500));
          await settle(tester);
          collect('$route scrolled');
        }
        nav.pop();
        await settle(tester);
      }

      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  tearDownAll(() async {
    final buffer = StringBuffer();
    buffer.writeln('LAYOUT AUDIT — ${findings.length} distinct failure sites');
    buffer.writeln('=' * 70);
    final keys = findings.keys.toList()..sort();
    for (final key in keys) {
      buffer.writeln();
      buffer.writeln('### $key');
      final entries = findings[key]!.toList()..sort();
      for (final entry in entries.take(4)) {
        buffer.writeln(entry.length > 320 ? '${entry.substring(0, 320)}…' : entry);
      }
    }
    await Directory('build').create(recursive: true);
    await File('build/layout-audit.txt').writeAsString(buffer.toString());
    // ignore: avoid_print
    print(buffer.toString());
  });
}
