import 'package:flutter/material.dart';

/// Manages active tab index for [BoutiqueMainShell] and enables
/// any descendant widget to switch tabs programmatically.
class BoutiqueNavProvider extends ChangeNotifier {
  int _currentIndex = 0;
  String? _pendingCategory;

  int get currentIndex => _currentIndex;
  String? get pendingCategory => _pendingCategory;

  void switchTab(int index, {String? category}) {
    _currentIndex = index;
    if (category != null) {
      _pendingCategory = category;
    }
    notifyListeners();
  }

  void clearPendingCategory() {
    _pendingCategory = null;
  }
}
