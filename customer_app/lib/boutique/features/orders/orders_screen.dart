import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

/// Orders is a pushed page from Account (HTML IA); header without shell tab.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  /// `null` means "all"; otherwise the list is narrowed to that status.
  OrderStatus? _status;

  void _track(BuildContext context, BoutiqueOrder order) => Navigator.pushNamed(
    context,
    BoutiqueRoutes.orderTracking,
    arguments: order,
  );

  /// Refills the cart with the order's lines, then opens the cart page.
  void _reorder(BuildContext context, BoutiqueOrder order) {
    final cart = context.read<CartProvider>();
    for (final line in order.items) {
      cart.add(
        line.product,
        qty: line.quantity,
        size: line.size,
        color: line.color,
      );
    }
    showRoniToast(context, 'خرایە ناو سەبەتە');
    BoutiqueRoutes.openCart(context);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrdersProvider>();
    final all = provider.orders;
    final orders = all
        .where((o) => _status == null || o.status == _status)
        .toList();

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 28),
          children: [
            _OrdersHeader(
              count: all.length,
              onBack: () => Navigator.of(context).maybePop(),
              onOpenCart: () => BoutiqueRoutes.openCart(context),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: StoreNotice(
                'داواکارییەکانی ئەم وەشانە بۆ پیشاندان و تاقیکردنەوەن.',
              ),
            ),
            const SizedBox(height: 16),
            _StatusFilters(
              selected: _status,
              onSelected: (value) => setState(() => _status = value),
            ),
            const SizedBox(height: 20),
            if (provider.loading && orders.isEmpty)
              const _OrdersSkeleton()
            else if (provider.error != null && orders.isEmpty)
              SizedBox(
                height: 340,
                child: StoreEmpty(
                  title: 'نەتوانرا داواکارییەکان بکرێنەوە',
                  message: provider.error!,
                  icon: Icons.cloud_off_rounded,
                  action: GoldButton(
                    label: 'دووبارە هەوڵدانەوە',
                    icon: Icons.refresh_rounded,
                    expand: false,
                    height: 50,
                    onPressed: () => provider.refreshFromApi(),
                  ),
                ),
              )
            else if (orders.isEmpty)
              SizedBox(
                height: 340,
                child: StoreEmpty(
                  title: _status == null
                      ? 'هیچ داواکارییەک نییە'
                      : 'هیچ داواکارییەک بەم دۆخە نییە',
                  message: 'داواکارییەکانت لێرە دەردەکەون.',
                  icon: Icons.receipt_long_outlined,
                  action: GoldButton(
                    label: 'بینینی بەرهەمەکان',
                    icon: Icons.grid_view_rounded,
                    expand: false,
                    height: 50,
                    onPressed: () => BoutiqueRoutes.openTab(context, 1),
                  ),
                ),
              )
            else
              for (var i = 0; i < orders.length; i++)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: RoniFadeSlide(
                    delay: Duration(milliseconds: 45 * i),
                    child: RoniPressable(
                      scale: .98,
                      child: _OrderCard(
                        order: orders[i],
                        onTap: () => _track(context, orders[i]),
                        onTrack: () => _track(context, orders[i]),
                        onReorder: () => _reorder(context, orders[i]),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// In-page header standing in for the AppBar the other tab screens use.
class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader({
    required this.count,
    required this.onBack,
    required this.onOpenCart,
  });

  final int count;
  final VoidCallback onBack;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Padding(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
    child: Row(
      children: [
        // Back sits on the right in RTL and must point right; `arrow_back` is
        // mirrored by Flutter for the ambient text direction, so it does.
        RoniIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'گەڕانەوە',
          onPressed: onBack,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'داواکاریەکانم',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                count == 0
                    ? 'هێشتا هیچ داواکارییەک نییە'
                    : '$count داواکاری لە تۆمارەکەدا',
                style: TextStyle(
                  fontSize: 12,
                  color: p.muted,
                ),
              ),
            ],
          ),
        ),
        RoniIconButton(
          icon: Icons.shopping_bag_outlined,
          tooltip: 'سەبەتە',
          color: p.brand2,
          onPressed: onOpenCart,
        ),
      ],
    ),
    );
  }
}

/// Horizontally scrollable status filter; the selected chip is gold filled.
class _StatusFilters extends StatelessWidget {
  const _StatusFilters({required this.selected, required this.onSelected});

  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  static const _options = <(OrderStatus?, String)>[
    (null, 'هەموو'),
    (OrderStatus.processing, 'لە پرۆسەدایە'),
    (OrderStatus.onTheWay, 'لە ڕێگادایە'),
    (OrderStatus.delivered, 'گەیەندراو'),
  ];

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 42,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (context, i) {
        final (status, label) = _options[i];
        return _GoldChip(
          label: label,
          selected: selected == status,
          onTap: () => onSelected(status),
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
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          gradient: selected ? BoutiqueColors.goldGradient : null,
          color: selected ? null : p.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? BoutiqueColors.goldDeep : p.line,
          ),
          boxShadow: selected ? BoutiqueColors.barShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            // Dark ink on the gold chip reads better than white on gold.
            color: selected ? p.onGold : p.fg,
          ),
        ),
      ),
    ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onTrack,
    required this.onReorder,
  });

  final BoutiqueOrder order;
  final VoidCallback onTap;
  final VoidCallback onTrack;
  final VoidCallback onReorder;

  static StatusTone _tone(OrderStatus status) => switch (status) {
    OrderStatus.processing => StatusTone.processing,
    OrderStatus.onTheWay => StatusTone.shipped,
    OrderStatus.delivered => StatusTone.delivered,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RoniCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.id,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(order.date, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(label: order.statusLabel, tone: _tone(order.status)),
            ],
          ),
          const SizedBox(height: 16),
          for (final line in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: ProductArtwork(product: line.product),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${line.product.name} × ${line.quantity}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Divider(height: 1),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Text('کۆی گشتی', style: theme.textTheme.bodySmall),
              const Spacer(),
              Text(
                order.formatAmount(order.total),
                style: theme.textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GoldButton(
                  label: 'بەدواداچوون',
                  icon: Icons.local_shipping_outlined,
                  height: 46,
                  onPressed: onTrack,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GhostButton(
                  label: 'دووبارە کڕینەوە',
                  icon: Icons.refresh_rounded,
                  height: 46,
                  onPressed: onReorder,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder that sketches the order card so the page does not jump
/// when the real rows arrive.
class _OrdersSkeleton extends StatelessWidget {
  const _OrdersSkeleton();

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    Widget bar({required double height, double? width}) => RoniShimmer(
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: p.soft,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );

    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: RoniCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: bar(height: 16)),
                      const SizedBox(width: 8),
                      bar(height: 24, width: 64),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      RoniShimmer(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.soft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: bar(height: 14)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  bar(height: 18, width: 120),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
