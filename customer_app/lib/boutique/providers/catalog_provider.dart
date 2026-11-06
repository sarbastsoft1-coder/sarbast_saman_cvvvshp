import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/boutique_constants.dart';
import '../core/shop_department.dart';
import '../models/product.dart';
import '../services/commerce_api.dart';

/// Holds selected category, search query, sort key, price range, and the visible products.
class CatalogProvider extends ChangeNotifier {
  CatalogProvider({
    CommerceApi? api,
    this.onProductsLoaded,
    this.loader,
    SharedPreferences? preferences,
  }) : _api = api,
       _preferences = preferences {
    final saved = preferences?.getString(_departmentKey);
    if (saved != null) {
      _department = ShopDepartmentX.parse(saved);
    }
  }

  final CommerceApi? _api;
  final Future<List<BoutiqueProduct>> Function()? loader;
  final void Function(List<BoutiqueProduct>)? onProductsLoaded;
  final SharedPreferences? _preferences;
  static const _departmentKey = 'boutique.shop.department';
  List<BoutiqueProduct> products = [];
  bool loading = false;
  String? error;
  bool _disposed = false;
  ShopDepartment _department = ShopDepartment.female;

  Future<void> load() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      List<BoutiqueProduct> remote = const [];
      if (loader != null) {
        remote = await loader!();
      } else if (_api != null) {
        final rows = await _api.products();
        remote = rows.map(BoutiqueProduct.fromApi).toList();
      }
      if (_disposed) return;
      if (remote.isNotEmpty) {
        products = remote;
        error = null;
      } else if (products.isEmpty) {
        // Only seed demo when we have nothing cached and API returned empty/unavailable.
        products = sampleProducts;
        error = 'کاتالۆگ لە سێرڤەر بەتاڵە — نموونە پیشان درا';
      }
      onProductsLoaded?.call(products);
    } catch (e) {
      if (!_disposed) {
        if (products.isEmpty) {
          products = sampleProducts;
          error = 'نەتوانرا کاتالۆگ بکرێتەوە — نموونە پیشان درا';
        } else {
          error = e is CommerceException ? e.message : 'هەڵەی تۆڕ';
        }
        onProductsLoaded?.call(products);
      }
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  String _category = BoutiqueConstants.categories.first;
  String _query = '';
  String _sort = BoutiqueConstants.sortOptions.first['key']!;
  RangeValues _priceRange = const RangeValues(0, 150000);

  static String _normalize(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('ي', 'ی')
      .replaceAll('ك', 'ک')
      .replaceAll(RegExp(r'[\u064B-\u065F]'), '');
  bool get hasFilters =>
      _query.isNotEmpty ||
      _category != BoutiqueConstants.categories.first ||
      _priceRange != const RangeValues(0, 150000) ||
      _sort != 'newest';

  String get category => _category;
  String get query => _query;
  String get sort => _sort;
  RangeValues get priceRange => _priceRange;
  ShopDepartment get department => _department;

  /// Catalog after department + category + search + price filters.
  List<BoutiqueProduct> get visibleProducts => filter(products);

  void selectDepartment(ShopDepartment value) {
    if (_department == value) return;
    _department = value;
    _preferences?.setString(_departmentKey, value.apiValue);
    notifyListeners();
  }

  void selectCategory(String value) {
    if (_category == value) return;
    _category = value;
    notifyListeners();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setSort(String value) {
    _sort = value;
    notifyListeners();
  }

  void setPriceRange(RangeValues values) {
    _priceRange = values;
    notifyListeners();
  }

  void clearFilters() {
    _category = BoutiqueConstants.categories.first;
    _query = '';
    _sort = BoutiqueConstants.sortOptions.first['key']!;
    _priceRange = const RangeValues(0, 150000);
    notifyListeners();
  }

  /// Returns products filtered by optional shop department, category, query, price, and sort.
  List<BoutiqueProduct> filter(
    List<BoutiqueProduct> source, {
    ShopDepartment? department,
  }) {
    final q = _normalize(_query);
    final filtered = source.where((product) {
      final matchesShop =
          department == null || department.shows(product.audience);
      final matchesCategory =
          _category == BoutiqueConstants.categories.first ||
          product.category == _category;
      final matchesQuery =
          q.isEmpty ||
          _normalize(product.name).contains(q) ||
          _normalize(product.description).contains(q) ||
          _normalize(product.category).contains(q);
      final matchesPrice =
          product.price >= _priceRange.start &&
          product.price <= _priceRange.end;
      return matchesShop && matchesCategory && matchesQuery && matchesPrice;
    }).toList();

    switch (_sort) {
      case 'price_low':
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_high':
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'best_selling':
        filtered.sort((a, b) => b.reviews.compareTo(a.reviews));
        break;
      case 'newest':
      case 'new':
      default:
        filtered.sort((a, b) => b.id.compareTo(a.id));
    }
    return filtered;
  }
}
