import 'package:flutter/material.dart';

import '../main.dart'; // For AdminTheme
import '../providers/notification_provider.dart';

/// The small count bubble that sits on the navigation rail and the bell.
class UnreadBadge extends StatelessWidget {
  const UnreadBadge({super.key, required this.count, this.color});

  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final accent = color ?? AdminTheme.terracotta;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: count > 9 ? 5 : 0),
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      decoration: BoxDecoration(
        color: accent,
        borderRadius: BorderRadius.circular(999),
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Bell that opens the notification feed, carrying the live unread count.
///
/// It subscribes to the provider itself, so a poll repaints only the badge
/// instead of the screen that hosts it.
class NotificationBellButton extends StatelessWidget {
  const NotificationBellButton({
    super.key,
    required this.onPressed,
    this.iconColor,
    this.badgeColor,
  });

  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? badgeColor;

  @override
  Widget build(BuildContext context) {
    final count = NotificationScope.watch(context).unreadCount;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(
            count > 0
                ? Icons.notifications_rounded
                : Icons.notifications_none_rounded,
            color: iconColor ?? Colors.white,
          ),
          if (count > 0)
            Positioned(
              right: -8,
              top: -5,
              child: UnreadBadge(count: count, color: badgeColor),
            ),
        ],
      ),
    );
  }
}

/// Navigation rail icon that carries the unread count, for the destinations
/// notifications can lead to.
class RailBadgeIcon extends StatelessWidget {
  const RailBadgeIcon({
    super.key,
    required this.icon,
    required this.count,
    this.color,
  });

  final IconData icon;
  final int count;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -10,
            top: -4,
            child: UnreadBadge(count: count, color: color),
          ),
      ],
    );
  }
}
