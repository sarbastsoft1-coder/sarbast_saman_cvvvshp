import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/commerce_api.dart';
import 'roni_provider.dart';

class CoinEntry {
  CoinEntry(Map<String, dynamic> row)
    : label = '${row['description'] ?? row['type'] ?? ''}',
      amount = numberOf(row['amount']).toInt(),
      at = DateTime.tryParse('${row['created_at']}');
  final String label;
  final int amount;
  final DateTime? at;
}
class CoinsProvider extends ChangeNotifier {
  CoinsProvider({CommerceApi? api, SharedPreferences? preferences}) : _api = api ?? CommerceApi();
  final CommerceApi _api;
  int balance = 0, earned = 0, spent = 0;
  List<CoinEntry> history = [];
  List<Map<String, dynamic>> rewards = [], redemptions = [];
  Map<String, dynamic> policy = {};
  bool loading = false, busy = false, _disposed = false;
  String? error;
  int _generation = 0;
  Future<void> refresh() async {
    final generation = ++_generation;
    if (_api.token == null) { reset(); return; }
    loading = true; error = null; notifyListeners();
    try {
      final response = await _api.getData('/customer/ronix', authenticated: true);
      if (_disposed || generation != _generation) return;
      final data = objectOf(response['data']);
      balance = numberOf(data['balance']).toInt();
      earned = numberOf(data['earned']).toInt(); spent = numberOf(data['spent']).toInt();
      history = rowsOf(data['transactions']).map(CoinEntry.new).toList();
      rewards = rowsOf(data['rewards']); redemptions = rowsOf(data['redemptions']); policy = objectOf(data['policy']);
    } on CommerceException catch(e) { if (!_disposed && generation == _generation) error = e.message; }
    finally { if (!_disposed && generation == _generation) { loading = false; notifyListeners(); } }
  }
  Future<bool> redeemReward(int id) async {
    if (busy) return false;
    busy = true; error = null; notifyListeners();
    try {
      await _api.postData('/customer/rewards/$id/redeem', {'idempotency_key': 'reward-$id-${DateTime.now().microsecondsSinceEpoch}'});
      await refresh(); return true;
    } on CommerceException catch(e) { error = e.message; return false; }
    finally { busy = false; if (!_disposed) notifyListeners(); }
  }
  void reset() { ++_generation; balance = 0; earned = 0; spent = 0; history = []; rewards = []; redemptions = []; policy = {}; error = null; loading = false; notifyListeners(); }
  @override
  void dispose() { _disposed = true; ++_generation; super.dispose(); }
}

