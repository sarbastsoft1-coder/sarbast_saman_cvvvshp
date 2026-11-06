import 'package:flutter/material.dart';

enum DiscountType { percentage, fixed, freeShipping }

class BoutiqueCoupon {
  final String code;
  final String title;
  final String description;
  final DiscountType type;
  final double
  value; // Percentage (e.g. 20) or fixed amount in IQD (e.g. 10000)
  final double minSpend;
  final String expiryDate;
  final String emoji;
  final Color accentColor;
  final DateTime? expiresAt;

  const BoutiqueCoupon({
    required this.code,
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    this.minSpend = 0,
    required this.expiryDate,
    this.emoji = '🏷️',
    this.accentColor = const Color(0xFFDCAE96),
    this.expiresAt,
  });

  bool get isValid => expiresAt == null || DateTime.now().isBefore(expiresAt!);

  /// Calculates the discount amount in IQD based on the cart subtotal and delivery fee.
  double calculateDiscount(double subtotal, double deliveryFee) {
    if (subtotal < minSpend) return 0.0;

    switch (type) {
      case DiscountType.percentage:
        return (subtotal * (value / 100)).roundToDouble();
      case DiscountType.fixed:
        return value > subtotal ? subtotal : value;
      case DiscountType.freeShipping:
        return 0; // Shipping is waived separately, never deducted twice.
    }
  }

  String get discountBadge {
    switch (type) {
      case DiscountType.percentage:
        return '٪${value.toInt()} داشکاندن';
      case DiscountType.fixed:
        return '${value.toInt()} د.ع داشکاندن';
      case DiscountType.freeShipping:
        return 'گەیاندنی بێبەرامبەر';
    }
  }
}

/// Available store coupons
final List<BoutiqueCoupon> sampleCoupons = [
  BoutiqueCoupon(
    code: 'WELCOME20',
    expiresAt: DateTime(2027, 12, 31),
    title: 'داشکاندنی ٪٢٠ بۆ یەکەم کڕین',
    description: 'بۆ کڕینی سەروو ٤٠,٠٠٠ دینار لە سەرجەم بەشەکان',
    type: DiscountType.percentage,
    value: 20,
    minSpend: 40000,
    expiryDate: '٣١ی کانوونی یەکەم ٢٠٢٧',
    emoji: '✨',
    accentColor: Color(0xFFDCAE96),
  ),
  BoutiqueCoupon(
    code: 'FREESHIP',
    expiresAt: DateTime(2027, 12, 31),
    title: 'گەیاندنی بێبەرامبەر بە دیاری',
    description: 'گەیاندنی بێ بەرامبەر بۆ هەر کڕینێکی سەروو ٣٠,٠٠٠ دینار',
    type: DiscountType.freeShipping,
    value: 3000,
    minSpend: 30000,
    expiryDate: '٣١ی کانوونی یەکەم ٢٠٢٧',
    emoji: '🚚',
    accentColor: Color(0xFF4A7BD0),
  ),
  BoutiqueCoupon(
    code: 'BOUTIQUE10',
    expiresAt: DateTime(2027, 12, 31),
    title: 'داشکاندنی ٪١٠ی گشتی بۆتیک',
    description: 'داشکاندن بەبێ هیچ مەرجێکی کەمی بڕی کڕین',
    type: DiscountType.percentage,
    value: 10,
    minSpend: 0,
    expiryDate: '٣١ی کانوونی یەکەم ٢٠٢٧',
    emoji: '🌸',
    accentColor: Color(0xFF6FBF73),
  ),
  BoutiqueCoupon(
    code: 'VIP50',
    expiresAt: DateTime(2027, 12, 31),
    title: 'داشکاندنی شاهانەی VIP',
    description: 'داشکاندنی ١٥,٠٠٠ دینار بۆ کڕینی سەروو ١٠٠,٠٠٠ دینار',
    type: DiscountType.fixed,
    value: 15000,
    minSpend: 100000,
    expiryDate: '٣١ی کانوونی یەکەم ٢٠٢٧',
    emoji: '👑',
    accentColor: Color(0xFFB9986A),
  ),
];
