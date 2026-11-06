import 'package:flutter/material.dart';

import '../main.dart'; // For AdminTheme

/// The categories the backend can emit. A type the admin panel does not know is
/// treated as [AdminNotificationType.system] rather than being dropped, so a row
/// the server really sent is never hidden from the feed.
enum AdminNotificationType { order, promo, system, newProduct }

extension AdminNotificationTypeX on AdminNotificationType {
  IconData get icon {
    switch (this) {
      case AdminNotificationType.order:
        return Icons.receipt_long_rounded;
      case AdminNotificationType.promo:
        return Icons.local_offer_rounded;
      case AdminNotificationType.newProduct:
        return Icons.auto_awesome_rounded;
      case AdminNotificationType.system:
        return Icons.campaign_rounded;
    }
  }

  Color get accent {
    switch (this) {
      case AdminNotificationType.order:
        return AdminTheme.terracotta;
      case AdminNotificationType.promo:
        return AdminTheme.clayOchre;
      case AdminNotificationType.newProduct:
        return AdminTheme.sageGreen;
      case AdminNotificationType.system:
        return AdminTheme.forestGreen;
    }
  }

  String get label {
    switch (this) {
      case AdminNotificationType.order:
        return 'Order';
      case AdminNotificationType.promo:
        return 'Promo';
      case AdminNotificationType.newProduct:
        return 'New product';
      case AdminNotificationType.system:
        return 'Platform';
    }
  }

  static AdminNotificationType parse(String? raw) => switch (raw) {
        'order' => AdminNotificationType.order,
        'promo' => AdminNotificationType.promo,
        'new_product' => AdminNotificationType.newProduct,
        _ => AdminNotificationType.system,
      };
}

/// One row of the `/notifications` feed, exactly as the server serialised it.
class AdminNotification {
  const AdminNotification({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.body,
    this.actionLabel,
    this.actionRoute,
    this.actionArgs,
    this.readAt,
    this.createdAt,
  });

  factory AdminNotification.fromJson(Map<String, dynamic> json) {
    return AdminNotification(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      type: AdminNotificationTypeX.parse(json['type']?.toString()),
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      actionLabel: json['action_label']?.toString(),
      actionRoute: json['action_route']?.toString(),
      actionArgs: (json['action_args'] as Map?)?.cast<String, dynamic>(),
      readAt: _asDate(json['read_at']),
      createdAt: _asDate(json['created_at']),
    );
  }

  final int id;
  final int userId;
  final AdminNotificationType type;
  final String title;
  final String body;
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, dynamic>? actionArgs;
  final DateTime? readAt;
  final DateTime? createdAt;

  /// `read_at` is null on the server while the row is unread.
  bool get isRead => readAt != null;

  AdminNotification copyWith({DateTime? readAt}) {
    return AdminNotification(
      id: id,
      userId: userId,
      type: type,
      title: title,
      body: body,
      actionLabel: actionLabel,
      actionRoute: actionRoute,
      actionArgs: actionArgs,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  /// Compact age label for the list, e.g. `4m ago`.
  String get timeAgo {
    final created = createdAt;
    if (created == null) return '';
    final diff = DateTime.now().difference(created.toLocal());
    if (diff.isNegative || diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return created.toLocal().toIso8601String().substring(0, 10);
  }

  static int _asInt(dynamic value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  static DateTime? _asDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse('$value');
  }
}
