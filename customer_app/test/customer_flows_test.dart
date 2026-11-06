import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:customer_app/boutique/boutique_app.dart';
import 'package:customer_app/boutique/core/routes/boutique_routes.dart';
import 'package:customer_app/boutique/features/checkout/checkout_screen.dart';
import 'package:customer_app/boutique/features/orders/order_tracking_screen.dart';
import 'package:customer_app/boutique/features/search/search_screen.dart';
import 'package:customer_app/boutique/features/roni/splash_screen.dart';
import 'package:customer_app/boutique/features/orders/orders_screen.dart';
import 'package:customer_app/boutique/features/products/product_details_screen.dart';
import 'package:customer_app/boutique/models/coupon.dart';
import 'package:customer_app/boutique/models/product.dart';
import 'package:customer_app/boutique/providers/cart_provider.dart';
import 'package:customer_app/boutique/providers/catalog_provider.dart';
import 'package:customer_app/boutique/providers/customer_provider.dart';
import 'package:customer_app/boutique/providers/notifications_provider.dart';
import 'package:customer_app/boutique/providers/orders_provider.dart';
import 'package:customer_app/boutique/providers/recently_viewed_provider.dart';
import 'package:customer_app/boutique/providers/reviews_provider.dart';
import 'package:customer_app/boutique/providers/settings_provider.dart';
import 'package:customer_app/boutique/providers/wishlist_provider.dart';
import 'package:customer_app/boutique/core/constants/boutique_constants.dart';
import 'package:customer_app/boutique/widgets/main_shell.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = FontLoader('Vazirmatn')
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Vazirmatn-Bold.ttf'));
    await font.load();
  });
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Most tests exercise the app as a returning visitor. The one-time splash is
  /// covered separately by its own test below.
  setUp(
    () => SharedPreferences.setMockInitialValues({
      BoutiqueConstants.splashSeenKey: true,
    }),
  );

  test('free shipping is waived once and coupons reset with the cart', () {
    final cart = CartProvider()..add(sampleProducts.first);
    expect(cart.applyCouponCode(' freeship ').$1, isTrue);
    expect(cart.discountAmount, 0);
    expect(cart.effectiveDeliveryFee, 0);
    expect(cart.total, 45000);
    cart.clear();
    expect(cart.appliedCoupon, isNull);
    cart.add(sampleProducts.first);
    expect(cart.total, 48000);
  });

  test(
    'variants stay separate, quantity cannot be negative, discount revalidates',
    () {
      final cart = CartProvider();
      final product = sampleProducts[1];
      cart.add(product, size: 'S', qty: 2);
      cart.add(product, size: 'M');
      expect(cart.lines.length, 2);
      expect(cart.applyCouponCode('WELCOME20').$1, isTrue);
      cart.remove(cart.lines.last.key);
      cart.decrement(cart.lines.first.key);
      expect(cart.subtotal, 38000);
      expect(cart.appliedCoupon, isNull);
      cart.add(product, qty: -3);
      expect(cart.itemCount, 1);
      cart.add(product, qty: 1000, size: 'S');
      expect(cart.lines.single.quantity, 99);
    },
  );

  test('expired coupons and empty carts are rejected', () {
    final cart = CartProvider();
    expect(cart.applyCouponCode('WELCOME20').$1, isFalse);
    cart.add(sampleProducts.first);
    final coupon = BoutiqueCoupon(
      code: 'OLD',
      title: '',
      description: '',
      type: DiscountType.percentage,
      value: 30,
      expiryDate: '',
      expiresAt: DateTime(2020),
    );
    expect(cart.applyCoupon(coupon).$1, isFalse);
    expect(cart.total, 48000);
  });

  test(
    'cart, wishlist, recently viewed and reviews survive a restart',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final cart = CartProvider(preferences: prefs)
        ..add(sampleProducts.first, size: 'L', color: Colors.black, qty: 2);
      cart.applyCouponCode('WELCOME20');
      final wishlist = WishlistProvider(preferences: prefs)
        ..toggle(sampleProducts[2]);
      final recent = RecentlyViewedProvider(preferences: prefs)
        ..track(sampleProducts[4]);
      final reviews = ReviewsProvider(preferences: prefs)
        ..submit(
          productId: 2,
          name: 'Test',
          rating: 4,
          comment: 'A useful review.',
        );
      await Future.wait([
        cart.pendingSave,
        wishlist.pendingSave,
        recent.pendingSave,
        reviews.pendingSave,
      ]);
      final restored = CartProvider(preferences: prefs);
      expect(restored.lines.single.size, 'L');
      expect(restored.lines.single.quantity, 2);
      expect(restored.total, cart.total);
      expect(restored.appliedCoupon?.code, 'WELCOME20');
      expect(
        WishlistProvider(preferences: prefs).contains(sampleProducts[2].id),
        isTrue,
      );
      expect(
        RecentlyViewedProvider(preferences: prefs).items.single.id,
        sampleProducts[4].id,
      );
      expect(
        ReviewsProvider(preferences: prefs).forProduct(2).single.comment,
        'A useful review.',
      );
    },
  );

  test(
    'orders preserve contact, variants, discount and delivery after a restart',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final cart = CartProvider()..add(sampleProducts.first, qty: 2, size: 'L');
      cart.applyCouponCode('FREESHIP');
      final orders = OrdersProvider(preferences: prefs);
      final order = orders.addOrder(
        items: cart.lines,
        total: cart.total,
        deliveryFee: cart.effectiveDeliveryFee,
        discount: cart.discountAmount,
        address: 'Erbil, test street 20',
        phone: '07501234567',
        paymentMethod: 'cash',
      );
      cart.clear();
      await orders.pendingSave;
      final restored = OrdersProvider(preferences: prefs).byId(order.id)!;
      expect(restored.total, 90000);
      expect(restored.deliveryFee, 0);
      expect(restored.phone, '07501234567');
      expect(restored.items.single.size, 'L');
      expect(restored.items.single.quantity, 2);
      expect(restored.trackingStep, 0);
      expect(restored.courierPhone, isEmpty);
      expect(
        () => orders.addOrder(
          items: [],
          total: 0,
          address: '',
          paymentMethod: 'cash',
        ),
        throwsArgumentError,
      );
    },
  );

  test('address updates and default selection persist', () async {
    final prefs = await SharedPreferences.getInstance();
    final customer = CustomerProvider(preferences: prefs);
    customer.updateName(' Test Customer ');
    customer.saveAddress(
      const CustomerAddress(
        id: 'home',
        label: 'Home',
        address: 'Erbil, street 20',
        phone: '07501234567',
      ),
    );
    customer.saveAddress(
      const CustomerAddress(
        id: 'work',
        label: 'Work',
        address: 'Erbil, street 25',
        phone: '07501234567',
      ),
    );
    customer.makeDefault('work');
    customer.removeAddress('home');
    await customer.pendingSave;
    final restored = CustomerProvider(preferences: prefs);
    expect(restored.name, 'Test Customer');
    expect(restored.addresses.length, 1);
    expect(restored.defaultAddress!.id, 'work');
    expect(validatePhone('٠٧٥٠ ١٢٣ ٤٥٦٧'), isNull);
    expect(validatePhone('+964 750 123 4567'), isNull);
    expect(validatePhone('123'), isNotNull);
    expect(validatePhone('abc'), isNotNull);
  });

  test(
    'notification preferences change the feed and read status persists',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final settings = SettingsProvider();
      final notifications = NotificationsProvider(preferences: prefs);
      expect(notifications.byId(999), isNull);
      await settings.setPromoUpdates(false);
      expect(
        notifications
            .visibleItems(settings)
            .any((n) => n.type == BoutiqueNotificationType.promo),
        isFalse,
      );
      await settings.setNotificationsEnabled(false);
      expect(notifications.visibleItems(settings), isEmpty);
      await settings.setNotificationsEnabled(true);
      expect(settings.orderUpdates, isTrue);
      expect(settings.promoUpdates, isFalse);
      notifications.markAllAsRead();
      // With no api the provider is offline, so nothing is unread.
      expect(notifications.unreadCount, 0);
      expect(NotificationsProvider(preferences: prefs).unreadCount, 0);
    },
  );

  test('catalog normalizes Arabic and Kurdish letter forms', () {
    final catalog = CatalogProvider()..setQuery('كلاسيك');
    expect(catalog.filter(sampleProducts).map((p) => p.id), contains(1));
    catalog.selectCategory('پێڵاو');
    expect(catalog.filter(sampleProducts), isEmpty);
    catalog.clearFilters();
    expect(catalog.filter(sampleProducts).length, sampleProducts.length);
  });

  test(
    'entity routes include IDs so browser refresh retains the destination',
    () {
      final product = BoutiqueRoutes.onGenerateRoute(
        RouteSettings(
          name: '/product-details',
          arguments: sampleProducts.first,
        ),
      );
      expect(product.settings.name, '/product-details?id=1');
      final order = BoutiqueRoutes.onGenerateRoute(
        const RouteSettings(
          name: '/order-tracking',
          arguments: {'orderId': 'ORD-9412'},
        ),
      );
      expect(order.settings.name, '/order-tracking?id=ORD-9412');
      final notification = BoutiqueRoutes.onGenerateRoute(
        const RouteSettings(name: '/notification-detail', arguments: 2),
      );
      expect(notification.settings.name, '/notification-detail?id=2');
    },
  );

  testWidgets('product selections reach the cart and the bag shortcut works', (
    tester,
  ) async {
    await tester.pumpWidget(
      BoutiqueApp(catalogLoader: () async => sampleProducts),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(BoutiqueMainShell));
    final cart = context.read<CartProvider>();
    Navigator.of(context).pushNamed('/product-details?id=2');
    await tester.pumpAndSettle();
    final scrollable = find
        .descendant(
          of: find.byType(ProductDetailsScreen),
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byKey(const Key('size-L')),
      200,
      scrollable: scrollable,
    );
    await tester.tap(find.byKey(const Key('size-L')));
    await tester.tap(find.byKey(const Key('color-1')));
    await tester.tap(find.byKey(const Key('add-selected-product')));
    await tester.pumpAndSettle();
    expect(cart.lines.single.size, 'L');
    expect(cart.lines.single.color, sampleProducts[1].availableColors[1]);
    await tester.tap(find.byTooltip('سەبەتەکەم'));
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsNothing);
    expect(find.byKey(const Key('checkout-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('web deep links restore a product directly', (tester) async {
    tester.binding.platformDispatcher.defaultRouteNameTestValue =
        '/product-details?id=1';
    addTearDown(
      tester.binding.platformDispatcher.clearDefaultRouteNameTestValue,
    );
    await tester.pumpWidget(
      BoutiqueApp(catalogLoader: () async => sampleProducts),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ProductDetailsScreen), findsOneWidget);
    expect(
      tester
          .widget<ProductDetailsScreen>(find.byType(ProductDetailsScreen))
          .product
          .id,
      1,
    );
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('customer routes and tabs render at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        BoutiqueApp(
          preferences: prefs,
          catalogLoader: () async => sampleProducts,
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'home at $width');
      final context = tester.element(find.byType(BoutiqueMainShell));
      context.read<CartProvider>().add(sampleProducts.first);
      context.read<WishlistProvider>().add(sampleProducts.first);
      final nav = Navigator.of(tester.element(find.byType(BoutiqueMainShell)));
      final routes = <String, Object?>{
        '/products': null,
        '/wishlist': null,
        '/cart': null,
        '/profile': null,
        '/product-details': sampleProducts[1],
        '/checkout': null,
        '/orders': null,
        '/order-tracking': {'orderId': 'ORD-9412'},
        '/notifications': null,
        '/notification-detail': {'id': 2},
        '/recently-viewed': null,
        '/write-review': sampleProducts.first,
        '/search': null,
        '/settings': null,
        '/addresses': null,
        '/help': null,
        '/missing': null,
        '/order-tracking?id=missing': null,
      };
      for (final route in routes.entries) {
        nav.pushNamed(route.key, arguments: route.value);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${route.key} at $width',
        );
        nav.pop();
        await tester.pumpAndSettle();
      }
      // Route factory must also reject missing/malformed arguments safely.
      for (final route in [
        '/product-details',
        '/write-review',
        '/order-tracking',
        '/notification-detail',
      ]) {
        nav.pushNamed(route, arguments: 99.5);
        await tester.pumpAndSettle();
        expect(find.byType(MissingRouteScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        nav.pop();
        await tester.pumpAndSettle();
      }
    });
  }

  testWidgets(
    'checkout validates input and creates one order with selected variants',
    (tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        BoutiqueApp(preferences: await SharedPreferences.getInstance()),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(BoutiqueMainShell));
      final cart = context.read<CartProvider>()
        ..add(sampleProducts.first, size: 'L', qty: 2);
      cart.applyCouponCode('FREESHIP');
      final orders = context.read<OrdersProvider>();
      final before = orders.orders.length;
      Navigator.of(context).pushNamed('/checkout');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('confirm-order')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-order')));
      await tester.pumpAndSettle();
      expect(orders.orders.length, before);
      await tester.enterText(
        find.byKey(const Key('checkout-address')),
        'هەولێر، شەقامی تاقیکردنەوە ٢٠',
      );
      await tester.enterText(
        find.byKey(const Key('checkout-phone')),
        '٠٧٥٠١٢٣٤٥٦٧',
      );
      await tester.ensureVisible(find.byKey(const Key('confirm-order')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('confirm-order')));
      await tester.pumpAndSettle();
      expect(find.byType(CheckoutScreen), findsNothing);
      expect(find.byType(OrderTrackingScreen), findsOneWidget);
      expect(orders.orders.length, before + 1);
      expect(orders.orders.first.phone, '07501234567');
      expect(orders.orders.first.items.single.size, 'L');
      expect(orders.orders.first.total, 90000);
      expect(cart.isEmpty, isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'search categories return results with an empty query and do not leak filters',
    (tester) async {
      await tester.pumpWidget(
        BoutiqueApp(catalogLoader: () async => sampleProducts),
      );
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(BoutiqueMainShell));
      final catalog = context.read<CatalogProvider>()
        ..selectCategory('جوانکاری');
      Navigator.of(context).pushNamed('/search');
      await tester.pumpAndSettle();
      expect(find.byType(SearchScreen), findsOneWidget);
      await tester.tap(find.widgetWithText(ChoiceChip, 'جانتاکان'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<SearchResultRow>(find.byType(SearchResultRow))
            .every((w) => w.product.category == 'جانتاکان'),
        isTrue,
      );
      expect(find.byType(SearchResultRow), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('product-search')),
        'no matching item',
      );
      await tester.pumpAndSettle();
      expect(find.byType(SearchResultRow), findsNothing);
      expect(catalog.category, 'جوانکاری');
      expect(catalog.query, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('the Roni splash shows once, then hands over to the store', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      BoutiqueApp(
        preferences: prefs,
        catalogLoader: () async => sampleProducts,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(prefs.getBool(BoutiqueConstants.splashSeenKey), isTrue);

    await tester.tap(find.text('دەست پێبکە'));
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(BoutiqueMainShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a returning visitor goes straight to the store', (tester) async {
    SharedPreferences.setMockInitialValues({
      BoutiqueConstants.splashSeenKey: true,
    });
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      BoutiqueApp(
        preferences: prefs,
        catalogLoader: () async => sampleProducts,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(BoutiqueMainShell), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the five Roni tabs are reachable from the bottom bar', (
    tester,
  ) async {
    await tester.pumpWidget(
      BoutiqueApp(catalogLoader: () async => sampleProducts),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('nav-0')), findsOneWidget);
    expect(find.byKey(const Key('nav-4')), findsOneWidget);

    // Orders is tab 3 in the Roni information architecture.
    await tester.tap(find.byKey(const Key('nav-3')));
    await tester.pumpAndSettle();
    expect(find.byType(OrdersScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
