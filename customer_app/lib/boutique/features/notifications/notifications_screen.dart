import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/store_components.dart';

/// Client-side feed filters. Each maps onto one notification category so a
/// row can always be reached, whichever chip the customer picks.
enum _Feed { all, orders, coins, offers, products }

extension _FeedX on _Feed {
  /// `null` keeps every category visible.
  BoutiqueNotificationType? get type => switch (this) {
    _Feed.all => null,
    _Feed.orders => BoutiqueNotificationType.order,
    _Feed.coins => BoutiqueNotificationType.system,
    _Feed.offers => BoutiqueNotificationType.promo,
    _Feed.products => BoutiqueNotificationType.newProduct,
  };

  String get label => switch (this) {
    _Feed.all => 'هەموو',
    _Feed.orders => 'داواکارییەکان',
    _Feed.coins => 'کۆینەکان',
    _Feed.offers => 'ئۆفەرەکان',
    _Feed.products => 'بەرهەمی نوێ',
  };
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  _Feed _feed = _Feed.all;

  void _markAllAsRead(BuildContext context) {
    context.read<NotificationsProvider>().markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: BoutiqueColors.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        content: const Text(
          'هەموو ئاگادارکردنەوەکان خوێندرانەوە ✓',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: BoutiqueColors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationsProvider>();
    final visible = provider.visibleItems(context.watch<SettingsProvider>());
    final items = _feed.type == null
        ? visible
        : visible.where((n) => n.type == _feed.type).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _FeedHeader(
                unread: provider.unreadCount,
                onMarkAllRead: () => _markAllAsRead(context),
              ),
              _FeedFilters(
                selected: _feed,
                onSelected: (value) => setState(() => _feed = value),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: items.isEmpty
                    ? (provider.offline
                          ? const _OfflineState()
                          : _EmptyState(filtered: _feed != _Feed.all))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                        itemCount: items.length + (provider.offline ? 1 : 0),
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          // An unreachable server is stated plainly rather
                          // than letting a stale feed look like "nothing new".
                          if (provider.offline && i == 0) {
                            return const _OfflineBanner();
                          }
                          final item = items[provider.offline ? i - 1 : i];
                          return _NotificationCard(
                            item: item,
                            onTap: () => Navigator.of(context).pushNamed(
                              BoutiqueRoutes.notificationDetail,
                              arguments: item.id,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-page header with the back affordance this pushed page still needs.
class _FeedHeader extends StatelessWidget {
  const _FeedHeader({required this.unread, required this.onMarkAllRead});

  final int unread;
  final VoidCallback onMarkAllRead;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
    child: Row(
      children: [
        RoniIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'گەڕانەوە',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ئاگادارکردنەوەکان',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                unread == 0
                    ? 'هەموویان خوێندراوەتەوە'
                    : '$unread پەیامی نوێت هەیە',
                style: const TextStyle(
                  fontSize: 12,
                  color: BoutiqueColors.muted,
                ),
              ),
            ],
          ),
        ),
        if (unread > 0)
          TextButton(
            onPressed: onMarkAllRead,
            style: TextButton.styleFrom(
              foregroundColor: BoutiqueColors.dustyPink,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'هەمووی بخوێنەوە',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: BoutiqueColors.dustyPink,
              ),
            ),
          ),
      ],
    ),
  );
}

class _FeedFilters extends StatelessWidget {
  const _FeedFilters({required this.selected, required this.onSelected});

  final _Feed selected;
  final ValueChanged<_Feed> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _Feed.values.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final feed = _Feed.values[i];
        return _GoldChip(
          label: feed.label,
          selected: feed == selected,
          onTap: () => onSelected(feed),
        );
      },
    ),
  );
}

class _GoldChip extends StatelessWidget {
  const _GoldChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? BoutiqueColors.goldGradient : null,
          color: selected ? null : BoutiqueColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? BoutiqueColors.goldDeep : BoutiqueColors.border,
          ),
          boxShadow: selected ? BoutiqueColors.barShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected
                ? BoutiqueColors.white
                : BoutiqueColors.softCharcoal,
          ),
        ),
      ),
    ),
  );
}

/// (foreground, wash) pair for the round icon tile.
(Color, Color) _accentFor(BoutiqueNotificationType type) => switch (type) {
  BoutiqueNotificationType.order => (
    BoutiqueColors.statusShipped,
    BoutiqueColors.statusShippedWash,
  ),
  BoutiqueNotificationType.promo => (
    BoutiqueColors.rose,
    BoutiqueColors.statusCancelledWash,
  ),
  BoutiqueNotificationType.newProduct => (
    BoutiqueColors.dustyPink,
    BoutiqueColors.goldWash,
  ),
  BoutiqueNotificationType.system => (
    BoutiqueColors.goldDeep,
    BoutiqueColors.goldWash,
  ),
};

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final BoutiqueNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (foreground, wash) = _accentFor(item.type);
    return RoniCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      // Unread rows keep their lift and gold edge; read rows settle back.
      shadow: !item.isRead,
      borderColor: item.isRead
          ? BoutiqueColors.border
          : BoutiqueColors.gold.withValues(alpha: 0.55),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: wash, shape: BoxShape.circle),
            child: Icon(item.type.icon, color: foreground, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: item.isRead
                              ? FontWeight.w600
                              : FontWeight.w700,
                          color: item.isRead
                              ? BoutiqueColors.softCharcoal
                              : BoutiqueColors.charcoal,
                        ),
                      ),
                    ),
                    if (!item.isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: BoutiqueColors.rose,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  item.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(item.time, style: theme.textTheme.bodySmall),
                    const Spacer(),
                    const Icon(
                      Icons.chevron_left_rounded,
                      size: 16,
                      color: BoutiqueColors.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineState extends StatelessWidget {
  const _OfflineState();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 48, color: BoutiqueColors.muted),
          SizedBox(height: 16),
          Text(
            'چوونەژوورەوە بکە بۆ بینینی ئاگادارکردنەوەکان',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: BoutiqueColors.charcoal,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'ئاگادارکردنەوەکان بۆ هەر هەژمارێک لەسەر ڕاژەکە هەڵدەگیرێن.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12.5,
              height: 1.7,
              color: BoutiqueColors.muted,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Shown at the top of the feed when the last poll could not reach the server.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  @override
  Widget build(BuildContext context) => RoniCard(
    padding: const EdgeInsets.all(14),
    color: BoutiqueColors.statusCancelledWash,
    borderColor: BoutiqueColors.statusCancelled.withValues(alpha: 0.25),
    shadow: false,
    child: const Row(
      children: [
        Icon(Icons.wifi_off_rounded, size: 18, color: BoutiqueColors.rose),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'پەیوەندی بە ڕاژاکە نییە • ئەم پەیامانەی پێشوو نیشان دەدرێن',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 12,
              height: 1.6,
              color: BoutiqueColors.rose,
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filtered});

  /// True when the feed is empty only because a filter chip is active.
  final bool filtered;

  @override
  Widget build(BuildContext context) => StoreEmpty(
    title: filtered
        ? 'هیچ پەیامێک بەم بەشە نییە'
        : 'هیچ ئاگادارکردنەوەیەک نییە',
    message: filtered
        ? 'بەشێکی تر هەڵبژێرە بۆ بینینی پەیامەکانی تر.'
        : 'ئاگادارکردنەوەکانت لێرە دەردەکەون.',
    icon: Icons.notifications_none_rounded,
  );
}
