import 'package:flutter/material.dart';

import '../app/theme.dart';

/// The categories the backend can emit. A type the studio app does not know is
/// treated as [AppNotificationType.system] rather than being dropped, so a row
/// the server really sent is never hidden from the feed.
enum AppNotificationType { order, promo, system, newProduct }

extension AppNotificationTypeX on AppNotificationType {
  IconData get icon {
    switch (this) {
      case AppNotificationType.order:
        return Icons.receipt_long_rounded;
      case AppNotificationType.promo:
        return Icons.local_offer_rounded;
      case AppNotificationType.newProduct:
        return Icons.auto_awesome_rounded;
      case AppNotificationType.system:
        return Icons.campaign_rounded;
    }
  }

  Color get accent {
    switch (this) {
      case AppNotificationType.order:
        return AppColors.terracotta;
      case AppNotificationType.promo:
        return AppColors.clayOchre;
      case AppNotificationType.newProduct:
        return AppColors.sage;
      case AppNotificationType.system:
        return AppColors.forest;
    }
  }

  String get label {
    switch (this) {
      case AppNotificationType.order:
        return 'Order';
      case AppNotificationType.promo:
        return 'Promo';
      case AppNotificationType.newProduct:
        return 'New product';
      case AppNotificationType.system:
        return 'Studio';
    }
  }

  static AppNotificationType parse(String? raw) => switch (raw) {
        'order' => AppNotificationType.order,
        'promo' => AppNotificationType.promo,
        'new_product' => AppNotificationType.newProduct,
        _ => AppNotificationType.system,
      };
}

/// One row of the `/notifications` feed, exactly as the server serialised it.
class AppNotification {
  const AppNotification({
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

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: _asInt(json['id']),
      userId: _asInt(json['user_id']),
      type: AppNotificationTypeX.parse(json['type']?.toString()),
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
  final AppNotificationType type;
  final String title;
  final String body;
  final String? actionLabel;
  final String? actionRoute;
  final Map<String, dynamic>? actionArgs;
  final DateTime? readAt;
  final DateTime? createdAt;

  /// `read_at` is null on the server while the row is unread.
  bool get isRead => readAt != null;

  AppNotification copyWith({DateTime? readAt}) {
    return AppNotification(
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
