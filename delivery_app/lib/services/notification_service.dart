import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';

/// A courier alert delivered by the server, e.g. a new pickup job.
///
/// Alerts arrive by polling the server's `notifications` table. There is no
/// push service or device token involved.
class CourierNotification {
  const CourierNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
  });

  final int id;
  final String title;
  final String body;
  final bool isRead;

  factory CourierNotification.fromJson(Map<String, dynamic> json) =>
      CourierNotification(
        id: (json['id'] as num).toInt(),
        title: json['title']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        isRead: json['read_at'] != null,
      );
}

/// Polls the courier alert feed and exposes the unread count to the dashboard.
class NotificationService extends ChangeNotifier {
  /// Same cadence as the task list so a new job and its alert arrive together.
  static const pollInterval = Duration(seconds: 30);

  Timer? _timer;
  bool _busy = false;
  int _cursor = 0;
  int _unread = 0;
  CourierNotification? _latest;
  bool _unreachable = false;

  int get unreadCount => _unread;
  CourierNotification? get latest => _latest;

  /// True when the last poll could not reach the server, so the UI can say so
  /// instead of implying there is simply nothing new.
  bool get unreachable => _unreachable;

  void start() {
    refresh();
    _timer?.cancel();
    _timer = Timer.periodic(pollInterval, (_) => refresh());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> refresh() async {
    if (_busy) return;
    _busy = true;
    try {
      // Only ask for rows newer than the last one we saw.
      final result = await ApiService.get(
        _cursor > 0 ? '/notifications?since_id=$_cursor' : '/notifications',
      );

      if (result['status'] != 'success') {
        _unreachable = true;
        return;
      }

      final rows = (result['data'] as List?) ?? const [];
      for (final row in rows) {
        final alert = CourierNotification.fromJson(
          Map<String, dynamic>.from(row as Map),
        );
        _latest ??= alert;
      }

      final latestId = (result['latest_id'] as num?)?.toInt() ?? _cursor;
      if (latestId > _cursor) _cursor = latestId;
      _unread = (result['unread_count'] as num?)?.toInt() ?? 0;
      _unreachable = false;
    } catch (_) {
      // Offline: keep the last known count rather than showing a false zero.
      _unreachable = true;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    _unread = 0;
    notifyListeners();
    try {
      await ApiService.post('/notifications/read-all', {});
    } catch (_) {
      // The next poll restores the true count.
    }
  }

  /// Clears state so a different courier account never sees stale alerts.
  void reset() {
    stop();
    _cursor = 0;
    _unread = 0;
    _latest = null;
    _unreachable = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}
