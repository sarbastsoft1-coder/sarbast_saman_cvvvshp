import 'package:flutter/material.dart';

import 'money.dart';

/// Static catalog data and shared UI constants.
class BoutiqueConstants {
  BoutiqueConstants._();

  // Curated category list shown across the app (Claude HTML).
  static const List<String> categories = [
    'هەموو',
    'جلوبەرگ',
    'پێڵاو و جانتا',
    'ماڵ و چێشتخانە',
    'منداڵان',
    'جوانکاری',
    'دەستکرد',
  ];

  // Sort options surfaced in the filter sheet.
  static const List<Map<String, String>> sortOptions = [
    {'key': 'newest', 'label': 'نوێترین'},
    {'key': 'price_low', 'label': 'نرخ: کەم بۆ زۆر'},
    {'key': 'price_high', 'label': 'نرخ: زۆر بۆ کەم'},
    {'key': 'best_selling', 'label': 'زۆرترین فرۆشراو'},
  ];

  // Color swatches used on the product details screen.
  static const List<Color> palette = [
    Color(0xFFDCAE96),
    Color(0xFF333333),
    Color(0xFFF5F5DC),
    Color(0xFFE8A7A1),
    Color(0xFF6FBF73),
    Color(0xFFB9986A),
  ];

  // Standard size labels (kept short for boutique apparel).
  static const List<String> sizes = ['XS', 'S', 'M', 'L', 'XL'];

  /// Shared-preferences key marking the Roni splash as already shown, so it
  /// appears on first launch only.
  static const String splashSeenKey = 'boutique.splash.seen.v1';

  // Recent search suggestions seeded for the search screen.
  static const List<String> recentSearches = [
    'تاوە',
    'لەچک',
    'کراس',
    'سۆبە',
    'بەتانی',
  ];

  // Customer reviews used on the product details screen.
  static const List<Map<String, dynamic>> reviews = [
    {
      'name': 'شیلان',
      'rating': 5.0,
      'date': '١٢ی تشرینی یەکەم',
      'comment': 'وەک وێنەکە بوو. پێش گەیاندن وێنەکەیم بینی و دڵنیا بووم.',
    },
    {
      'name': 'کڕیاری Roni',
      'rating': 4.0,
      'date': '٨ی تشرینی یەکەم',
      'comment': 'کوالیتی باشە، قەبارەی ٢٤ سم بچووکە.',
    },
  ];
}

/// Number-to-Kurdish friendly string. Format uses Iraqi Dinar symbol "د.ع".
///
/// Delegates to [Money] so every price in the app — filters, coupons, hero
/// cards, totals — is rendered by exactly one formatter.
String formatPrice(num price) => Money.formatIqd(price);
