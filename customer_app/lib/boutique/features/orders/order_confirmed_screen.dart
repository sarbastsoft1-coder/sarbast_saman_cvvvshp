import 'package:flutter/material.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/store_components.dart';

/// Post-checkout success — HTML `#placed`.
class OrderConfirmedScreen extends StatelessWidget {
  const OrderConfirmedScreen({super.key, required this.order});
  final BoutiqueOrder order;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: p.soft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 44,
                  color: p.brand2,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'داواکارییەکەت نێردرا',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: p.fg,
                ),
              ),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    color: p.muted,
                  ),
                  children: [
                    const TextSpan(text: 'ژمارەی داواکاری '),
                    TextSpan(
                      text: order.id,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w700,
                        color: p.fg,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 22),
              RoniCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.statusLabel.isEmpty
                                ? 'سبەی دەگات'
                                : order.statusLabel,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'بەیانی وێنەی کاڵاکەت بۆ دەنێرین. پارە تەنها لە دەرگا دەدەیت.',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              height: 1.6,
                              color: p.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.local_shipping_outlined,
                      color: p.brand2,
                      size: 26,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              GoldButton(
                label: 'بینینی داواکاری',
                onPressed: () => Navigator.of(context).pushReplacementNamed(
                  BoutiqueRoutes.orderTracking,
                  arguments: order,
                ),
              ),
              const SizedBox(height: 10),
              GhostButton(
                label: 'گەڕانەوە بۆ سەرەکی',
                onPressed: () => BoutiqueRoutes.openTab(context, 0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
