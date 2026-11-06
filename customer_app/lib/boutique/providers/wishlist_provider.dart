import 'package:shared_preferences/shared_preferences.dart';
import '../services/commerce_api.dart';
import '../services/local_store.dart';
import '../models/product.dart';

/// Persists wishlist state across screens; syncs with `/customer/favorites` when signed in.
class WishlistProvider extends LocalStoreNotifier {
  WishlistProvider({CommerceApi? api, SharedPreferences? preferences})
    : _api = api,
      super(preferences, 'boutique.wishlist.v1') {
    final data = readData();
    if (data is List) {
      for (final item in data) {
        try {
          final product = BoutiqueProduct.fromJson(
            Map<String, dynamic>.from(item as Map),
          );
          _items.add(product);
          _ids.add(product.id);
        } catch (_) {
          /* Skip invalid saved entries. */
        }
      }
    }
  }

  final CommerceApi? _api;
  bool loading = false;
  String? error;
  bool _disposed = false;

  void _changed() {
    saveData(_items.map((p) => p.toJson()).toList());
    notifyListeners();
  }

  final Set<int> _ids = <int>{};
  final List<BoutiqueProduct> _items = [];

  List<BoutiqueProduct> get items => List.unmodifiable(_items);
  int get count => _ids.length;
  bool get isEmpty => _ids.isEmpty;

  bool contains(int productId) => _ids.contains(productId);

  Future<void> refreshFromApi() async {
    final api = _api;
    if (api == null || api.token == null) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = await api.favorites();
      if (_disposed) return;
      _ids.clear();
      _items.clear();
      for (final row in rows) {
        try {
          final product = BoutiqueProduct.fromApi(row);
          _ids.add(product.id);
          _items.add(product);
        } catch (_) {
          /* Skip bad rows. */
        }
      }
      error = null;
      _changed();
    } on CommerceException catch (e) {
      error = e.message;
      notifyListeners();
    } catch (_) {
      error = 'نەتوانرا دڵخوازەکان بکرێنەوە';
      notifyListeners();
    } finally {
      loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> toggle(BoutiqueProduct product) async {
    final wasIn = _ids.contains(product.id);
    // Optimistic local update.
    if (wasIn) {
      _ids.remove(product.id);
      _items.removeWhere((p) => p.id == product.id);
    } else {
      _ids.add(product.id);
      _items.add(product);
    }
    _changed();

    final api = _api;
    if (api == null || api.token == null) return;
    try {
      final added = await api.toggleFavorite(product.id);
      if (added && !_ids.contains(product.id)) {
        _ids.add(product.id);
        _items.add(product);
        _changed();
      } else if (!added && _ids.contains(product.id)) {
        _ids.remove(product.id);
        _items.removeWhere((p) => p.id == product.id);
        _changed();
      }
    } on CommerceException catch (e) {
      // Revert optimistic change.
      if (wasIn) {
        _ids.add(product.id);
        if (!_items.any((p) => p.id == product.id)) _items.add(product);
      } else {
        _ids.remove(product.id);
        _items.removeWhere((p) => p.id == product.id);
      }
      error = e.message;
      _changed();
    }
  }

  void add(BoutiqueProduct product) {
    if (_ids.contains(product.id)) return;
    _ids.add(product.id);
    _items.add(product);
    _changed();
    final api = _api;
    if (api != null && api.token != null) {
      api.toggleFavorite(product.id).catchError((_) => false);
    }
  }

  void remove(int productId) {
    final existing = _items.where((p) => p.id == productId).firstOrNull;
    _ids.remove(productId);
    _items.removeWhere((p) => p.id == productId);
    _changed();
    final api = _api;
    if (api != null && api.token != null && existing != null) {
      api.toggleFavorite(productId).catchError((_) => false);
    }
  }

  void clear() {
    _ids.clear();
    _items.clear();
    _changed();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
