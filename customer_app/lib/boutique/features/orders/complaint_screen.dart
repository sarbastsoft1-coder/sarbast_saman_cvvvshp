import 'package:flutter/material.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/orders_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_components.dart';

class ComplaintScreen extends StatefulWidget {
  const ComplaintScreen({super.key, this.order});
  final BoutiqueOrder? order;
  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  String _type = 'product';
  String _want = 'refund';
  final _note = TextEditingController(
    text: 'دوای دوو ڕۆژ کێشەیەکم بینی.',
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(title: const Text('کێشەیەکم هەیە')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const StoreNotice(
            'بەرهەمی شکاو یان جیاواز لە وەسف لە ماوەی ٣ ڕۆژ دوای وەرگرتن دەگەڕێتەوە. وەڵام لە ماوەی ٢ کاتژمێردا.',
          ),
          const SizedBox(height: 12),
          if (order != null)
            RoniCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: order.items.isNotEmpty
                        ? ProductArtwork(product: order.items.first.product)
                        : const Icon(Icons.inventory_2_outlined),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.id, textDirection: TextDirection.ltr, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          order.items.isNotEmpty ? order.items.first.product.name : 'داواکاری',
                          style: const TextStyle(color: BoutiqueColors.muted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          const Text('جۆری کێشە', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _radio('product', 'بەرهەم کێشەی هەیە'),
          _radio('delivery', 'گەیاندن دواکەوت'),
          _radio('pay', 'پارە'),
          _radio('seller', 'فرۆشیار'),
          const SizedBox(height: 12),
          const Text('چی ڕوویدا؟', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          TextField(controller: _note, maxLines: 4, decoration: const InputDecoration()),
          const SizedBox(height: 12),
          const Text('چیت دەوێت؟', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _wantChip('refund', 'گەڕاندنەوەی پارە')),
              const SizedBox(width: 8),
              Expanded(child: _wantChip('exchange', 'گۆڕینەوە')),
            ],
          ),
          const SizedBox(height: 18),
          GoldButton(
            label: 'ناردن',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('سکاڵاکەت نێردرا · لە ماوەی ٢ کاتژمێردا وەڵام دەدەینەوە')),
              );
              Navigator.of(context).pushReplacementNamed(BoutiqueRoutes.help);
            },
          ),
        ],
      ),
    );
  }

  Widget _radio(String id, String label) => RadioListTile<String>(
    value: id,
    groupValue: _type,
    onChanged: (v) => setState(() => _type = v ?? id),
    title: Text(label, style: const TextStyle(fontSize: 14)),
    activeColor: BoutiqueColors.dustyPink,
    contentPadding: EdgeInsets.zero,
  );

  Widget _wantChip(String id, String label) {
    final on = _want == id;
    return Material(
      color: on ? BoutiqueColors.white : BoutiqueColors.line,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        onTap: () => setState(() => _want = id),
        borderRadius: BorderRadius.circular(9),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: on ? BoutiqueColors.charcoal : BoutiqueColors.muted)),
        ),
      ),
    );
  }
}
