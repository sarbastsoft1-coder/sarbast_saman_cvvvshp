import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_components.dart';

class InspectScreen extends StatefulWidget {
  const InspectScreen({super.key, required this.order});
  final BoutiqueOrder order;
  @override
  State<InspectScreen> createState() => _InspectScreenState();
}

class _InspectScreenState extends State<InspectScreen> {
  late final Map<int, bool> _accept;

  @override
  void initState() {
    super.initState();
    _accept = {
      for (var i = 0; i < widget.order.items.length; i++) i: true,
    };
  }

  double get _payTotal {
    var sum = 0.0;
    for (var i = 0; i < widget.order.items.length; i++) {
      if (_accept[i] == true) {
        final line = widget.order.items[i];
        sum += line.product.price * line.quantity;
      }
    }
    return sum + widget.order.deliveryFee;
  }

  String get _code {
    final digits = widget.order.id.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) return digits.substring(digits.length - 4);
    return '4719';
  }

  Future<void> _finish() async {
    context.read<OrdersProvider>().updateOrderStatus(
      widget.order.id,
      OrderStatus.delivered,
      4,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(
      BoutiqueRoutes.rateOrder,
      arguments: widget.order,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(title: const Text('پشکنین لە بەردەم دەرگا')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const StoreNotice(
            'سندوقەکان بکەرەوە و هەر بەرهەمێک بپشکنە. پارە تەنها بۆ ئەوانە دەدەیت کە وەریدەگریت.',
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < widget.order.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RoniCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 40,
                          height: 40,
                          child: ProductArtwork(
                            product: widget.order.items[i].product,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(widget.order.items[i].product.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                widget.order.items[i].product.formatAmount(
                                  widget.order.items[i].product.price * widget.order.items[i].quantity,
                                ),
                                style: const TextStyle(color: BoutiqueColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _Seg(
                            label: 'وەریدەگرم',
                            on: _accept[i] == true,
                            onTap: () => setState(() => _accept[i] = true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _Seg(
                            label: 'ڕەتی دەکەمەوە',
                            on: _accept[i] == false,
                            onTap: () => setState(() => _accept[i] = false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          RoniCard(
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('بیدە بە گەیەنەر', style: TextStyle(fontWeight: FontWeight.w800))),
                    Text(
                      widget.order.items.first.product.formatAmount(_payTotal),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text('دوای پارەدان، کۆدی $_code بدە بە گەیەنەر', style: const TextStyle(color: BoutiqueColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                Text(
                  _code,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 6, color: BoutiqueColors.goldDeep),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GoldButton(label: 'تەواو · پارەم دا', onPressed: _finish),
        ],
      ),
    );
  }
}

class _Seg extends StatelessWidget {
  const _Seg({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: on ? BoutiqueColors.white : BoutiqueColors.line,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(9),
          boxShadow: on ? [BoxShadow(color: Colors.black.withValues(alpha: .08), blurRadius: 3)] : null,
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: on ? BoutiqueColors.charcoal : BoutiqueColors.muted)),
      ),
    ),
  );
}
