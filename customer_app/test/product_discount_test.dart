import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/boutique/models/product.dart';
import 'package:customer_app/boutique/providers/cart_provider.dart';
import 'package:customer_app/boutique/widgets/product_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Vazirmatn')
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'));
    await font.load();
  });
  final product = BoutiqueProduct.fromApi({
    'id': 101,
    'name': 'Everyday woven tote',
    'price_fiat': 100,
    'sale_price_fiat': 75,
    'category': {'name': 'Handmade bags'},
    'store': {'name': 'The Artisan Studio'},
    'rating': 4.8,
  });

  test('API discount survives persistence and updates cart totals', () {
    expect(product.discountPercent, 25);
    expect(product.formatAmount(product.price), '\$75.00');
    expect(BoutiqueProduct.fromJson(product.toJson()).oldPrice, 100);
    final cart = CartProvider();
    cart.add(product, qty: 2);
    expect(cart.subtotal, 150);
    cart.syncProducts([
      BoutiqueProduct.fromApi({
        'id': 101,
        'name': 'Everyday woven tote',
        'price_fiat': 100,
        'sale_price_fiat': 100,
      }),
    ]);
    expect(cart.subtotal, 200);
    expect(cart.lines.first.product.hasDiscount, false);
    cart.dispose();
  });

  testWidgets('sale card fits narrow RTL cards and exposes price and savings', (
    tester,
  ) async {
    final key = GlobalKey();
    for (final width in [160.0, 220.0]) {
      for (final scale in [1.0, 1.4]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(fontFamily: 'Vazirmatn'),
            home: Scaffold(
              body: Center(
                child: RepaintBoundary(
                  key: key,
                  child: MediaQuery(
                    data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                    child: Directionality(
                      textDirection: TextDirection.rtl,
                      child: SizedBox(
                        width: width,
                        height: 300,
                        child: ProductCard(
                          product: product,
                          onTap: () {},
                          onToggleWishlist: () {},
                          onAddToBag: () {},
                          isWishlisted: false,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('−25%'), findsOneWidget);
        expect(find.text('\$75.00'), findsOneWidget);
        expect(find.text('\$100.00'), findsOneWidget);
      }
    }
    if (Platform.environment['CAPTURE_DISCOUNT_CARD'] == '1') {
      final boundary =
          key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('build/discount-preview').create(recursive: true);
        await File(
          'build/discount-preview/card.png',
        ).writeAsBytes(data!.buffer.asUint8List());
      });
    }
  });
}
