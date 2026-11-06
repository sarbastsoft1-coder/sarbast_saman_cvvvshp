import '../core/constants/money.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/coupon.dart';
import '../models/product.dart';
import '../services/local_store.dart';

class CartLine {
  final BoutiqueProduct product;
  final int quantity;
  final String? size;
  final Color? color;
  const CartLine({
    required this.product,
    required this.quantity,
    this.size,
    this.color,
  });
  String get key => '${product.id}|${size ?? ''}|${color?.toARGB32() ?? ''}';
  String get variantLabel => [
    if (size != null) 'قەبارە: $size',
    if (color != null) 'ڕەنگی هەڵبژێردراو',
  ].join(' · ');
  CartLine copyWith({int? quantity}) => CartLine(
    product: product,
    quantity: quantity ?? this.quantity,
    size: size,
    color: color,
  );
  double get subtotal => product.price * quantity;
  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
    'size': size,
    'color': color?.toARGB32(),
  };
  factory CartLine.fromJson(Map<String, dynamic> json) => CartLine(
    product: BoutiqueProduct.fromJson(
      Map<String, dynamic>.from(json['product'] as Map),
    ),
    quantity: (json['quantity'] as int).clamp(1, 99),
    size: json['size'] as String?,
    color: json['color'] == null ? null : Color(json['color'] as int),
  );
}

class CartProvider extends LocalStoreNotifier {
  CartProvider({SharedPreferences? preferences})
    : super(preferences, 'boutique.cart.v2') {
    final data = readData();
    if (data is Map) {
      for (final item in (data['lines'] as List? ?? [])) {
        try {
          _lines.add(CartLine.fromJson(Map<String, dynamic>.from(item as Map)));
        } catch (_) {
          /* Skip invalid saved lines. */
        }
      }
      for (final coupon in sampleCoupons) {
        if (coupon.code == data['coupon'] &&
            coupon.isValid &&
            subtotal >= coupon.minSpend) {
          _appliedCoupon = coupon;
        }
      }
    }
  }
  final List<CartLine> _lines = [];
  final Map<int, BoutiqueProduct> _liveProducts = {};
  void syncProducts(List<BoutiqueProduct> products) {
    _liveProducts
      ..clear()
      ..addEntries(products.map((p) => MapEntry(p.id, p)));
    for (var i = 0; i < _lines.length; i++) {
      final line = _lines[i];
      final latest = _liveProducts[line.product.id];
      if (latest != null && latest.currency == line.product.currency) {
        _lines[i] = CartLine(
          product: latest,
          quantity: line.quantity,
          size: line.size,
          color: line.color,
        );
      }
    }
    _changed();
  }

  BoutiqueCoupon? _appliedCoupon;
  static const double deliveryFee = 3000;
  bool get hasMixedCurrencies =>
      _lines.map((l) => l.product.currency).toSet().length > 1;
  String get currency => _lines.firstOrNull?.product.currency ?? 'IQD';
  double get shippingFee => currency == 'USD' ? 4.50 : deliveryFee;
  String formatAmount(num value) => hasMixedCurrencies
      ? 'Remove items in a different currency'
      : Money.format(value, currency: currency);

  List<CartLine> get lines => List.unmodifiable(_lines);
  int get itemCount => _lines.fold(0, (sum, l) => sum + l.quantity);
  bool get isEmpty => _lines.isEmpty;
  double get subtotal => _lines.fold(0, (sum, l) => sum + l.subtotal);
  BoutiqueCoupon? get appliedCoupon => _appliedCoupon;
  bool get _couponEligible =>
      currency == 'IQD' &&
      _appliedCoupon != null &&
      _appliedCoupon!.isValid &&
      subtotal >= _appliedCoupon!.minSpend;
  double get discountAmount =>
      !_couponEligible || _appliedCoupon!.type == DiscountType.freeShipping
      ? 0
      : _appliedCoupon!.calculateDiscount(subtotal, deliveryFee);
  double get effectiveDeliveryFee =>
      isEmpty ||
          (_couponEligible && _appliedCoupon!.type == DiscountType.freeShipping)
      ? 0
      : shippingFee;
  double get total => isEmpty
      ? 0
      : (subtotal - discountAmount + effectiveDeliveryFee).clamp(
          0,
          double.infinity,
        );
  (bool, String) applyCoupon(BoutiqueCoupon coupon) {
    if (currency != 'IQD') return (false, 'ئەم کۆپۆنە تەنها بۆ بەرهەمی دینارە');
    if (isEmpty) return (false, 'سەرەتا بەرهەم زیاد بکە بۆ سەبەتە');
    if (!coupon.isValid) return (false, 'کۆپۆنەکە بەسەرچووە');
    if (subtotal < coupon.minSpend) {
      return (false, 'کەمترین بڕی کڕین ${coupon.minSpend.toInt()} دینارە');
    }
    _appliedCoupon = coupon;
    _changed();
    return (true, 'کۆپۆنی ${coupon.code} کاراکرا ✓');
  }

  (bool, String) applyCouponCode(String rawCode) {
    for (final coupon in sampleCoupons) {
      if (coupon.code == rawCode.trim().toUpperCase()) {
        return applyCoupon(coupon);
      }
    }
    return (false, 'کۆدی داشکاندن نادروستە');
  }

  void removeCoupon() {
    _appliedCoupon = null;
    _changed();
  }

  bool contains(int id) => _lines.any((l) => l.product.id == id);
  int quantityOf(int id) => _lines
      .where((l) => l.product.id == id)
      .fold(0, (sum, l) => sum + l.quantity);
  void add(BoutiqueProduct product, {int qty = 1, String? size, Color? color}) {
    if (qty <= 0) return;
    final latest = _liveProducts[product.id];
    if (latest?.currency == product.currency) product = latest!;
    final selectedSize = product.availableSizes.contains(size)
        ? size
        : product.availableSizes.firstOrNull;
    final selectedColor = product.availableColors.contains(color)
        ? color
        : product.availableColors.firstOrNull;
    final line = CartLine(
      product: product,
      quantity: qty.clamp(1, 99),
      size: selectedSize,
      color: selectedColor,
    );
    final index = _lines.indexWhere((l) => l.key == line.key);
    if (index < 0) {
      _lines.add(line);
    } else {
      _lines[index] = CartLine(
        product: product,
        quantity: (_lines[index].quantity + qty).clamp(1, 99),
        size: selectedSize,
        color: selectedColor,
      );
    }
    _changed();
  }

  bool _matches(CartLine line, Object id) =>
      id is int ? line.product.id == id : line.key == id;
  void remove(Object id) {
    _lines.removeWhere((l) => _matches(l, id));
    _changed();
  }

  void increment(Object id) {
    final i = _lines.indexWhere((l) => _matches(l, id));
    if (i < 0 || _lines[i].quantity >= 99) return;
    _lines[i] = _lines[i].copyWith(quantity: _lines[i].quantity + 1);
    _changed();
  }

  void decrement(Object id) {
    final i = _lines.indexWhere((l) => _matches(l, id));
    if (i < 0) return;
    if (_lines[i].quantity == 1) {
      _lines.removeAt(i);
    } else {
      _lines[i] = _lines[i].copyWith(quantity: _lines[i].quantity - 1);
    }
    _changed();
  }

  void clear() {
    _lines.clear();
    _appliedCoupon = null;
    _changed();
  }

  void _changed() {
    if (!_couponEligible) _appliedCoupon = null;
    saveData({
      'lines': _lines.map((l) => l.toJson()).toList(),
      'coupon': _appliedCoupon?.code,
    });
    notifyListeners();
  }
}
