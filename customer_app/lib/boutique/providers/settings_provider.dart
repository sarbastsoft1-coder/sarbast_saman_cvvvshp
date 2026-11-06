import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App theme modes. Persisted and wired to [MaterialApp.themeMode].
enum BoutiqueThemeMode { system, light, dark }

/// Holds user-tunable preferences. Persisted via SharedPreferences so the
/// choices survive an app restart. All getters default to the same value the
/// app shipped with originally.
class SettingsProvider extends ChangeNotifier {
  static const _kThemeMode = 'settings.themeMode';
  static const _kNotifications = 'settings.notifications';
  static const _kOrderUpdates = 'settings.orderUpdates';
  static const _kPromoUpdates = 'settings.promoUpdates';
  static const _kProductUpdates = 'settings.productUpdates';
  static const _kLanguage = 'settings.language';
  static const _kCurrency = 'settings.currency';

  /// Dark gold look matches the HTML artifact screenshot by default.
  BoutiqueThemeMode _themeMode = BoutiqueThemeMode.dark;
  bool _notificationsEnabled = true;
  bool _orderUpdates = true;
  bool _promoUpdates = true;
  bool _productUpdates = true;
  String _languageCode = 'ku'; // ISO code: ku, ckb, ar, en
  String _currencyCode = 'IQD'; // IQD, USD

  BoutiqueThemeMode get themeMode => _themeMode;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get orderUpdates => _orderUpdates;
  bool get promoUpdates => _promoUpdates;
  bool get productUpdates => _productUpdates;
  String get languageCode => _languageCode;
  String get currencyCode => _currencyCode;

  /// Loads any previously-saved values. Safe to call repeatedly; missing
  /// keys keep their defaults.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString(_kThemeMode);
    if (mode != null) {
      _themeMode = BoutiqueThemeMode.values.firstWhere(
        (m) => m.name == mode,
        orElse: () => BoutiqueThemeMode.light,
      );
    }
    _notificationsEnabled = prefs.getBool(_kNotifications) ?? true;
    _orderUpdates = prefs.getBool(_kOrderUpdates) ?? true;
    _promoUpdates = prefs.getBool(_kPromoUpdates) ?? true;
    _productUpdates = prefs.getBool(_kProductUpdates) ?? true;
    _languageCode = prefs.getString(_kLanguage) ?? 'ku';
    _currencyCode = prefs.getString(_kCurrency) ?? 'IQD';
    notifyListeners();
  }

  Future<void> setThemeMode(BoutiqueThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeMode, mode.name);
  }

  Future<void> setNotificationsEnabled(bool v) async {
    if (_notificationsEnabled == v) return;
    _notificationsEnabled = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifications, v);
    await prefs.setBool(_kOrderUpdates, _orderUpdates);
    await prefs.setBool(_kPromoUpdates, _promoUpdates);
    await prefs.setBool(_kProductUpdates, _productUpdates);
  }

  Future<void> setOrderUpdates(bool v) async {
    if (_orderUpdates == v) return;
    _orderUpdates = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOrderUpdates, v);
  }

  Future<void> setPromoUpdates(bool v) async {
    if (_promoUpdates == v) return;
    _promoUpdates = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kPromoUpdates, v);
  }

  Future<void> setProductUpdates(bool v) async {
    if (_productUpdates == v) return;
    _productUpdates = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kProductUpdates, v);
  }

  Future<void> setLanguageCode(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLanguage, code);
  }

  Future<void> setCurrencyCode(String code) async {
    if (_currencyCode == code) return;
    _currencyCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, code);
  }
}
