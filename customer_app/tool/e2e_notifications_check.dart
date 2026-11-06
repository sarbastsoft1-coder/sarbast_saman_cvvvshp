// End-to-end check for the server-backed notification feed: drives the real
// CommerceApi against the running Laravel server.
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:customer_app/boutique/services/commerce_api.dart';

const _base = 'http://127.0.0.1:8000/api/v1';

/// Moves an order along as the seller would, so the customer gets a real
/// delivery-status notification. The customer app has no seller endpoint, so
/// this one call goes out directly.
Future<void> _sellerSetStatus(String token, int orderId, String status) async {
  final response = await http.post(
    Uri.parse('$_base/seller/orders/$orderId/status'),
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode({'status': status}),
  );
  if (response.statusCode != 200) {
    throw StateError('seller status update failed: ${response.statusCode}');
  }
}

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
    // Register a customer so the feed is guaranteed to start empty.
    final email = 'nf${DateTime.now().millisecondsSinceEpoch}@example.com';
    final session = await api.register(
      name: 'Notify Flow',
      email: email,
      password: 'secret1234',
      passwordConfirmation: 'secret1234',
    );
    api.useToken(session.token);
    check('registered', session.token.isNotEmpty);

    // 1. Feed starts empty
    final empty = await api.notifications();
    check('feed starts empty', empty.items.isEmpty, 'count=${empty.items.length}');
    check('unread count starts at 0', empty.unreadCount == 0);

    // 2. Anonymous access is refused
    final anon = CommerceApi();
    var refused = false;
    try {
      await anon.notifications();
    } on AuthExpired {
      refused = true;
    }
    check('feed requires a session', refused);
    anon.dispose();

    // 3. Real checkout produces a real notification
    final products = await api.products();
    final productId = (products.first['id'] as num).toInt();
    final order = await api.checkout(
      items: [(productId: productId, quantity: 1)],
      shippingAddress: 'Hulwsh, Mahalla 90',
      phone: '07501234567',
    );
    check('order placed', order.orderNumber.isNotEmpty, order.orderNumber);

    final afterCheckout = await api.notifications();
    check('checkout produced a notification', afterCheckout.items.isNotEmpty,
        'count=${afterCheckout.items.length}');
    check('unread count is 1', afterCheckout.unreadCount == 1,
        'unread=${afterCheckout.unreadCount}');
    final first = afterCheckout.items.first;
    check('notification has a title', first.title.isNotEmpty, first.title);
    check('notification has a body', first.body.isNotEmpty, first.body);
    check('it is an order notification', first.type == 'order', first.type);
    check('it deep-links to tracking',
        first.actionRoute == '/order-tracking', '${first.actionRoute}');
    check('it carries the order id',
        first.actionArgs?['orderId'] == order.orderNumber,
        '${first.actionArgs?['orderId']}');
    check('it is unread', !first.isRead);

    // 4. The cursor suppresses a repeat poll
    final noNew = await api.notifications(sinceId: afterCheckout.latestId);
    check('cursor returns nothing new', noNew.items.isEmpty,
        'count=${noNew.items.length}');

    // 5. Mark one read
    await api.markNotificationRead(first.id);
    final afterRead = await api.notifications();
    check('read state is stored on the server',
        afterRead.items.first.isRead, 'unread=${afterRead.unreadCount}');
    check('unread count dropped to 0', afterRead.unreadCount == 0);

    // 6. unread_only filter
    final unreadOnly = await api.notifications();
    check('filter returns the read row', unreadOnly.items.length == 1,
        'total=${unreadOnly.items.length}');

    // 7. A second real event (seller status change) arrives.
    //    The customer app has no seller endpoint, so this one call is made
    //    directly with the seller's token over plain HTTP.
    final sellerApi = CommerceApi();
    final sellerSession = await sellerApi.login(
      email: 'seller@earthshop.test',
      password: 'password',
    );
    await _sellerSetStatus(
      sellerSession.token,
      order.id,
      'out_for_delivery',
    );
    sellerApi.dispose();

    final afterStatus = await api.notifications();
    check('status change produced a new notification',
        afterStatus.items.length == 2, 'count=${afterStatus.items.length}');
    check('unread count is 1 again', afterStatus.unreadCount == 1,
        'unread=${afterStatus.unreadCount}');
    check('newest is the delivery update',
        afterStatus.items.first.body.contains('out for delivery'),
        afterStatus.items.first.body);

    // 8. mark all read
    await api.markAllNotificationsRead();
    final afterAll = await api.notifications();
    check('mark-all-read clears unread', afterAll.unreadCount == 0,
        'unread=${afterAll.unreadCount}');
    check('rows are kept, just read', afterAll.items.length == 2,
        'count=${afterAll.items.length}');

    // 9. limit is respected
    final limited = await api.notifications(limit: 1);
    check('limit is respected', limited.items.length <= 1,
        'count=${limited.items.length}');

    // 10. delete
    await api.deleteNotification(afterAll.items.first.id);
    final afterDelete = await api.notifications();
    check('notification deleted', afterDelete.items.length == 1,
        'count=${afterDelete.items.length}');

    // 11. Cross-account isolation
    final otherApi = CommerceApi();
    final other = await otherApi.register(
      name: 'Other',
      email: 'no${DateTime.now().millisecondsSinceEpoch}@example.com',
      password: 'secret1234',
      passwordConfirmation: 'secret1234',
    );
    otherApi.useToken(other.token);
    final otherFeed = await otherApi.notifications();
    check('another account sees an empty feed', otherFeed.items.isEmpty,
        'count=${otherFeed.items.length}');
    var crossDelete = false;
    try {
      await otherApi.deleteNotification(afterDelete.items.first.id);
    } on CommerceException {
      crossDelete = true;
    }
    check("cannot delete another account's notification", crossDelete);
    otherApi.dispose();
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
