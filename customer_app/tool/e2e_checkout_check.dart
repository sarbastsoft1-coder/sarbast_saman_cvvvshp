// Integration check: drives the real CommerceApi against the running Laravel
// server, proving the customer app can register, price, and check out for real.
import 'dart:io';

import 'package:customer_app/boutique/services/commerce_api.dart';

Future<void> main() async {
  final api = CommerceApi();
  var failures = 0;

  void check(String label, bool ok, [String detail = '']) {
    stdout.writeln(
      '${ok ? "PASS" : "FAIL"}  $label${detail.isEmpty ? "" : "  -> $detail"}',
    );
    if (!ok) failures++;
  }

  try {
    // 1. register
    final email =
        'e2e${DateTime.now().millisecondsSinceEpoch}@example.com';
    final session = await api.register(
      name: 'E2E Customer',
      email: email,
      password: 'secret1234',
      passwordConfirmation: 'secret1234',
      phone: '07501234567',
    );
    check('register returns a token', session.token.isNotEmpty);
    check('register returns the user name', session.name == 'E2E Customer',
        session.name);

    api.useToken(session.token);

    // 2. catalog
    final products = await api.products();
    check('catalog loads from the server', products.isNotEmpty,
        '${products.length} products');
    final first = products.first;
    final productId = (first['id'] as num).toInt();
    stdout.writeln('      using product #$productId "${first['name']}"');

    // 3. server-authoritative quote
    final quote = await api.quote(items: [
      (productId: productId, quantity: 2),
    ]);
    check('quote returns priced lines', quote.lines.isNotEmpty);
    final expectedSubtotal = quote.lines.first.unitPrice * 2;
    check(
      'quote subtotal equals unit price x quantity',
      (quote.subtotal - expectedSubtotal).abs() < 0.01,
      'subtotal=${quote.subtotal} expected=$expectedSubtotal',
    );
    check(
      'total = subtotal - discount + delivery',
      (quote.total - (quote.subtotal - quote.discount + quote.deliveryFee))
              .abs() <
          0.01,
      'total=${quote.total}',
    );

    // 4. coupons
    final coupons = await api.coupons();
    check('coupon list is populated', coupons.isNotEmpty,
        '${coupons.length} active');
    final welcome = coupons.firstWhere(
      (c) => c['code'] == 'WELCOME10',
      orElse: () => <String, dynamic>{},
    );
    if (welcome.isNotEmpty) {
      final discounted = await api.quote(
        items: [(productId: productId, quantity: 2)],
        couponCode: 'WELCOME10',
      );
      check('WELCOME10 reduces the total',
          discounted.total < quote.total,
          '${discounted.total} < ${quote.total}');
      check('WELCOME10 is reported back',
          discounted.couponCode == 'WELCOME10');
    }

    // 5. expired coupon is refused
    final expired = await api.quote(
      items: [(productId: productId, quantity: 1)],
      couponCode: 'EXPIRED',
    );
    check('expired coupon is rejected with a reason',
        expired.couponCode == null && expired.couponError != null,
        expired.couponError ?? '(none)');

    // 6. addresses
    final saved = await api.saveAddress(
      label: 'home',
      address: 'Hulwsh, Mahalla 90, Building 4',
      phone: '07501234567',
      isDefault: true,
    );
    check('address is saved and default', saved.isDefault, 'id=${saved.id}');
    final addresses = await api.addresses();
    check('address list contains it',
        addresses.any((a) => a.id == saved.id));

    // 7. stock before / after a real checkout
    final beforeStock = (first['stock'] as num?)?.toInt() ?? 0;

    // Re-quote with the same coupon the order will use, so the comparison is
    // against the priced basket that was actually submitted.
    final discountedQuote = await api.quote(
      items: [(productId: productId, quantity: 2)],
      couponCode: 'WELCOME10',
    );

    final order = await api.checkout(
      items: [(productId: productId, quantity: 2)],
      shippingAddress: 'Hulwsh, Mahalla 90, Building 4',
      phone: '07501234567',
      addressId: saved.id,
      couponCode: 'WELCOME10',
    );
    check('order is created with a number', order.orderNumber.isNotEmpty,
        order.orderNumber);
    check(
      'order total equals the server quote for the same basket',
      (order.total - discountedQuote.total).abs() < 0.01,
      'order=${order.total} quote=${discountedQuote.total}',
    );
    check('order records the discount', order.discount > 0,
        'discount=${order.discount}');

    final productsAfter = await api.products();
    final afterStock = (productsAfter
            .firstWhere((p) => (p['id'] as num).toInt() == productId)['stock']
        as num)
        .toInt();
    check('stock decreased by the ordered quantity',
        afterStock == beforeStock - 2,
        '$beforeStock -> $afterStock');

    // 8. orders list
    final orders = await api.orders();
    check('order appears in the account history',
        orders.any((o) => o.orderNumber == order.orderNumber));

    // 9. cancel restores stock
    await api.cancelOrder(order.id, reason: 'e2e cleanup');
    final productsAfterCancel = await api.products();
    final restoredStock = (productsAfterCancel
            .firstWhere((p) => (p['id'] as num).toInt() == productId)['stock']
        as num)
        .toInt();
    check('cancelling restores the stock', restoredStock == beforeStock,
        '$afterStock -> $restoredStock');

    // 10. cancelling twice is refused
    var doubleCancelRefused = false;
    try {
      await api.cancelOrder(order.id);
    } on CommerceException {
      doubleCancelRefused = true;
    }
    check('a cancelled order cannot be cancelled again', doubleCancelRefused);

    // 11. an invalid token is rejected
    api.useToken('not-a-real-token');
    var authRefused = false;
    try {
      await api.orders();
    } on AuthExpired {
      authRefused = true;
    }
    check('an invalid token is rejected with AuthExpired', authRefused);

    // 12. logout clears the session server-side
    api.useToken(session.token);
    await api.logout();
    var afterLogoutRefused = false;
    try {
      await api.orders();
    } on AuthExpired {
      afterLogoutRefused = true;
    }
    check('the token stops working after logout', afterLogoutRefused);
  } on CommerceException catch (e) {
    check('unexpected API error', false, e.message);
  } catch (e) {
    check('unexpected error', false, e.toString());
  }

  api.dispose();
  stdout.writeln(
    failures == 0 ? '\nALL CHECKS PASSED' : '\n$failures CHECK(S) FAILED',
  );
  exit(failures == 0 ? 0 : 1);
}
