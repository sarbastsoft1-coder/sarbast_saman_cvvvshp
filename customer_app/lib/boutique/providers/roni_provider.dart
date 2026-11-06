import 'package:flutter/foundation.dart';
import '../services/commerce_api.dart';

Map<String, dynamic> objectOf(dynamic value) => value is Map ? Map<String, dynamic>.from(value) : {};
List<Map<String, dynamic>> rowsOf(dynamic value) => value is List ? value.map(objectOf).toList() : [];
num numberOf(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
String minorMoney(dynamic value) => '\$${(numberOf(value) / 100).toStringAsFixed(2)}';

/// Server snapshots only: privileges, winners and contributions are never calculated locally.
class RoniProvider extends ChangeNotifier {
  RoniProvider({required this.api});
  final CommerceApi api;
  Map<String, dynamic> summary = {}, gives = {}, memberships = {};
  bool loading = false, busy = false, _disposed = false;
  String? error;
  int _generation = 0;
  Future<void> refresh() async {
    final generation = ++_generation;
    loading = true; error = null; notifyListeners();
    try {
      final values = await Future.wait([
        api.getData('/customer/roni'), api.getData('/customer/gives'), api.getData('/customer/memberships'),
      ]);
      if (_disposed || generation != _generation) return;
      summary = objectOf(values[0]['data']); gives = objectOf(values[1]['data']); memberships = objectOf(values[2]['data']);
    } on CommerceException catch (e) {
      if (!_disposed && generation == _generation) error = e.message;
    } finally {
      if (!_disposed && generation == _generation) { loading = false; notifyListeners(); }
    }
  }
  Future<bool> requestMembership(int id, String interval) => _mutate(
    '/customer/memberships/request', {'plan_id': id, 'interval': interval});
  Future<bool> cancelMembership() => _mutate('/customer/memberships/cancel', {});
  Future<bool> _mutate(String path, Map<String, dynamic> body) async {
    if (busy) return false;
    busy = true; error = null; notifyListeners();
    try { await api.postData(path, body); await refresh(); return true; }
    on CommerceException catch (e) { error = e.message; return false; }
    finally { busy = false; if (!_disposed) notifyListeners(); }
  }
  void clear() { ++_generation; summary = {}; gives = {}; memberships = {}; error = null; loading = false; notifyListeners(); }
  @override
  void dispose() { _disposed = true; ++_generation; super.dispose(); }
}

