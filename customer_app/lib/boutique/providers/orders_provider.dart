import '../core/constants/money.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/commerce_api.dart';
import '../services/local_store.dart';
import 'cart_provider.dart';

enum OrderStatus { processing, onTheWay, delivered }

class BoutiqueOrder {
  String formatAmount(num value) =>
      items.firstOrNull?.product.formatAmount(value) ??
      Money.formatIqd(value);
  final String id;
  final String date;
  final OrderStatus status;
  final int
  trackingStep; // 0: Placed, 1: Packed, 2: Picked Up, 3: On The Way, 4: Delivered
  final List<CartLine> items;
  final double total;
  final double deliveryFee;
  final String address;
  final String phone;
  final double discount;
  final String paymentMethod;
  final String courierName;
  final String courierPhone;
  final String courierVehicle;
  final double courierRating;
  final int courierDeliveriesCount;
  final String storeName;
  final String storeAddress;
  final String estimatedTime;
  final int? serverId;

  const BoutiqueOrder({
    required this.id,
    required this.date,
    required this.status,
    this.trackingStep = 2,
    required this.items,
    required this.total,
    this.deliveryFee = 3000,
    required this.address,
    this.phone = '',
    this.discount = 0,
    required this.paymentMethod,
    this.courierName = 'کاروان عەلی',
    this.courierPhone = '+964 750 123 4567',
    this.courierVehicle = 'ماتۆڕسکیل هۆندا (ژمارە: ٥٤٣٢ هەولێر)',
    this.courierRating = 4.9,
    this.courierDeliveriesCount = 184,
    this.storeName = 'بۆتیکی ڕۆیاڵ',
    this.storeAddress = 'هەولێر، فامیلی مۆڵ، نهۆمی یەکەم',
    this.estimatedTime = '٢٥ - ٣٥ خولەک',
    this.serverId,
  });

  BoutiqueOrder copyWith({
    String? id,
    String? date,
    OrderStatus? status,
    int? trackingStep,
    List<CartLine>? items,
    double? total,
    double? deliveryFee,
    String? address,
    String? paymentMethod,
    String? courierName,
    String? courierPhone,
    String? courierVehicle,
    double? courierRating,
    int? courierDeliveriesCount,
    String? storeName,
    String? storeAddress,
    String? estimatedTime,
    int? serverId,
  }) {
    return BoutiqueOrder(
      id: id ?? this.id,
      date: date ?? this.date,
      status: status ?? this.status,
      trackingStep: trackingStep ?? this.trackingStep,
      items: items ?? this.items,
      total: total ?? this.total,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      address: address ?? this.address,
      phone: phone,
      discount: discount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      courierName: courierName ?? this.courierName,
      courierPhone: courierPhone ?? this.courierPhone,
      courierVehicle: courierVehicle ?? this.courierVehicle,
      courierRating: courierRating ?? this.courierRating,
      courierDeliveriesCount:
          courierDeliveriesCount ?? this.courierDeliveriesCount,
      storeName: storeName ?? this.storeName,
      storeAddress: storeAddress ?? this.storeAddress,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      serverId: serverId ?? this.serverId,
    );
  }

  String get statusLabel {
    switch (status) {
      case OrderStatus.processing:
        return 'لە پرۆسەدایە';
      case OrderStatus.onTheWay:
        return 'لە ڕێگادایە';
      case OrderStatus.delivered:
        return 'گەیەندراو';
    }
  }

  Color get statusColor {
    switch (status) {
      case OrderStatus.processing:
        return const Color(0xFFD49B44);
      case OrderStatus.onTheWay:
        return const Color(0xFF4A7BD0);
      case OrderStatus.delivered:
        return const Color(0xFF2E7D32);
    }
  }

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'status': status.name,
    'trackingStep': trackingStep,
    'items': items.map((item) => item.toJson()).toList(),
    'total': total,
    'deliveryFee': deliveryFee,
    'discount': discount,
    'address': address,
    'phone': phone,
    'paymentMethod': paymentMethod,
    'courierName': courierName,
    'courierPhone': courierPhone,
    'estimatedTime': estimatedTime,
    'serverId': serverId,
  };
  factory BoutiqueOrder.fromJson(Map<String, dynamic> json) => BoutiqueOrder(
    id: json['id'] as String,
    date: json['date'] as String,
    status: OrderStatus.values.byName(json['status'] as String),
    trackingStep: json['trackingStep'] as int,
    items: List<CartLine>.unmodifiable(
      (json['items'] as List).map(
        (row) => CartLine.fromJson(Map<String, dynamic>.from(row as Map)),
      ),
    ),
    total: (json['total'] as num).toDouble(),
    deliveryFee: (json['deliveryFee'] as num).toDouble(),
    discount: (json['discount'] as num? ?? 0).toDouble(),
    address: json['address'] as String,
    phone: json['phone'] as String? ?? '',
    paymentMethod: json['paymentMethod'] as String,
    courierName: json['courierName'] as String? ?? '',
    courierPhone: json['courierPhone'] as String? ?? '',
    estimatedTime: json['estimatedTime'] as String? ?? '',
    serverId: (json['serverId'] as num?)?.toInt(),
  );

  static OrderStatus statusFromApi(String raw) {
    final s = raw.toLowerCase();
    if (s.contains('deliver')) return OrderStatus.delivered;
    if (s.contains('way') ||
        s.contains('ship') ||
        s.contains('out') ||
        s.contains('pick')) {
      return OrderStatus.onTheWay;
    }
    return OrderStatus.processing;
  }

  static int stepFromStatus(OrderStatus status) => switch (status) {
    OrderStatus.processing => 1,
    OrderStatus.onTheWay => 3,
    OrderStatus.delivered => 4,
  };

  factory BoutiqueOrder.fromPlaced(PlacedOrder placed) {
    final status = statusFromApi(placed.status);
    final items = placed.items
        .map(
          (line) => CartLine(
            product: BoutiqueProduct(
              id: line.productId,
              name: line.name,
              price: line.unitPrice,
              currency: 'USD',
              category: 'بەرهەم',
              description: '',
              seller: '',
              rating: 0,
              reviews: 0,
              emoji: '🛍️',
              art: 'bag',
              accent: const Color(0xFFDCAE96),
              imageUrl: line.imageUrl,
              availableSizes: const [],
              availableColors: const [],
            ),
            quantity: line.quantity,
          ),
        )
        .toList();
    return BoutiqueOrder(
      id: placed.orderNumber.isNotEmpty
          ? placed.orderNumber
          : 'ORD-${placed.id}',
      date: (placed.createdAt ?? DateTime.now()).toIso8601String().substring(
        0,
        10,
      ),
      status: status,
      trackingStep: stepFromStatus(status),
      items: List<CartLine>.unmodifiable(items),
      total: placed.total,
      deliveryFee: placed.deliveryFee,
      discount: placed.discount,
      address: placed.shippingAddress,
      phone: placed.phone,
      paymentMethod: placed.paymentMethod == 'cash'
          ? 'پارەدان لە کاتی وەرگرتن'
          : placed.paymentMethod,
      courierName: '',
      courierPhone: '',
      estimatedTime: status == OrderStatus.delivered
          ? 'گەیەندراوە'
          : 'دیاری نەکراوە',
      serverId: placed.id,
    );
  }
}

class OrdersProvider extends LocalStoreNotifier {
  OrdersProvider({CommerceApi? api, SharedPreferences? preferences})
    : _api = api,
      super(preferences, 'boutique.orders.v1') {
    final saved = readData();
    if (saved is List) {
      _orders.clear();
      for (final row in saved) {
        try {
          _orders.add(
            BoutiqueOrder.fromJson(Map<String, dynamic>.from(row as Map)),
          );
        } catch (_) {
          /* Skip damaged saved orders. */
        }
      }
    }
  }

  final CommerceApi? _api;
  bool loading = false;
  String? error;
  bool _disposed = false;

  BoutiqueOrder? byId(String id) =>
      _orders.where((o) => o.id == id).firstOrNull;
  void _changed() {
    saveData(_orders.map((o) => o.toJson()).toList());
    notifyListeners();
  }

  final List<BoutiqueOrder> _orders = [];

  List<BoutiqueOrder> get orders => List.unmodifiable(_orders);

  /// In-progress orders for the home live strip (HTML `#liveOrder`).
  List<BoutiqueOrder> get activeOrders => _orders
      .where(
        (o) =>
            o.status == OrderStatus.processing ||
            o.status == OrderStatus.onTheWay,
      )
      .toList(growable: false);

  /// Pull server orders when signed in. Keeps local cache as offline fallback.
  Future<void> refreshFromApi() async {
    final api = _api;
    if (api == null || api.token == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final remote = await api.orders();
      if (_disposed) return;
      _orders
        ..clear()
        ..addAll(remote.map(BoutiqueOrder.fromPlaced));
      error = null;
      _changed();
    } on CommerceException catch (e) {
      error = e.message;
      notifyListeners();
    } catch (_) {
      error = 'نەتوانرا داواکارییەکان بکرێنەوە';
      notifyListeners();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> cancelRemote(BoutiqueOrder order, {String? reason}) async {
    final api = _api;
    final id = order.serverId;
    if (api == null || api.token == null || id == null) return false;
    try {
      await api.cancelOrder(id, reason: reason);
      await refreshFromApi();
      return true;
    } on CommerceException catch (e) {
      error = e.message;
      notifyListeners();
      return false;
    }
  }

  void clearForGuest() {
    _orders.clear();
    error = null;
    _changed();
  }

  BoutiqueOrder addOrder({
    required List<CartLine> items,
    required double total,
    required String address,
    required String paymentMethod,
    String phone = '',
    String? serverOrderNumber,
    int? serverId,
    double deliveryFee = CartProvider.deliveryFee,
    double discount = 0,
  }) {
    if (items.isEmpty) throw ArgumentError('Cannot place an empty order');
    final newId =
        serverOrderNumber ?? 'ORD-${DateTime.now().microsecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String().substring(0, 10);
    final order = BoutiqueOrder(
      id: newId,
      date: now,
      status: OrderStatus.processing,
      trackingStep: 0,
      items: List<CartLine>.unmodifiable(items),
      total: total,
      deliveryFee: deliveryFee,
      discount: discount,
      phone: phone,
      address: address,
      paymentMethod: paymentMethod == 'cash'
          ? 'پارەدان لە کاتی وەرگرتن'
          : 'کارتی بانکی',
      courierName: '',
      courierPhone: '',
      courierVehicle: 'ماتۆڕسکیل هۆندا (ژمارە: ٥٤٣٢ هەولێر)',
      courierRating: 4.9,
      courierDeliveriesCount: 184,
      storeName: 'بۆتیکی ڕۆیاڵ',
      storeAddress: 'هەولێر، فامیلی مۆڵ، نهۆمی یەکەم',
      estimatedTime: 'دیاری نەکراوە',
      serverId: serverId,
    );
    _orders.insert(0, order);
    _changed();
    return order;
  }

  void updateOrderStatus(String orderId, OrderStatus newStatus, int newStep) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index] = _orders[index].copyWith(
        status: newStatus,
        trackingStep: newStep,
        estimatedTime: newStep >= 4
            ? 'گەیەندراوە'
            : (newStep == 3 ? '١٥ - ٢٠ خولەک' : '٣٠ - ٤٥ خولەک'),
      );
      _changed();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
