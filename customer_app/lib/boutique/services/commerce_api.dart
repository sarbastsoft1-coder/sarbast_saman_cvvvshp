import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Raised when the API returns a non-success payload, carrying the server's
/// own message so the UI can show something meaningful to the customer.
class CommerceException implements Exception {
  CommerceException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Raised when the stored token is no longer accepted (401).
class AuthExpired extends CommerceException {
  AuthExpired([
    super.message = 'Your session has expired. Please sign in again.',
  ]);
}

class Session {
  const Session({
    required this.token,
    required this.name,
    required this.email,
    this.role,
  });
  final String token;
  final String name;
  final String email;
  final String? role;
}

/// One priced line as returned by the server. The client never computes these.
class QuoteLine {
  const QuoteLine({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.stock = 0,
  });

  final int productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final double total;
  final int stock;

  factory QuoteLine.fromJson(Map<String, dynamic> json) => QuoteLine(
    productId: (json['product_id'] as num).toInt(),
    name: json['name']?.toString() ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    unitPrice: (json['unit_fiat'] as num?)?.toDouble() ?? 0,
    total: (json['total_fiat'] as num?)?.toDouble() ?? 0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
  );
}

/// The server's authoritative view of a cart. Every number here was computed on
/// the backend from the database, never from what the client believed.
class CartQuote {
  const CartQuote({
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.deliveryFee,
    required this.total,
    this.couponCode,
    this.couponError,
    this.warnings = const [],
  });

  final List<QuoteLine> lines;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final String? couponCode;
  final String? couponError;
  final List<String> warnings;

  factory CartQuote.fromJson(Map<String, dynamic> json) => CartQuote(
    lines: (json['lines'] as List? ?? [])
        .map((row) => QuoteLine.fromJson(Map<String, dynamic>.from(row as Map)))
        .toList(),
    subtotal: (json['subtotal_fiat'] as num?)?.toDouble() ?? 0,
    discount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
    deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
    total: (json['total_fiat'] as num?)?.toDouble() ?? 0,
    couponCode: json['coupon']?['code']?.toString(),
    couponError: json['coupon_error']?.toString(),
    warnings: (json['warnings'] as List? ?? [])
        .map((w) => w.toString())
        .toList(),
  );
}

/// One row from the server's notification feed.
///
/// Notifications are plain database rows the client polls for, so there is no
/// push SDK, no device token and no third-party service involved.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.actionLabel,
    this.actionRoute,
    this.actionArgs,
    this.createdAt,
  });

  final int id;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, dynamic>? actionArgs;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: (json['id'] as num).toInt(),
        type: json['type']?.toString() ?? 'system',
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        isRead: json['read_at'] != null,
        actionLabel: json['action_label']?.toString(),
        actionRoute: json['action_route']?.toString(),
        actionArgs: json['action_args'] == null
            ? null
            : Map<String, dynamic>.from(json['action_args'] as Map),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

/// A page of notifications plus the cursor for the next poll.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unreadCount,
    required this.latestId,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final int latestId;

  factory NotificationPage.fromJson(Map<String, dynamic> json) =>
      NotificationPage(
        items: (json['data'] as List? ?? [])
            .map(
              (row) => AppNotification.fromJson(
                Map<String, dynamic>.from(row as Map),
              ),
            )
            .toList(),
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
        latestId: (json['latest_id'] as num?)?.toInt() ?? 0,
      );
}

/// A saved delivery address held on the server.
class SavedAddress {
  const SavedAddress({
    required this.id,
    required this.label,
    required this.address,
    required this.phone,
    required this.isDefault,
  });

  final int id;
  final String label;
  final String address;
  final String phone;
  final bool isDefault;

  factory SavedAddress.fromJson(Map<String, dynamic> json) => SavedAddress(
    id: (json['id'] as num).toInt(),
    label: json['label']?.toString() ?? 'home',
    address: json['address']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    isDefault: json['is_default'] == true,
  );
}

/// One line on a placed order (when the API includes `items`).
class PlacedOrderItem {
  const PlacedOrderItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.imageUrl,
  });

  final int productId;
  final String name;
  final int quantity;
  final double unitPrice;
  final String? imageUrl;

  factory PlacedOrderItem.fromJson(Map<String, dynamic> json) {
    final product = json['product'] is Map
        ? Map<String, dynamic>.from(json['product'] as Map)
        : const <String, dynamic>{};
    return PlacedOrderItem(
      productId: (json['product_id'] as num?)?.toInt() ??
          (product['id'] as num?)?.toInt() ??
          0,
      name: product['name']?.toString() ??
          json['name']?.toString() ??
          'بەرهەم',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_fiat'] as num?)?.toDouble() ??
          (json['price_fiat'] as num?)?.toDouble() ??
          (product['sale_price_fiat'] as num?)?.toDouble() ??
          (product['price_fiat'] as num?)?.toDouble() ??
          0,
      imageUrl: product['image']?.toString(),
    );
  }
}

/// An order as stored on the server after a successful checkout.
class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.total,
    required this.discount,
    required this.deliveryFee,
    required this.shippingAddress,
    this.phone = '',
    this.paymentMethod = 'cash',
    this.createdAt,
    this.items = const [],
  });

  final int id;
  final String orderNumber;
  final String status;
  final double total;
  final double discount;
  final double deliveryFee;
  final String shippingAddress;
  final String phone;
  final String paymentMethod;
  final DateTime? createdAt;
  final List<PlacedOrderItem> items;

  factory PlacedOrder.fromJson(Map<String, dynamic> json) => PlacedOrder(
    id: (json['id'] as num).toInt(),
    orderNumber: json['order_number']?.toString() ?? '',
    status: json['status']?.toString() ?? 'pending',
    total: (json['total_fiat'] as num?)?.toDouble() ?? 0,
    discount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
    deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
    shippingAddress: json['shipping_address']?.toString() ?? '',
    phone: json['phone']?.toString() ?? '',
    paymentMethod: json['payment_method']?.toString() ?? 'cash',
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    items: (json['items'] as List? ?? [])
        .map(
          (row) =>
              PlacedOrderItem.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList(),
  );
}

/// Thin client for the Laravel commerce endpoints.
///
/// Prices are always fetched from the server via [quote] or committed via
/// [checkout]; this client deliberately exposes no way to set a price locally.
class CommerceApi {
  CommerceApi({http.Client? client, this.baseUrl = defaultBaseUrl})
    : _client = client ?? http.Client();

  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  final http.Client _client;
  final String baseUrl;

  String? _token;

  /// Sets the bearer token sent with every request.
  void useToken(String? token) => _token = token;

  String? get token => _token;

  /// Shared transport for marketplace and RONI modules.
  Future<Map<String, dynamic>> getData(
    String path, {
    bool authenticated = false,
  }) => _get(path, requiresAuth: authenticated);

  Future<Map<String, dynamic>> postData(
    String path,
    Map<String, dynamic> body,
  ) => _post(path, body, requiresAuth: true);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request, {
    required bool requiresAuth,
  }) async {
    late http.Response response;
    try {
      response = await request().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw CommerceException('The server took too long to respond.');
    } catch (_) {
      throw CommerceException(
        'Could not reach the shop server. Check that the backend is running.',
      );
    }

    if (response.statusCode == 401 && requiresAuth) throw AuthExpired();

    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw CommerceException(
        'The server sent an unreadable response (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 400 || body['status'] == 'error') {
      // Laravel validation errors arrive as {message, errors:{field:[...]}}.
      final detail = body['errors'] != null
          ? (body['errors'] as Map).values
                .expand((list) => (list as List).map((e) => e.toString()))
                .join('\n')
          : null;
      throw CommerceException(
        detail ?? body['message']?.toString() ?? 'Request failed.',
        statusCode: response.statusCode,
      );
    }

    return body;
  }

  Future<Map<String, dynamic>> _get(
    String path, {
    Map<String, String>? query,
    bool requiresAuth = false,
  }) => _send(
    () => _client.get(_uri(path, query), headers: _headers),
    requiresAuth: requiresAuth,
  );

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) => _send(
    () => _client.post(_uri(path), headers: _headers, body: jsonEncode(body)),
    requiresAuth: requiresAuth,
  );

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body, {
    bool requiresAuth = false,
  }) => _send(
    () => _client.put(_uri(path), headers: _headers, body: jsonEncode(body)),
    requiresAuth: requiresAuth,
  );

  Future<Map<String, dynamic>> _delete(
    String path, {
    bool requiresAuth = false,
  }) => _send(
    () => _client.delete(_uri(path), headers: _headers),
    requiresAuth: requiresAuth,
  );

  // --- auth ---

  Future<Session> login({
    required String email,
    required String password,
  }) async {
    final body = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    final user = Map<String, dynamic>.from(body['user'] as Map);
    return Session(
      token: body['token'] as String,
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      role: user['role']?.toString(),
    );
  }

  Future<Session> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    final body = await _post('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    });
    final user = Map<String, dynamic>.from(body['user'] as Map);
    return Session(
      token: body['token'] as String,
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      role: user['role']?.toString(),
    );
  }

  Future<({String name, String email})> profile() async {
    final body = await _get('/auth/profile', requiresAuth: true);
    final user = Map<String, dynamic>.from(body['user'] as Map);
    return (
      name: user['name']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
    );
  }

  Future<void> logout() => _post('/auth/logout', const {});

  // --- catalog ---

  Future<List<Map<String, dynamic>>> products({
    String? category,
    String? gender,
  }) async {
    final query = <String, String>{
      if (category != null) 'category': category,
      if (gender != null) 'gender': gender,
    };
    final body = await _get(
      '/customer/products',
      query: query.isEmpty ? null : query,
    );
    return (body['data'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<List<Map<String, dynamic>>> coupons() async {
    final body = await _get('/customer/coupons');
    return (body['data'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  // --- pricing ---

  /// Asks the server what the cart actually costs. The client sends only
  /// product ids and quantities; prices come back from the database.
  Future<CartQuote> quote({
    required List<({int productId, int quantity})> items,
    String? couponCode,
  }) async {
    final body = await _post('/customer/quote', {
      'items': [
        for (final item in items)
          {'product_id': item.productId, 'quantity': item.quantity},
      ],
      if (couponCode != null && couponCode.isNotEmpty)
        'coupon_code': couponCode,
    }, requiresAuth: true);

    return CartQuote.fromJson(Map<String, dynamic>.from(body['data'] as Map));
  }

  /// Places the order. Totals are recomputed server-side; any price the client
  /// sends is ignored by the backend.
  Future<PlacedOrder> checkout({
    required List<({int productId, int quantity})> items,
    required String shippingAddress,
    required String phone,
    String paymentMethod = 'cash',
    int? addressId,
    String? couponCode,
  }) async {
    final body = await _post('/customer/checkout', {
      'items': [
        for (final item in items)
          {'product_id': item.productId, 'quantity': item.quantity},
      ],
      'payment_method': paymentMethod,
      'shipping_address': shippingAddress,
      'phone': phone,
      'address_id': ?addressId,
      if (couponCode != null && couponCode.isNotEmpty)
        'coupon_code': couponCode,
    }, requiresAuth: true);

    return PlacedOrder.fromJson(
      Map<String, dynamic>.from(body['order'] as Map),
    );
  }

  Future<List<PlacedOrder>> orders() async {
    final body = await _get('/customer/orders', requiresAuth: true);
    return (body['data'] as List)
        .map(
          (row) => PlacedOrder.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<void> cancelOrder(int orderId, {String? reason}) async {
    await _post('/customer/orders/$orderId/cancel', {
      'reason': ?reason,
    }, requiresAuth: true);
  }

  // --- addresses ---

  Future<List<SavedAddress>> addresses() async {
    final body = await _get('/customer/addresses', requiresAuth: true);
    return (body['data'] as List)
        .map(
          (row) => SavedAddress.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  Future<SavedAddress> saveAddress({
    required String label,
    required String address,
    required String phone,
    bool isDefault = false,
  }) async {
    final body = await _post('/customer/addresses', {
      'label': label,
      'address': address,
      'phone': phone,
      'is_default': isDefault,
    }, requiresAuth: true);
    return SavedAddress.fromJson(
      Map<String, dynamic>.from(body['address'] as Map),
    );
  }

  Future<SavedAddress> updateAddress({
    required int id,
    required String label,
    required String address,
    required String phone,
    bool isDefault = false,
  }) async {
    final body = await _put('/customer/addresses/$id', {
      'label': label,
      'address': address,
      'phone': phone,
      'is_default': isDefault,
    }, requiresAuth: true);
    return SavedAddress.fromJson(
      Map<String, dynamic>.from(body['address'] as Map),
    );
  }

  Future<void> deleteAddress(int id) async {
    await _delete('/customer/addresses/$id', requiresAuth: true);
  }

  // --- notifications ---

  /// Fetches the feed. [sinceId] restricts the response to rows newer than the
  /// cursor, which is what a polling client sends on every tick.
  Future<NotificationPage> notifications({int? sinceId, int? limit}) async {
    final query = <String, String>{
      if (sinceId != null) 'since_id': '$sinceId',
      if (limit != null) 'limit': '$limit',
    };
    final body = await _get(
      '/notifications',
      query: query.isEmpty ? null : query,
      requiresAuth: true,
    );
    return NotificationPage.fromJson(body);
  }

  Future<void> markNotificationRead(int id) async {
    await _post('/notifications/$id/read', const {}, requiresAuth: true);
  }

  Future<void> markAllNotificationsRead() async {
    await _post('/notifications/read-all', const {}, requiresAuth: true);
  }

  Future<void> deleteNotification(int id) async {
    await _delete('/notifications/$id', requiresAuth: true);
  }

  // --- wishlist ---

  Future<List<Map<String, dynamic>>> favorites() async {
    final body = await _get('/customer/favorites', requiresAuth: true);
    return (body['data'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
  }

  Future<bool> toggleFavorite(int productId) async {
    final body = await _post('/customer/favorites/toggle', {
      'product_id': productId,
    }, requiresAuth: true);
    return body['action'] == 'added';
  }

  void dispose() => _client.close();
}
