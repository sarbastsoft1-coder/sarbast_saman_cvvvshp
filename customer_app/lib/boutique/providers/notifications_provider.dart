import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/boutique_colors.dart';
import '../services/commerce_api.dart';
import 'settings_provider.dart';

enum BoutiqueNotificationType { promo, order, system, newProduct }

extension BoutiqueNotificationTypeX on BoutiqueNotificationType {
  IconData get icon {
    switch (this) {
      case BoutiqueNotificationType.promo:
        return Icons.local_offer_rounded;
      case BoutiqueNotificationType.order:
        return Icons.local_shipping_rounded;
      case BoutiqueNotificationType.system:
        return Icons.card_giftcard_rounded;
      case BoutiqueNotificationType.newProduct:
        return Icons.auto_awesome_rounded;
    }
  }

  Color get color {
    switch (this) {
      case BoutiqueNotificationType.promo:
        return BoutiqueColors.rose;
      case BoutiqueNotificationType.order:
        return const Color(0xFF4A7BD0);
      case BoutiqueNotificationType.system:
        return BoutiqueColors.gold;
      case BoutiqueNotificationType.newProduct:
        return BoutiqueColors.dustyPink;
    }
  }

  String get label {
    switch (this) {
      case BoutiqueNotificationType.promo:
        return 'داشکاندن';
      case BoutiqueNotificationType.order:
        return 'داواکاری';
      case BoutiqueNotificationType.system:
        return 'سیستەم';
      case BoutiqueNotificationType.newProduct:
        return 'بەرهەمی نوێ';
    }
  }

  /// Maps a server `type` string onto the app's four categories. Anything the
  /// backend does not know about is treated as a system message.
  static BoutiqueNotificationType parse(String raw) => switch (raw) {
    'order' => BoutiqueNotificationType.order,
    'promo' => BoutiqueNotificationType.promo,
    'new_product' => BoutiqueNotificationType.newProduct,
    _ => BoutiqueNotificationType.system,
  };
}

class BoutiqueNotification {
  final int id;
  final String title;
  final String body;
  final String time;
  final BoutiqueNotificationType type;
  final bool isRead;
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, dynamic>? actionArgs;

  const BoutiqueNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    this.isRead = false,
    this.actionLabel,
    this.actionRoute,
    this.actionArgs,
  });

  BoutiqueNotification copyWith({bool? isRead}) {
    return BoutiqueNotification(
      id: id,
      title: title,
      body: body,
      time: time,
      type: type,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
      actionArgs: actionArgs,
    );
  }
}

/// The in-app notification feed, backed by the Laravel `notifications` table.
///
/// Clients poll the server rather than registering with a push service, so
/// there is no third-party SDK, no device token and no per-platform setup. A
/// timer refreshes the feed while the app is open; read state lives on the
/// server so it follows the customer to another device.
class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({CommerceApi? api, SharedPreferences? preferences})
    : _api = api,
      _preferences = preferences {
    // A null api means there is no server to talk to (tests, or a build with
    // no backend); the feed then stays empty instead of throwing.
    if (_api == null) _offline = true;
    // Read state is optimistic: show what we know from the last successful
    // fetch, then reconcile with the server on the first poll.
    final cached = _preferences?.getStringList(_readCacheKey) ?? const [];
    for (final raw in cached) {
      final id = int.tryParse(raw);
      if (id != null) _locallyRead.add(id);
    }
  }

  static const _readCacheKey = 'boutique.notifications.read.v1';

  /// How often the feed refreshes while the app is open.
  static const pollInterval = Duration(seconds: 30);

  final CommerceApi? _api;
  final SharedPreferences? _preferences;

  final List<BoutiqueNotification> _items = [];
  final Set<int> _locallyRead = {};
  Timer? _timer;
  bool _loading = false;
  bool _disposed = false;
  int _generation = 0;
  bool _offline = false;

  /// Cursor for incremental polling: only ids greater than this are fetched.
  int _cursor = 0;

  List<BoutiqueNotification> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  /// True when the last poll failed, so the UI can say the feed is stale
  /// instead of pretending there is simply nothing new.
  bool get offline => _offline;

  List<BoutiqueNotification> visibleItems(SettingsProvider settings) =>
      !settings.notificationsEnabled
      ? []
      : _items
            .where(
              (n) => switch (n.type) {
                BoutiqueNotificationType.order => settings.orderUpdates,
                BoutiqueNotificationType.promo => settings.promoUpdates,
                BoutiqueNotificationType.newProduct => settings.productUpdates,
                BoutiqueNotificationType.system => true,
              },
            )
            .toList();

  int get unreadCount => _items.where((n) => !n.isRead).length;

  BoutiqueNotification? byId(int id) =>
      _items.where((n) => n.id == id).firstOrNull;

  /// Fetches the feed. Pass `full: true` to reload from scratch (first load,
  /// sign-in, or after a reconnect); otherwise only newer rows are requested.
  Future<void> refresh({bool full = false}) async {
    if (_loading) return;
    final api = _api;
    if (api == null) {
      // No backend configured: nothing to poll.
      return;
    }
    final generation = _generation;
    _loading = true;
    if (full) _items.clear();
    notifyListeners();

    try {
      final page = await api.notifications(
        sinceId: full ? null : _cursor,
        limit: 50,
      );

      if (_disposed || generation != _generation) return;
      if (full) _items.clear();
      for (final incoming in page.items) {
        _items.removeWhere((n) => n.id == incoming.id);
        _items.insert(
          0,
          BoutiqueNotification(
            id: incoming.id,
            title: incoming.title,
            body: incoming.body,
            time: _relativeTime(incoming.createdAt),
            type: BoutiqueNotificationTypeX.parse(incoming.type),
            // Read state is authoritative on the server; the local cache only
            // covers rows we have not seen the server's answer for yet.
            isRead: incoming.isRead || _locallyRead.contains(incoming.id),
            actionLabel: incoming.actionLabel,
            actionRoute: incoming.actionRoute,
            actionArgs: incoming.actionArgs,
          ),
        );
      }
      _items.sort((a, b) => b.id.compareTo(a.id));
      _cursor = page.latestId > _cursor ? page.latestId : _cursor;
      _offline = false;
    } on CommerceException {
      // Keep whatever is on screen; the next poll will catch up.
      if (!_disposed && generation == _generation) _offline = true;
    } finally {
      if (!_disposed && generation == _generation) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  /// Starts polling. Safe to call repeatedly; only one timer runs.
  void startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
  }

  void stopPolling() {
    _timer?.cancel();
    _timer = null;
  }

  /// Drops the local feed when a session ends, so the next account does not
  /// briefly see the previous customer's notifications.
  void reset() {
    ++_generation;
    _loading = false;
    stopPolling();
    _items.clear();
    _locallyRead.clear();
    _cursor = 0;
    _offline = false;
    _preferences?.remove(_readCacheKey);
    notifyListeners();
  }

  void markAsRead(int id) {
    final index = _items.indexWhere((n) => n.id == id);
    if (index == -1 || _items[index].isRead) return;

    // Show it as read immediately, then confirm with the server.
    _items[index] = _items[index].copyWith(isRead: true);
    _locallyRead.add(id);
    _persistReadCache();
    notifyListeners();

    _api?.markNotificationRead(id).catchError((_) {
      // Offline: keep the optimistic state and let the next full refresh
      // correct it rather than bouncing the notification back.
    });
  }

  void markAllAsRead() {
    final unread = _items.where((n) => !n.isRead).toList();
    if (unread.isEmpty) return;

    for (var i = 0; i < _items.length; i++) {
      if (!_items[i].isRead) {
        _items[i] = _items[i].copyWith(isRead: true);
        _locallyRead.add(_items[i].id);
      }
    }
    _persistReadCache();
    notifyListeners();

    _api?.markAllNotificationsRead().catchError((_) {});
  }

  Future<void> remove(int id) async {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
    try {
      await _api?.deleteNotification(id);
    } on CommerceException {
      // Leave it hidden locally; a later full refresh restores it if the
      // server still has it.
    }
  }

  void _persistReadCache() {
    // Keep the cache small: only the most recent ids are worth remembering.
    final recent = _locallyRead.toList()..sort((a, b) => b.compareTo(a));
    _preferences?.setStringList(
      _readCacheKey,
      recent.take(200).map((id) => '$id').toList(),
    );
  }

  /// Kurdish relative time, matching the tone of the rest of the storefront.
  static String _relativeTime(DateTime? createdAt) {
    if (createdAt == null) return '';
    final diff = DateTime.now().difference(createdAt.toLocal());

    if (diff.inMinutes < 1) return 'ئێستا';
    if (diff.inMinutes < 60) return '${diff.inMinutes} خولەک لەمەوبەر';
    if (diff.inHours < 24) return '${diff.inHours} کاتژمێر لەمەوبەر';
    if (diff.inDays == 1) return 'دوێنێ';
    if (diff.inDays < 7) return '${diff.inDays} ڕۆژ لەمەوبەر';
    return createdAt.toLocal().toIso8601String().substring(0, 10);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    stopPolling();
    super.dispose();
  }
}
