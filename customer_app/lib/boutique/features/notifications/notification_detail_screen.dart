import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/notifications_provider.dart';
import '../../widgets/store_components.dart';

/// Full-page notification detail view. Reached by tapping a row in
/// [NotificationsScreen]. Renders the notification body, time, type chip,
/// and a contextual primary action button when applicable.
class NotificationDetailScreen extends StatefulWidget {
  const NotificationDetailScreen({super.key, required this.notificationId});

  final int notificationId;

  @override
  State<NotificationDetailScreen> createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  @override
  void initState() {
    super.initState();
    // Mark as read on open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NotificationsProvider>().markAsRead(widget.notificationId);
    });
  }

  void _runAction(BoutiqueNotification n) {
    final route = n.actionRoute;
    if (route == null) return;

    if (route == BoutiqueRoutes.home) {
      BoutiqueRoutes.openTab(context, 0);
      return;
    }
    Navigator.of(context).pushNamed(route, arguments: n.actionArgs);
  }

  @override
  Widget build(BuildContext context) {
    final n = context.watch<NotificationsProvider>().byId(
      widget.notificationId,
    );
    if (n == null) return const MissingRouteScreen();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('ئاگادارکردنەوە')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Hero(n: n),
              const SizedBox(height: 22),
              RoniCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel('وردەکاری'),
                    const SizedBox(height: 10),
                    Text(
                      n.body,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (n.actionLabel != null) ...[
                GoldButton(
                  label: n.actionLabel!,
                  icon: Icons.arrow_back_rounded,
                  onPressed: () => _runAction(n),
                ),
                const SizedBox(height: 10),
              ],
              GhostButton(
                label: n.isRead ? 'پاشەکەوتکراوە ✓' : 'نیشانکردن وەک خوێندراوە',
                icon: n.isRead
                    ? Icons.check_circle_rounded
                    : Icons.mark_email_read_outlined,
                onPressed: () =>
                    context.read<NotificationsProvider>().markAsRead(n.id),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon block, title and timestamp — the detail page's visual header.
class _Hero extends StatelessWidget {
  const _Hero({required this.n});

  final BoutiqueNotification n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            color: n.type.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: n.type.color.withValues(alpha: 0.22)),
          ),
          child: Icon(n.type.icon, color: n.type.color, size: 40),
        ),
        const SizedBox(height: 18),
        _TypeChip(type: n.type),
        const SizedBox(height: 12),
        Text(
          n.title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.access_time_rounded,
              size: 14,
              color: BoutiqueColors.muted,
            ),
            const SizedBox(width: 5),
            Text(n.time, style: theme.textTheme.bodySmall),
            if (!n.isRead) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BoutiqueColors.rose,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.type});

  final BoutiqueNotificationType type;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: type.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(type.icon, size: 13, color: type.color),
        const SizedBox(width: 6),
        Text(
          type.label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: type.color,
          ),
        ),
      ],
    ),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontFamily: 'Vazirmatn',
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: BoutiqueColors.muted,
    ),
  );
}
