import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/notification.dart';
import '../services/api_service.dart';

/// Raised when the notification endpoints cannot be reached, or answer with an
/// error status. The feed keeps whatever it already had and flags itself as
/// offline, so a failed poll never looks like an empty inbox.
class NotificationApiException implements Exception {
  const NotificationApiException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// One page of `GET /notifications`.
class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.unreadCount,
    required this.latestId,
  });

  final List<AdminNotification> items;
  final int unreadCount;

  /// Highest id the server holds for this user – the polling cursor.
  final int latestId;
}

/// Thin wrapper over [ApiService] for the `/notifications` endpoints. Reuses the
/// existing bearer token, so there is no second HTTP client in this app.
class NotificationApi {
  const NotificationApi();

  Future<NotificationPage> feed({int? sinceId, int limit = 50}) async {
    final query = <String, String>{
      'limit': '$limit',
      // A cursor of 0 would ask for "everything newer than id 0", which is a
      // full reload; only send it once we actually know a high-water mark.
      if (sinceId != null && sinceId > 0) 'since_id': '$sinceId',
    };
    final suffix = Uri(queryParameters: query).query;

    try {
      final res = await ApiService.get('/notifications?$suffix');
      if (res['status'] != 'success') {
        throw NotificationApiException(
          res['message']?.toString() ?? 'Notification feed unavailable.',
        );
      }
      final rows = (res['data'] as List?) ?? const [];
      return NotificationPage(
        items: rows
            .whereType<Map<String, dynamic>>()
            .map(AdminNotification.fromJson)
            .toList(),
        unreadCount: _asInt(res['unread_count']),
        latestId: _asInt(res['latest_id']),
      );
    } on NotificationApiException {
      rethrow;
    } catch (_) {
      throw const NotificationApiException(
        'Could not reach the admin server.',
      );
    }
  }

  Future<void> markAsRead(int id) =>
      ApiService.post('/notifications/$id/read', {});

  Future<void> markAllAsRead() =>
      ApiService.post('/notifications/read-all', {});

  Future<void> remove(int id) => ApiService.delete('/notifications/$id');

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}

/// The in-app notification feed, backed by the Laravel `notifications` table.
///
/// The panel polls the server instead of registering with a push service, so
/// there is no device token and no push SDK anywhere in this app. Read state
/// lives on the server, which means it follows the admin to another device.
class NotificationProvider extends ChangeNotifier {
  NotificationProvider({NotificationApi? api})
    : _api = api ?? const NotificationApi();

  /// The single app-wide feed. Sign-in starts it, sign-out clears it.
  static final NotificationProvider instance = NotificationProvider();

  /// How often the feed refreshes while a session is active.
  static const Duration pollInterval = Duration(seconds: 30);

  /// Cap on rows kept in memory; the feed only ever shows the newest page.
  static const int maxItems = 200;

  final NotificationApi _api;

  final List<AdminNotification> _items = [];
  int _unreadCount = 0;
  int _cursor = 0;
  bool _loading = false;
  bool _offline = false;
  bool _disposed = false;
  Timer? _timer;

  /// Newest first.
  List<AdminNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _unreadCount;

  bool get loading => _loading;

  /// True when the last poll could not reach the server. The UI states this
  /// rather than showing a stale or empty feed as if it were authoritative.
  bool get offline => _offline;

  bool get isPolling => _timer != null;

  /// Fetches the feed. Pass `full: true` to reload from scratch (first load or
  /// a reconnect); otherwise only rows newer than the cursor are requested.
  Future<void> refresh({bool full = false}) async {
    if (_loading) return;
    _loading = true;
    _notify();

    try {
      final page = await _api.feed(sinceId: full ? null : _cursor, limit: 50);

      if (full) {
        _items
          ..clear()
          ..addAll(page.items);
      } else {
        for (final incoming in page.items) {
          _items.removeWhere((n) => n.id == incoming.id);
          _items.insert(0, incoming);
        }
      }
      _items.sort((a, b) => b.id.compareTo(a.id));
      if (_items.length > maxItems) {
        _items.removeRange(maxItems, _items.length);
      }

      if (page.latestId > _cursor) _cursor = page.latestId;
      _unreadCount = page.unreadCount;
      _offline = false;
    } on NotificationApiException {
      // Keep whatever is already on screen; the next poll catches up.
      _offline = true;
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// Starts polling and does one immediate load. Safe to call repeatedly –
  /// only ever one timer runs.
  void startPolling() {
    if (_timer != null) return;
    _timer = Timer.periodic(pollInterval, (_) => refresh());
    refresh(full: true);
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Drops the feed when a session ends, so the next account signed in on this
  /// device never sees the previous admin's notifications.
  void reset() {
    stopPolling();
    _items.clear();
    _unreadCount = 0;
    _cursor = 0;
    _loading = false;
    _offline = false;
    _notify();
  }

  /// Optimistic: the row reads as read immediately, the POST follows.
  void markAsRead(int id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].isRead) return;

    _items[index] = _items[index].copyWith(readAt: DateTime.now());
    if (_unreadCount > 0) _unreadCount -= 1;
    _notify();

    // Never block the UI on the network; a later full poll reconciles.
    _api.markAsRead(id).catchError((_) {});
  }

  /// Optimistic, same as [markAsRead] but for the whole feed.
  void markAllAsRead() {
    if (_unreadCount == 0 && _items.every((n) => n.isRead)) return;

    final now = DateTime.now();
    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) _items[i] = _items[i].copyWith(readAt: now);
    }
    _unreadCount = 0;
    _notify();

    _api.markAllAsRead().catchError((_) {});
  }

  /// Dismisses a row. Hidden locally straight away; the server drops it too.
  void remove(int id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1) return;
    if (!_items[index].isRead && _unreadCount > 0) _unreadCount -= 1;
    _items.removeAt(index);
    _notify();

    _api.remove(id).catchError((_) {});
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    stopPolling();
    super.dispose();
  }
}

/// Makes [NotificationProvider] readable from anywhere in the widget tree and
/// rebuilds the widgets that depend on it when the feed changes. Hand-rolled on
/// [InheritedNotifier] so the app needs no state-management package.
class NotificationScope extends InheritedNotifier<NotificationProvider> {
  const NotificationScope({
    super.key,
    required NotificationProvider provider,
    required super.child,
  }) : super(notifier: provider);

  /// Reads the provider and subscribes the calling widget to its updates.
  static NotificationProvider watch(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<NotificationScope>()
            ?.notifier ??
        NotificationProvider.instance;
  }
}
