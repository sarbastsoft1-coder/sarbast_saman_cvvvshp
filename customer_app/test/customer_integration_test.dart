import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:customer_app/boutique/models/product.dart';
import 'package:customer_app/boutique/providers/cart_provider.dart';
import 'package:customer_app/boutique/providers/checkout_provider.dart';
import 'package:customer_app/boutique/providers/coins_provider.dart';
import 'package:customer_app/boutique/providers/notifications_provider.dart';
import 'package:customer_app/boutique/services/commerce_api.dart';

void main() {
  test('wallet loads authenticated server balance and redemption', () async {
    final requests = <http.Request>[];
    final api = CommerceApi(
      client: MockClient((request) async {
        requests.add(request);
        return http.Response(
          jsonEncode({
            'data': {
              'balance': 275,
              'earned': 300,
              'spent': 25,
              'transactions': [
                {'amount': -25, 'description': 'Reward'},
              ],
              'rewards': [],
              'redemptions': [],
            },
          }),
          200,
        );
      }),
    )..useToken('customer-token');
    final coins = CoinsProvider(api: api);
    addTearDown(coins.dispose);
    addTearDown(api.dispose);
    await coins.refresh();
    expect(coins.balance, 275);
    expect(coins.history.single.amount, -25);
    expect(await coins.redeemReward(7), isTrue);
    expect(
      requests.every(
        (r) => r.headers['Authorization'] == 'Bearer customer-token',
      ),
      isTrue,
    );
    expect(
      requests.any((r) => r.url.path.endsWith('/rewards/7/redeem')),
      isTrue,
    );
    api.useToken(null);
    await coins.refresh();
    expect(coins.balance, 0);
    expect(coins.history, isEmpty);
  });

  test('notification response from a previous session is discarded', () async {
    final response = Completer<http.Response>();
    final api = CommerceApi(client: MockClient((_) => response.future));
    final notifications = NotificationsProvider(api: api);
    addTearDown(notifications.dispose);
    addTearDown(api.dispose);
    final pending = notifications.refresh();
    notifications.reset();
    response.complete(
      http.Response(
        jsonEncode({
          'data': [
            {
              'id': 1,
              'title': 'Old account',
              'body': 'Private',
              'type': 'system',
            },
          ],
          'latest_id': 1,
        }),
        200,
      ),
    );
    await pending;
    expect(notifications.items, isEmpty);
    expect(notifications.loading, isFalse);
  });

  test('checkout preserves authoritative order identity and totals', () async {
    final api = CommerceApi(
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'order': {
              'id': 42,
              'order_number': 'SHOP-42',
              'total_fiat': 22.5,
              'discount_amount': 2,
              'delivery_fee': 3,
              'shipping_address': 'Server address',
            },
          }),
          200,
        ),
      ),
    )..useToken('token');
    final checkout = CheckoutProvider(api: api);
    final cart = CartProvider()..add(sampleProducts.first);
    addTearDown(api.dispose);
    addTearDown(checkout.dispose);
    addTearDown(cart.dispose);
    expect(
      await checkout.placeOrder(
        cart: cart,
        address: 'Address',
        phone: '07501234567',
      ),
      CheckoutOutcome.placed,
    );
    expect(checkout.placedOrder?.orderNumber, 'SHOP-42');
    expect(checkout.placedOrder?.total, 22.5);
  });

  test('a slower quote cannot replace a newer coupon quote', () async {
    final replies = <Completer<http.Response>>[];
    final api = CommerceApi(
      client: MockClient((_) {
        final reply = Completer<http.Response>();
        replies.add(reply);
        return reply.future;
      }),
    )..useToken('token');
    final checkout = CheckoutProvider(api: api);
    final cart = CartProvider()..add(sampleProducts.first);
    addTearDown(api.dispose);
    addTearDown(checkout.dispose);
    addTearDown(cart.dispose);
    final first = checkout.refreshQuote(cart, couponCode: 'OLD');
    await Future<void>.delayed(Duration.zero);
    final second = checkout.refreshQuote(cart, couponCode: 'NEW');
    await Future<void>.delayed(Duration.zero);
    http.Response quote(String code, int total) => http.Response(
      jsonEncode({
        'data': {
          'lines': [],
          'total_fiat': total,
          'coupon': {'code': code},
        },
      }),
      200,
    );
    replies[1].complete(quote('NEW', 20));
    await second;
    replies[0].complete(quote('OLD', 40));
    await first;
    expect(checkout.quote?.total, 20);
    expect(checkout.couponCode, 'NEW');
  });
}
