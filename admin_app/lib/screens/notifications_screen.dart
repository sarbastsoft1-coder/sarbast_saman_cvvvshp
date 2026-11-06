import 'package:flutter/material.dart';

import '../main.dart'; // For AdminTheme
import '../models/notification.dart';
import '../providers/notification_provider.dart';

/// The admin notification feed: newest first, swipe to dismiss, tap to open
/// whatever the row's `action_route` points at.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, this.onOpenRoute});

  /// Lets the dashboard act on a route the panel understands (e.g. switching
  /// the navigation rail to the reward tasks tab).
  final ValueChanged<String>? onOpenRoute;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _provider = NotificationProvider.instance;

  Future<void> _refresh() async {
    await _provider.refresh(full: true);
  }

  void _markAllAsRead() {
    _provider.markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _open(AdminNotification notification) {
    _provider.markAsRead(notification.id);

    final route = notification.actionRoute;
    if (route == null || route.isEmpty) return;

    final handler = widget.onOpenRoute;
    if (handler == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$route is not part of the admin panel')),
      );
      return;
    }
    handler(route);
  }

  @override
  Widget build(BuildContext context) {
    return NotificationScope(
      provider: _provider,
      child: Scaffold(
        backgroundColor: AdminTheme.warmSand,
        appBar: AppBar(
          title: const Text('Notifications'),
          actions: [
            ListenableBuilder(
              listenable: _provider,
              builder: (context, _) => _provider.unreadCount > 0
                  ? TextButton(
                      onPressed: _markAllAsRead,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Mark all read'),
                    )
                  : const SizedBox.shrink(),
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
                child: CircularProgressIndicator(color: AdminTheme.terracotta),
              );
            }

            if (items.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _provider.offline
                            ? Icons.cloud_off_rounded
                            : Icons.notifications_none_rounded,
                        size: 48,
                        color: _provider.offline
                            ? AdminTheme.clayOchre
                            : AdminTheme.sageGreen,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _provider.offline
                            ? 'Cannot reach the server'
                            : 'No notifications yet',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AdminTheme.forestGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _provider.offline
                            ? 'The admin server did not answer, so there is '
                                  'nothing to show yet.'
                            : 'Reward submissions and platform activity will '
                                  'show up here.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              color: AdminTheme.terracotta,
              child: ListView.separated(
                padding: const EdgeInsets.all(24),
                itemCount: items.length + (_provider.offline ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  // An unreachable server is stated plainly rather than letting
                  // a stale feed look authoritative.
                  if (_provider.offline && i == 0) return const _OfflineBanner();
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

  final AdminNotification notification;
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
          color: AdminTheme.terracotta.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: AdminTheme.terracotta,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? AdminTheme.earthBorder
                  : AdminTheme.terracotta.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(notification.type.icon, color: accent, size: 20),
              ),
              const SizedBox(width: 14),
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
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,
                              fontSize: 14,
                              color: AdminTheme.forestGreen,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AdminTheme.terracotta,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.body,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            notification.type.label.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (notification.timeAgo.isNotEmpty)
                          Text(
                            notification.timeAgo,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black45,
                            ),
                          ),
                        const Spacer(),
                        if (notification.actionLabel != null)
                          Row(
                            children: [
                              Text(
                                notification.actionLabel!,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: AdminTheme.terracotta,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AdminTheme.terracotta,
                                size: 16,
                              ),
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
        color: AdminTheme.clayOchre.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.clayOchre),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, size: 18, color: AdminTheme.clayOchre),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cannot reach the server - showing the last known feed',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.5,
                color: AdminTheme.clayOchre,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
