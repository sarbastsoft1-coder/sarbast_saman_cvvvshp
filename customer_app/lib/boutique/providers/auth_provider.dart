import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/commerce_api.dart';

/// Signed-in customer session backed by a Laravel Sanctum token.
///
/// The boutique browses without an account, but placing a real order requires
/// one. The token is persisted so a returning customer stays signed in.
class AuthProvider extends ChangeNotifier {
  AuthProvider({required CommerceApi api, SharedPreferences? preferences})
    : _api = api,
      _preferences = preferences;

  final CommerceApi _api;
  final SharedPreferences? _preferences;

  static const _tokenKey = 'boutique.auth.token';
  static const _userKey = 'boutique.auth.user';

  String? _token;
  String? _name;
  String? _email;
  bool _busy = false;
  String? _error;
  bool _restored = false;

  bool get isSignedIn => _token != null;
  String? get token => _token;
  String? get name => _name;
  String? get email => _email;
  bool get busy => _busy;
  String? get error => _error;

  /// Re-reads a persisted session. Safe to call more than once.
  Future<void> restore() async {
    if (_restored) return;
    _restored = true;
    final token = _preferences?.getString(_tokenKey);
    if (token == null || token.isEmpty) return;

    _token = token;
    _api.useToken(token);
    _name = _preferences?.getString('$_userKey.name');
    _email = _preferences?.getString('$_userKey.email');
    notifyListeners();

    // Confirm the token is still valid; a revoked or expired token signs out
    // rather than failing later at checkout.
    try {
      final profile = await _api.profile();
      _name = profile.name;
      _email = profile.email;
      await _persistUser();
      notifyListeners();
    } on AuthExpired {
      await signOut();
    } on CommerceException {
      // Network is down. Keep the cached session so the customer can retry.
    }
  }

  Future<bool> signIn(String email, String password) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _api.login(email: email, password: password);
      await _applySession(session);
      return true;
    } on CommerceException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    String? phone,
  }) async {
    if (_busy) return false;
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      final session = await _api.register(
        name: name,
        email: email,
        password: password,
        passwordConfirmation: passwordConfirmation,
        phone: phone,
      );
      await _applySession(session);
      return true;
    } on CommerceException catch (e) {
      _error = e.message;
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _api.logout();
    } catch (_) {
      // Even if the server call fails, the local session must be cleared.
    }
    _token = null;
    _name = null;
    _email = null;
    _error = null;
    await _preferences?.remove(_tokenKey);
    await _preferences?.remove('$_userKey.name');
    await _preferences?.remove('$_userKey.email');
    notifyListeners();
  }

  Future<void> _applySession(Session session) async {
    _token = session.token;
    _name = session.name;
    _email = session.email;
    _error = null;
    await _preferences?.setString(_tokenKey, session.token);
    await _persistUser();
    notifyListeners();
  }

  Future<void> _persistUser() async {
    if (_name != null) await _preferences?.setString('$_userKey.name', _name!);
    if (_email != null) {
      await _preferences?.setString('$_userKey.email', _email!);
    }
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}
