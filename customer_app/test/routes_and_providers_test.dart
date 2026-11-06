import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/boutique/core/routes/boutique_routes.dart';
import 'package:customer_app/boutique/models/product.dart';
import 'package:customer_app/boutique/providers/cart_provider.dart';
import 'package:customer_app/boutique/providers/catalog_provider.dart';
import 'package:customer_app/boutique/providers/navigation_provider.dart';
import 'package:customer_app/boutique/providers/orders_provider.dart';
import 'package:customer_app/boutique/providers/wishlist_provider.dart';

void main() {
  group('Boutique Navigation & Routing Tests', () {
    test('BoutiqueRoutes defines all required named routes', () {
      expect(BoutiqueRoutes.home, '/');
      expect(BoutiqueRoutes.products, '/products');
      expect(BoutiqueRoutes.productDetails, '/product-details');
      expect(BoutiqueRoutes.cart, '/cart');
      expect(BoutiqueRoutes.checkout, '/checkout');
      expect(BoutiqueRoutes.wishlist, '/wishlist');
      expect(BoutiqueRoutes.profile, '/profile');
      expect(BoutiqueRoutes.search, '/search');
      expect(BoutiqueRoutes.orders, '/orders');
      expect(BoutiqueRoutes.notifications, '/notifications');
    });

    test(
      'BoutiqueRoutes.onGenerateRoute creates valid Route for all endpoints',
      () {
        final routesToTest = [
          BoutiqueRoutes.home,
          BoutiqueRoutes.products,
          BoutiqueRoutes.cart,
          BoutiqueRoutes.checkout,
          BoutiqueRoutes.wishlist,
          BoutiqueRoutes.profile,
          BoutiqueRoutes.search,
          BoutiqueRoutes.orders,
          BoutiqueRoutes.notifications,
        ];

        for (final route in routesToTest) {
          final generated = BoutiqueRoutes.onGenerateRoute(
            RouteSettings(name: route),
          );
          expect(
            generated,
            isNotNull,
            reason: 'Failed to generate route for $route',
          );
        }

        // Test with arguments for product details
        final productRoute = BoutiqueRoutes.onGenerateRoute(
          RouteSettings(
            name: BoutiqueRoutes.productDetails,
            arguments: sampleProducts.first,
          ),
        );
        expect(productRoute, isNotNull);
      },
    );

    test(
      'BoutiqueNavProvider switches tabs and handles pending categories',
      () {
        final nav = BoutiqueNavProvider();
        expect(nav.currentIndex, 0);

        nav.switchTab(1, category: 'جانتا');
        expect(nav.currentIndex, 1);
        expect(nav.pendingCategory, 'جانتا');

        nav.clearPendingCategory();
        expect(nav.pendingCategory, isNull);

        nav.switchTab(3);
        expect(nav.currentIndex, 3);
      },
    );
  });

  group('Boutique Catalog & Filters Tests', () {
    test(
      'CatalogProvider filters by category, price range, and search query',
      () {
        final catalog = CatalogProvider();
        final all = sampleProducts;

        // Initial filter
        final initialFiltered = catalog.filter(all);
        expect(initialFiltered.length, all.length);

        // Category filter
        catalog.selectCategory('پێڵاو و جانتا');
        final bags = catalog.filter(all);
        expect(bags, isNotEmpty);
        for (final item in bags) {
          expect(item.category, 'پێڵاو و جانتا');
        }

        // Price filter
        catalog.clearFilters();
        catalog.setPriceRange(const RangeValues(0, 50000));
        final cheap = catalog.filter(all);
        for (final item in cheap) {
          expect(item.price <= 50000, isTrue);
        }

        // Search filter
        catalog.clearFilters();
        catalog.setQuery('كراسي');
        final searchRes = catalog.filter(all);
        expect(searchRes.isNotEmpty, isTrue);
      },
    );
  });

  group('Boutique Orders Provider Tests', () {
    test('OrdersProvider adds order and tracks status', () {
      final orders = OrdersProvider();
      final initialCount = orders.orders.length;

      orders.addOrder(
        items: [CartLine(product: sampleProducts.first, quantity: 2)],
        total: sampleProducts.first.price * 2,
        address: 'هەولێر',
        paymentMethod: 'cash',
      );

      expect(orders.orders.length, initialCount + 1);
      expect(orders.orders.first.status, OrderStatus.processing);
      expect(orders.orders.first.address, 'هەولێر');
    });
  });

  group('Boutique Cart & Wishlist Tests', () {
    test('CartProvider adds, updates quantity, and clears items', () {
      final cart = CartProvider();
      expect(cart.isEmpty, isTrue);

      cart.add(sampleProducts[0]);
      expect(cart.itemCount, 1);

      cart.add(sampleProducts[0]);
      expect(cart.itemCount, 2);

      cart.remove(sampleProducts[0].id);
      expect(cart.itemCount, 0);

      cart.clear();
      expect(cart.isEmpty, isTrue);
    });

    test('WishlistProvider toggles products', () {
      final wishlist = WishlistProvider();
      expect(wishlist.contains(sampleProducts[0].id), isFalse);

      wishlist.toggle(sampleProducts[0]);
      expect(wishlist.contains(sampleProducts[0].id), isTrue);

      wishlist.toggle(sampleProducts[0]);
      expect(wishlist.contains(sampleProducts[0].id), isFalse);
    });
  });
}
