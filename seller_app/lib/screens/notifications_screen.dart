import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../models/notification.dart';
import '../providers/notification_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';

/// The studio notification feed: newest first, swipe to dismiss, tap to open
/// whatever the row's `action_route` points at.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _provider = NotificationProvider.instance;

  /// The shell routes a studio notification may point at.
  static const _knownRoutes = {
    '/dashboard',
    '/orders',
    '/products',
    '/profile',
  };

  Future<void> _refresh() async {
    await _provider.refresh(full: true);
  }

  void _markAllAsRead() {
    _provider.markAllAsRead();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('All notifications marked as read')));
  }

  void _open(AppNotification notification) {
    _provider.markAsRead(notification.id);

    final route = notification.actionRoute;
    if (route == null || route.isEmpty) return;

    if (!_knownRoutes.contains(route)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('$route is not part of the studio app')));
      return;
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationScope(
      provider: _provider,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            if (_provider.unreadCount > 0)
              TextButton(
                onPressed: _markAllAsRead,
                child: const Text('Mark all read'),
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: ListenableBuilder(
          listenable: _provider,
          builder: (context, _) {
            final items = _provider.items;

            if (items.isEmpty && _provider.loading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.terracotta),
              );
            }

            if (items.isEmpty) {
              return _provider.offline
                  ? const SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.cloud_off_rounded,
                        title: 'Cannot reach the server',
                        subtitle:
                            'The studio server did not answer, so there is nothing '
                            'to show yet. Pull down to try again.',
                      ),
                    )
                  : const SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.notifications_none_rounded,
                        title: 'No notifications yet',
                        subtitle:
                            'New orders and cancellations will show up here.',
                      ),
                    );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AppColors.terracotta,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: items.length + (_provider.offline ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  // An unreachable server is stated plainly rather than letting
                  // a stale feed look authoritative.
                  if (_provider.offline && i == 0) {
                    return const _OfflineBanner();
                  }
                  final notification = items[_provider.offline ? i - 1 : i];
                  return _NotificationCard(
                    notification: notification,
                    onTap: () => _open(notification),
                    onDismiss: () => _provider.remove(notification.id),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  final AppNotification notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final accent = notification.type.accent;
    final isRead = notification.isRead;

    return Dismissible(
      key: ValueKey('notification-${notification.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 22),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      child: GlassCard(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        borderColor: isRead
            ? AppColors.border
            : AppColors.terracotta.withValues(alpha: 0.35),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notification.type.icon, color: accent, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            color: AppColors.forest,
                            fontWeight:
                                isRead ? FontWeight.w600 : FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          margin: const EdgeInsets.only(left: 8, top: 4),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.terracotta,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          notification.type.label.toUpperCase(),
                          style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (notification.timeAgo.isNotEmpty)
                        Text(
                          notification.timeAgo,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      const Spacer(),
                      if (notification.actionLabel != null)
                        Row(
                          children: [
                            Text(
                              notification.actionLabel!,
                              style: const TextStyle(
                                color: AppColors.terracotta,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.terracotta, size: 16),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: AppColors.warning),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cannot reach the server - showing the last known feed',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
