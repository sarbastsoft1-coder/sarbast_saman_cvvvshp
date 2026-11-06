import 'package:flutter/material.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/store_components.dart';

class RateOrderScreen extends StatefulWidget {
  const RateOrderScreen({super.key, required this.order});
  final BoutiqueOrder order;
  @override
  State<RateOrderScreen> createState() => _RateOrderScreenState();
}

class _RateOrderScreenState extends State<RateOrderScreen> {
  late final Map<int, int> _stars;
  int _delivery = 5;
  final _note = TextEditingController(text: 'زۆر باش بوو.');

  @override
  void initState() {
    super.initState();
    _stars = {for (var i = 0; i < widget.order.items.length; i++) i: 5};
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: const Text('هەڵسەنگاندن')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Center(
            child: Column(
              children: [
                const Text(
                  'چۆن بوو؟',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'هەڵسەنگاندنەکەت یارمەتی کڕیارانی تر دەدات',
                  style: TextStyle(color: p.muted, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          for (var i = 0; i < widget.order.items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: RoniCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.items[i].product.name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _Stars(
                      value: _stars[i] ?? 5,
                      onChanged: (v) => setState(() => _stars[i] = v),
                    ),
                    if (i == 0) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _note,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'تێبینی…',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '+٢٠ ڕۆنیکس بۆ هەڵسەنگاندن بە وێنە',
                        style: TextStyle(
                          color: p.brand2,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          RoniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('گەیاندن', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                _Stars(value: _delivery, onChanged: (v) => setState(() => _delivery = v)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GoldButton(
            label: 'ناردن',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سوپاس بۆ هەڵسەنگاندنەکەت ✓')),
              );
              Navigator.of(context).pushNamedAndRemoveUntil(BoutiqueRoutes.orders, (r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Row(
      children: [
        for (var i = 1; i <= 5; i++)
          Expanded(
            child: IconButton(
              tooltip: 'هەڵسەنگاندن $i',
              onPressed: () => onChanged(i),
              constraints: const BoxConstraints(
                minWidth: BoutiqueTokens.tapTarget,
                minHeight: BoutiqueTokens.tapTarget,
              ),
              icon: Icon(
                i <= value ? Icons.star_rounded : Icons.star_border_rounded,
                color: p.gold,
                size: 30,
              ),
            ),
          ),
      ],
    );
  }
}
