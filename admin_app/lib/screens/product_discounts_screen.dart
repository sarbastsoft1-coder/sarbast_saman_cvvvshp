import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProductDiscountsScreen extends StatefulWidget {
  const ProductDiscountsScreen({super.key});
  @override
  State<ProductDiscountsScreen> createState() => _ProductDiscountsScreenState();
}

class _ProductDiscountsScreenState extends State<ProductDiscountsScreen> {
  List<dynamic> products = [];
  bool loading = true, saving = false;
  String? error;
  String query = '';
  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    if (mounted) {
      setState(() {
        loading = true;
        error = null;
      });
    }
    try {
      final res = await ApiService.get('/product-discounts');
      if (res['status'] != 'success') {
        throw Exception(res['message'] ?? 'Could not load products');
      }
      if (mounted) setState(() => products = res['data']);
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> edit(Map<String, dynamic> product) async {
    final controller = TextEditingController(
      text: '${product['discount_percent'] ?? 0}',
    );
    final key = GlobalKey<FormState>();
    final price = (product['price_fiat'] as num).toDouble();
    final percent = await showDialog<int>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, update) {
          final value = int.tryParse(controller.text) ?? 0;
          final valid = value >= 0 && value <= 99;
          return AlertDialog(
            title: const Text('Product discount'),
            content: SizedBox(
              width: 380,
              child: Form(
                key: key,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product['name'],
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Discount',
                        suffixText: '%',
                        helperText: 'Enter 0 to remove the discount',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => update(() {}),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        return n == null || n < 0 || n > 99
                            ? 'Enter a whole number from 0 to 99'
                            : null;
                      },
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CUSTOMER PRICE',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1.5,
                              color: Color(0xFF9F452C),
                            ),
                          ),
                          Text(
                            valid
                                ? '\$${(price * (100 - value) / 100).toStringAsFixed(2)}'
                                : '—',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF9F452C),
                            ),
                          ),
                          Text('Original: \$${price.toStringAsFixed(2)}'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (key.currentState!.validate()) {
                    Navigator.pop(context, value);
                  }
                },
                child: const Text('Save discount'),
              ),
            ],
          );
        },
      ),
    );
    if (percent != null && mounted) {
      setState(() => saving = true);
      try {
        final res = await ApiService.post(
          '/product-discounts/${product['id']}',
          {'discount_percent': percent},
        );
        if (res['status'] != 'success') {
          throw Exception(res['message'] ?? 'Could not save discount');
        }
        await load();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Discount saved')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        if (mounted) setState(() => saving = false);
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = products
        .where(
          (p) =>
              p['name'].toString().toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Product discounts',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: loading || saving ? null : load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const Text(
          'Set a percentage off the original price. Saving 0 removes a sale. Sellers manage their own products; admins manage all products.',
        ),
        const SizedBox(height: 20),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Find a product',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        if (loading || saving) const LinearProgressIndicator(),
        if (error != null)
          Text(error!, style: const TextStyle(color: Colors.red)),
        if (!loading && error == null && filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No matching products.'),
          ),
        for (final p in filtered)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0E9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.local_offer_outlined,
                      color: Color(0xFF9F452C),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['name'],
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(p['store']?['name'] ?? ''),
                        Wrap(
                          spacing: 8,
                          children: [
                            Text(
                              '\$${(p['sale_price_fiat'] as num).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF9F452C),
                              ),
                            ),
                            if ((p['discount_percent'] as num) > 0) ...[
                              Text(
                                '\$${(p['price_fiat'] as num).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Text('−${p['discount_percent']}%'),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit discount',
                    onPressed: saving
                        ? null
                        : () => edit(Map<String, dynamic>.from(p)),
                    icon: const Icon(Icons.edit_outlined),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
