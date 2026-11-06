import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_store.dart';

import '../models/product.dart';

/// Tracks the products the user has opened most recently. Newer entries
/// bubble to the front; the list is capped to keep the UI responsive.
class RecentlyViewedProvider extends LocalStoreNotifier {
  RecentlyViewedProvider({SharedPreferences? preferences})
    : super(preferences, 'boutique.recent.v1') {
    final data = readData();
    if (data is List) {
      for (final item in data) {
        try {
          final product = BoutiqueProduct.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          _items.add(product);
        } catch (_) {
          /* Skip invalid saved entries. */
        }
      }
    }
  }
  void _changed() {
    saveData(_items.map((p) => p.toJson()).toList());
    notifyListeners();
  }

  static const int _capacity = 20;

  final List<BoutiqueProduct> _items = <BoutiqueProduct>[];

  List<BoutiqueProduct> get items => List.unmodifiable(_items);
  int get count => _items.length;
  bool get isEmpty => _items.isEmpty;

  /// Records a product view. If the product already exists, it is moved to
  /// the front instead of being duplicated.
  void track(BoutiqueProduct product) {
    _items.removeWhere((p) => p.id == product.id);
    _items.insert(0, product);
    if (_items.length > _capacity) {
      _items.removeRange(_capacity, _items.length);
    }
    _changed();
  }

  void remove(int productId) {
    final before = _items.length;
    _items.removeWhere((p) => p.id == productId);
    if (_items.length != before) _changed();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _changed();
  }
}
