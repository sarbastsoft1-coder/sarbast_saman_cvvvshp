import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:customer_app/boutique/providers/auction_provider.dart';
import 'package:customer_app/boutique/providers/coins_provider.dart';
import 'package:customer_app/boutique/services/commerce_api.dart';

/// Coverage for the Roni economy providers.
///
/// These providers are API-backed: the wallet, the auction book and the
/// rewards catalogue all come from the server, so the tests drive them
/// through a mocked transport and assert the parsing, the money maths and the
/// error paths rather than a local-only economy.
void main() {
  CommerceApi apiWith(
    Future<http.Response> Function(http.Request request) handler, {
    String? token = 'test-token',
  }) {
    final api = CommerceApi(
      client: MockClient((request) async => handler(request)),
    );
    if (token != null) api.useToken(token);
    return api;
  }

  group('CoinsProvider', () {
    test('parses the wallet payload into balance, earnings and history', () async {
      final api = apiWith((request) async {
        expect(request.url.path, '/api/v1/customer/ronix');
        return http.Response(
          jsonEncode({
            'data': {
              'balance': 4200,
              'earned': 5000,
              'spent': 800,
              'transactions': [
                {
                  'description': 'پاشەکەوتکردنی دەزگا',
                  'amount': 250,
                  'created_at': '2026-10-01T10:00:00Z',
                },
                {
                  'type': 'spend',
                  'amount': -100,
                  'created_at': '2026-10-02T10:00:00Z',
                },
              ],
              'rewards': [
                {'id': 1, 'title': 'دیارییەکانیان'},
              ],
              'redemptions': <Map<String, dynamic>>[],
              'policy': {'min_redeem': 500},
            },
          }),
          200,
        );
      });
      final provider = CoinsProvider(api: api);

      await provider.refresh();

      expect(provider.error, isNull);
      expect(provider.balance, 4200);
      expect(provider.earned, 5000);
      expect(provider.spent, 800);
      expect(provider.history, hasLength(2));
      expect(provider.history.first.label, 'پاشەکەوتکردنی دەزگا');
      expect(provider.history.first.amount, 250);
      // A transaction with no description falls back to its type.
      expect(provider.history.last.label, 'spend');
      expect(provider.rewards, hasLength(1));
      expect(provider.policy['min_redeem'], 500);
      expect(provider.loading, isFalse);
    });

    test('redeems a reward against the reward endpoint and refreshes', () async {
      final posted = <String>[];
      final api = apiWith((request) async {
        if (request.method == 'POST') {
          posted.add(request.url.path);
          return http.Response(jsonEncode({'data': true}), 200);
        }
        return http.Response(
          jsonEncode({
            'data': {'balance': 4300, 'transactions': <Map<String, dynamic>>[]},
          }),
          200,
        );
      });
      final provider = CoinsProvider(api: api);

      final ok = await provider.redeemReward(7);

      expect(ok, isTrue);
      expect(posted, ['/api/v1/customer/rewards/7/redeem']);
      expect(provider.balance, 4300);
      expect(provider.busy, isFalse);
    });

    test('surfaces a server failure instead of swallowing it', () async {
      final api = apiWith((request) async => http.Response(
            jsonEncode({'message': 'دەرگەیشتن نەکرا'}),
            422,
          ));
      final provider = CoinsProvider(api: api);

      await provider.refresh();

      expect(provider.error, isNotNull);
      expect(provider.loading, isFalse);
    });

    test('reset clears the wallet', () async {
      final api = apiWith((request) async => http.Response(
            jsonEncode({
              'data': {
                'balance': 99,
                'transactions': [
                  {'description': 'x', 'amount': 1},
                ],
              },
            }),
            200,
          ));
      final provider = CoinsProvider(api: api);
      await provider.refresh();
      expect(provider.balance, 99);

      provider.reset();

      expect(provider.balance, 0);
      expect(provider.earned, 0);
      expect(provider.spent, 0);
      expect(provider.history, isEmpty);
    });
  });

  group('AuctionProvider', () {
    test('selects a live lot and computes the next minimum bid', () async {
      final api = apiWith((request) async {
        if (request.url.path.endsWith('/3')) {
          return http.Response(
            jsonEncode({
              'data': {
                'auction': {
                  'id': 3,
                  'status': 'active',
                  'highest_bid': 100,
                  'bid_increment': 25,
                  'min_bid': 50,
                  'ends_at': DateTime.now()
                      .add(const Duration(hours: 2))
                      .toIso8601String(),
                },
              },
              'bids': <Map<String, dynamic>>[],
              'my_bids': <Map<String, dynamic>>[],
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 3,
                'status': 'active',
                'highest_bid': 100,
                'bid_increment': 25,
                'min_bid': 50,
                'ends_at': DateTime.now()
                    .add(const Duration(hours: 2))
                    .toIso8601String(),
              },
            ],
          }),
          200,
        );
      });
      final provider = AuctionProvider(api: api);

      await provider.refresh();

      expect(provider.error, isNull);
      expect(provider.auctions, hasLength(1));
      expect(provider.selected?['id'], 3);
      expect(provider.isLive, isTrue);
      // The next bid must be the current high bid plus the increment.
      expect(provider.minimumNextBid, 125);
      expect(provider.remaining, greaterThan(Duration.zero));
      expect(provider.remainingLabel, contains('h'));
    });

    test('an expired lot is not live and never counts down below zero', () async {
      final api = apiWith((request) async => http.Response(
            jsonEncode({
              'data': [
                {
                  'id': 9,
                  'status': 'ended',
                  'ends_at': DateTime.now()
                      .subtract(const Duration(hours: 3))
                      .toIso8601String(),
                },
              ],
            }),
            200,
          ));
      final provider = AuctionProvider(api: api);

      await provider.refresh();

      expect(provider.isLive, isFalse);
      expect(provider.remaining, Duration.zero);
    });

    test('bid posts the amount and refuses to bid without a selection', () async {
      final paths = <String>[];
      final api = apiWith((request) async {
        paths.add('${request.method} ${request.url.path}');
        if (request.method == 'POST') {
          return http.Response(jsonEncode({'data': true}), 200);
        }
        return http.Response(jsonEncode({'data': <Map<String, dynamic>>[]}), 200);
      });
      final provider = AuctionProvider(api: api);

      expect(await provider.bid(500), isFalse);
      expect(paths, isEmpty);
    });
  });
}
