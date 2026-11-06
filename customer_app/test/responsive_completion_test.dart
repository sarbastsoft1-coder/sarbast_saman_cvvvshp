import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:customer_app/boutique/boutique_app.dart';
import 'package:customer_app/boutique/models/product.dart';
import 'package:customer_app/boutique/providers/cart_provider.dart';
import 'package:customer_app/boutique/providers/wishlist_provider.dart';
import 'package:customer_app/boutique/providers/navigation_provider.dart';
import 'package:customer_app/boutique/services/commerce_api.dart';
import 'package:customer_app/boutique/widgets/main_shell.dart';

import 'support/settle.dart';

/// Renders every customer destination at ten viewport sizes with a 1.2x text
/// scale and asserts that nothing overflows its box.
///
/// The pump strategy is bounded rather than `pumpAndSettle`: the storefront
/// runs ambient animations that never end (bottom-nav coin float, carousel
/// auto-advance, flash-deal pulse), so settling to quiescence always times out
/// and reports a false failure instead of a layout defect.
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
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(844, 390),
    const Size(600, 960),
    const Size(320, 700),
    const Size(768, 1024),
    const Size(820, 1180),
    const Size(1024, 768),
    const Size(1366, 1024),
  ]) {
    testWidgets('all customer destinations at $size', (tester) async {
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
      final captureKey = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: captureKey,
          child: BoutiqueApp(
            api: api,
            catalogLoader: () async => sampleProducts,
          ),
        ),
      );
      await settle(tester);
      if (const bool.fromEnvironment('CAPTURE_LAYOUTS') &&
          (size.width == 390 || size.width == 820)) {
        final boundary =
            captureKey.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final png = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/layout-review').create(recursive: true);
          await File(
            'build/layout-review/home-${size.width.toInt()}.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          image.dispose();
        });
      }
      final context = tester.element(find.byType(BoutiqueMainShell));
      context.read<CartProvider>().add(sampleProducts[1], size: 'M', qty: 2);
      context.read<WishlistProvider>().toggle(sampleProducts[1]);
      for (var tab = 0; tab < 5; tab++) {
        context.read<BoutiqueNavProvider>().switchTab(tab);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: 'tab $tab at $size');
        final pageScroll = find.byType(Scrollable);
        if (pageScroll.evaluate().isNotEmpty) {
          await tester.drag(pageScroll.first, const Offset(0, -650));
          await settle(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: 'tab $tab scrolled at $size',
          );
        }
      }
      final nav = Navigator.of(context);
      for (final route in [
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
      ]) {
        nav.pushNamed(route);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: '$route at $size');
        if (route == '/checkout') {
          tester.view.viewInsets = FakeViewPadding(
            bottom: size.height > 500 ? 280 : 150,
          );
          await settle(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: 'checkout keyboard at $size',
          );
          tester.view.resetViewInsets();
          await settle(tester);
        }
        final scrolls = find.byType(Scrollable);
        if (scrolls.evaluate().isNotEmpty) {
          await tester.drag(scrolls.first, const Offset(0, -550));
          await settle(tester);
          expect(
            tester.takeException(),
            isNull,
            reason: '$route scrolled at $size',
          );
        }
        nav.pop();
        await settle(tester);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
