import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local demo data, separate from authentication.
abstract class LocalStoreNotifier extends ChangeNotifier {
  LocalStoreNotifier(this.preferences, this.storageKey);
  final SharedPreferences? preferences;
  final String storageKey;
  Future<void> _pendingSave = Future.value();
  Future<void> get pendingSave => _pendingSave;
  bool storageFailed = false;
  dynamic readData() {
    try {
      final value = preferences?.getString(storageKey);
      return value == null ? null : jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  void saveData(Object value) {
    if (preferences == null) return;
    final encoded = jsonEncode(value);
    _pendingSave = _pendingSave.then((_) async {
      try {
        storageFailed = !await preferences!.setString(storageKey, encoded);
      } catch (_) {
        storageFailed = true;
      }
    });
  }
}
