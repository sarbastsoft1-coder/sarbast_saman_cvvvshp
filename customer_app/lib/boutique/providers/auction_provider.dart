import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/commerce_api.dart';
import 'roni_provider.dart';

class AuctionProvider extends ChangeNotifier {
  AuctionProvider({CommerceApi? api, SharedPreferences? preferences}) : _api = api ?? CommerceApi() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) { if (!_disposed) notifyListeners(); });
  }
  final CommerceApi _api;
  Timer? _timer;
  List<Map<String, dynamic>> auctions = [];
  Map<String, dynamic>? selected;
  List<Map<String, dynamic>> bids = [], myBids = [];
  bool loading = false, busy = false, _disposed = false;
  String? error;
  int _generation = 0;
  bool get isLive => selected != null && ['active', 'live'].contains(selected!['status']) && remaining > Duration.zero;
  int get minimumNextBid => numberOf(selected?['highest_bid']).toInt() > 0
      ? numberOf(selected?['highest_bid']).toInt() + numberOf(selected?['bid_increment']).toInt()
      : numberOf(selected?['min_bid']).toInt();
  Duration get remaining {
    final end = DateTime.tryParse('${selected?['ends_at']}');
    final duration = end?.difference(DateTime.now()) ?? Duration.zero;
    return duration.isNegative ? Duration.zero : duration;
  }
  String get remainingLabel => '${remaining.inDays}d ${remaining.inHours % 24}h ${remaining.inMinutes % 60}m ${remaining.inSeconds % 60}s';
  Future<void> refresh({int? id}) async {
    final generation = ++_generation;
    loading = true; error = null; notifyListeners();
    try {
      final response = await _api.getData('/customer/auctions');
      if (_disposed || generation != _generation) return;
      auctions = rowsOf(response['data']);
      selected = auctions.where((a) => id != null ? a['id'] == id : ['active', 'live'].contains(a['status'])).firstOrNull ?? auctions.firstOrNull;
      if (selected != null) {
        final detail = await _api.getData('/customer/auctions/${selected!['id']}');
        if (_disposed || generation != _generation) return;
        final data = objectOf(detail['data']);
        selected = objectOf(data['auction']).isNotEmpty ? objectOf(data['auction']) : data;
        bids = rowsOf(detail['bids'] ?? data['bids']); myBids = rowsOf(detail['my_bids'] ?? data['my_bids']);
      }
    } on CommerceException catch(e) { if (!_disposed && generation == _generation) error = e.message; }
    finally { if (!_disposed && generation == _generation) { loading = false; notifyListeners(); } }
  }
  Future<bool> bid(int amount) async {
    if (busy || selected == null) return false;
    busy = true; error = null; notifyListeners();
    try { await _api.postData('/customer/auctions/${selected!['id']}/bid', {'amount': amount}); await refresh(id: numberOf(selected!['id']).toInt()); return true; }
    on CommerceException catch(e) { error = e.message; return false; }
    finally { busy = false; if (!_disposed) notifyListeners(); }
  }
  void clear() { ++_generation; selected = null; auctions = []; bids = []; myBids = []; error = null; notifyListeners(); }
  @override
  void dispose() { _disposed = true; ++_generation; _timer?.cancel(); super.dispose(); }
}

