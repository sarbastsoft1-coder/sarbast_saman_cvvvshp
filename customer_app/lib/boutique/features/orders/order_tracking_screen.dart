import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_components.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key, required this.order});
  final BoutiqueOrder order;
  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final current = context.watch<OrdersProvider>().byId(order.id) ?? order;
    // The provider exposes a light-mode status colour; map it onto the
    // palette so the label stays legible in the dark theme the app boots in.
    final statusColor = switch (current.status) {
      OrderStatus.processing => p.statusProcessing,
      OrderStatus.onTheWay => p.statusShipped,
      OrderStatus.delivered => p.statusDelivered,
    };
    return Scaffold(
      appBar: AppBar(
        title: const Text('وردەکاری داواکاری'),
        actions: [
          IconButton(
            tooltip: 'هاوبەشکردنی ژمارەی داواکاری',
            icon: const Icon(Icons.share_outlined),
            onPressed: () async {
              try {
                final box = context.findRenderObject() as RenderBox?;
                await Share.share(
                  '${current.id} • ${current.statusLabel} • ${current.formatAmount(current.total)}',
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                );
              } catch (_) {
                await Clipboard.setData(ClipboardData(text: current.id));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('ژمارەی داواکاری کۆپی کرا')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const StoreNotice(
            'داواکاریی پیشاندان • ئەم دۆخە شوێنپێهەڵگرتنی ڕاستەوخۆ نییە و هیچ بەرهەمێک نانێردرێت.',
          ),
          const SizedBox(height: 20),
          StorePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        current.id,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'کۆپیکردنی ژمارەی داواکاری',
                      onPressed: () async {
                        await Clipboard.setData(
                          ClipboardData(text: current.id),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('ژمارەی داواکاری کۆپی کرا'),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy_outlined, size: 18),
                    ),
                  ],
                ),
                Text(
                  current.date,
                  style: TextStyle(
                    color: p.muted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  current.statusLabel,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 20),
                for (var i = 0; i < 5; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Row(
                      children: [
                        Icon(
                          i <= current.trackingStep
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: i <= current.trackingStep
                              ? p.ok
                              : p.line,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          [
                            'تۆمارکرا',
                            'ئامادەکردن',
                            'وەرگرتن لەلایەن شۆفێر',
                            'لە ڕێگادایە',
                            'گەیەندرا',
                          ][i],
                          style: TextStyle(
                            fontWeight: i == current.trackingStep
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: i <= current.trackingStep
                                ? p.fg
                                : p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StorePanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ناونیشانی گەیاندن',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(current.address),
                if (current.phone.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(current.phone, textDirection: TextDirection.ltr),
                ],
                const SizedBox(height: 10),
                Text(
                  current.paymentMethod,
                  style: TextStyle(
                    fontSize: 12,
                    color: p.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          StorePanel(
            child: Column(
              children: [
                for (final line in current.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: ProductArtwork(product: line.product),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${line.product.name} × ${line.quantity}',
                                style: const TextStyle(fontSize: 13),
                              ),
                              Text(
                                line.variantLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: p.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          line.product.formatAmount(line.subtotal),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                _row('کۆی بەرهەمەکان', current.formatAmount(current.subtotal)),
                if (current.discount > 0)
                  _row(
                    'داشکاندن',
                    '−${current.formatAmount(current.discount)}',
                  ),
                _row(
                  'گەیاندن',
                  current.deliveryFee == 0
                      ? 'بێبەرامبەر'
                      : current.formatAmount(current.deliveryFee),
                ),
                const Divider(height: 24),
                _row('کۆی گشتی', current.formatAmount(current.total)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              BoutiqueRoutes.inspect,
              arguments: current,
            ),
            icon: const Icon(Icons.inventory_2_outlined),
            label: const Text('گەیەنەر گەیشت · پشکنین'),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              // Fills with the theme's foreground and labels with its
              // background, so the button reads as a solid block in both the
              // light and the dark theme.
              backgroundColor: p.fg,
              foregroundColor: p.bg,
            ),
            onPressed: () {
              final cart = context.read<CartProvider>();
              for (final item in current.items) {
                cart.add(
                  item.product,
                  qty: item.quantity,
                  size: item.size,
                  color: item.color,
                );
              }
              BoutiqueRoutes.openCart(context);
            },
            icon: const Icon(Icons.shopping_bag_outlined),
            label: const Text('دووبارە زیادکردن بۆ سەبەتە'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(
              context,
              BoutiqueRoutes.complaint,
              arguments: current,
            ),
            child: const Text('کێشەیەکت هەیە؟'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pushNamed(context, BoutiqueRoutes.orders),
            child: const Text('هەموو داواکارییەکان'),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(child: Text(title)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );
}
