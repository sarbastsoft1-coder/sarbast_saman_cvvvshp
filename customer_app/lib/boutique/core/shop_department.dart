import 'package:flutter/material.dart';

/// Which side of the boutique a listing belongs to.
///
/// Unisex items stay visible in both men's and women's shops.
enum ShopAudience { male, female, unisex }

/// The shopper-facing store: men's or women's.
enum ShopDepartment { male, female }

extension ShopAudienceX on ShopAudience {
  String get apiValue => name;

  static ShopAudience parse(
    Object? value, {
    String? category,
    String? name,
    int? id,
  }) {
    final raw = '$value'.trim().toLowerCase();
    switch (raw) {
      case 'male':
      case 'men':
      case 'man':
      case 'پیاوان':
      case 'پیاو':
        return ShopAudience.male;
      case 'female':
      case 'women':
      case 'woman':
      case 'ژنان':
      case 'ژن':
        return ShopAudience.female;
    }
    final text = '${name ?? ''} ${category ?? ''}'.toLowerCase();
    if (text.contains('پیاو') ||
        text.contains('men') ||
        text.contains('man') ||
        text.contains('کراس') ||
        text.contains('درێش') ||
        text.contains('تەشی')) {
      return ShopAudience.male;
    }
    if (text.contains('ژن') ||
        text.contains('women') ||
        text.contains('woman') ||
        text.contains('جانتا') ||
        text.contains('جوانکاری') ||
        text.contains('گوارە') ||
        text.contains('ئەنگشت') ||
        text.contains('ئارای')) {
      return ShopAudience.female;
    }
    if (id != null) {
      return id.isOdd ? ShopAudience.female : ShopAudience.male;
    }
    return ShopAudience.unisex;
  }
}

extension ShopDepartmentX on ShopDepartment {
  String get label => this == ShopDepartment.male ? 'پیاوان' : 'ژنان';

  String get englishLabel => this == ShopDepartment.male ? 'Men' : 'Women';

  String get hint =>
      this == ShopDepartment.male ? 'بەشی پیاوان' : 'بەشی ژنان';

  IconData get icon =>
      this == ShopDepartment.male ? Icons.male_rounded : Icons.female_rounded;

  String get apiValue => name;

  /// Unisex listings stay visible in both shops; gendered ones only in theirs.
  bool shows(ShopAudience audience) =>
      audience == ShopAudience.unisex ||
      (this == ShopDepartment.male && audience == ShopAudience.male) ||
      (this == ShopDepartment.female && audience == ShopAudience.female);

  static ShopDepartment parse(Object? value) {
    switch ('$value'.trim().toLowerCase()) {
      case 'male':
      case 'men':
      case 'man':
        return ShopDepartment.male;
      default:
        return ShopDepartment.female;
    }
  }
}
