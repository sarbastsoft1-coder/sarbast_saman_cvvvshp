import 'product_discounts_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_transitions.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  List<dynamic> _products = [];
  bool _loading = true;
  String _query = '';
  final _searchCtrl = TextEditingController();

  /// ID of the most recently created product – used to give it a
  /// pulse animation so the seller sees their new listing appear.
  dynamic _justAddedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetch();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _fetch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _animateInLatest() {
    if (_products.isEmpty) return;
    setState(() => _justAddedId = _products.first['id']);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _justAddedId = null);
    });
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await ApiService.get('/seller/products');
      if (res['status'] == 'success') {
        _products = res['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Products fetch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('نەتوانرا بەرهەمەکان بکرێنەوە: $e')),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  List<dynamic> get _filtered {
    if (_query.trim().isEmpty) return _products;
    final q = _query.toLowerCase();
    return _products
        .where((p) => (p['name']?.toString().toLowerCase() ?? '').contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('بەرهەمەکانم'),
        actions: [
          IconButton(
            tooltip: 'Product discounts',
            icon: const Icon(Icons.local_offer_outlined),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Discounts')),
                    body: const SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: ProductDiscountsScreen(),
                    ),
                  ),
                ),
              );
              _fetch();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetch,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<Map<String, dynamic>>(
            '/products/add',
          );
          if (!mounted || created == null) return;
          // Prepend the newly created product so it shows immediately.
          setState(() {
            _products.removeWhere((p) => p['id'] == created['id']);
            _products.insert(0, created);
          });
          _animateInLatest();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('بەرهەمی نوێ'),
        backgroundColor: AppColors.forest,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search your studio…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppColors.terracotta,
                ),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.terracotta,
                    ),
                  )
                : _filtered.isEmpty
                ? EmptyState(
                    icon: Icons.inventory_2_outlined,
                    title: _query.isEmpty
                        ? 'Your studio is empty'
                        : 'No matches',
                    subtitle: _query.isEmpty
                        ? 'Add your first artisan creation to start selling.'
                        : 'Try a different search term.',
                    action: _query.isEmpty
                        ? ElevatedButton.icon(
                            onPressed: () async {
                              final created = await context
                                  .push<Map<String, dynamic>>('/products/add');
                              if (!mounted || created == null) return;
                              setState(() {
                                _products.removeWhere(
                                  (p) => p['id'] == created['id'],
                                );
                                _products.insert(0, created);
                              });
                              _animateInLatest();
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Item'),
                          )
                        : null,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    itemCount: _filtered.length,
                    itemBuilder: (context, i) {
                      final p = _filtered[i] as Map<String, dynamic>;
                      final isJustAdded = p['id'] == _justAddedId;
                      return FadeSlideIn(
                        delay: Duration(milliseconds: 70 * i),
                        child: _ProductTile(
                          product: p,
                          highlight: isJustAdded,
                          onTap: () =>
                              context.push('/products/${p['id']}/edit'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({
    required this.product,
    required this.onTap,
    this.highlight = false,
  });

  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final name = product['name'] ?? 'Item';
    final price = (product['sale_price_fiat'] ?? product['price_fiat'])?.toString() ?? '0';
    final stock = product['stock'] ?? 0;
    final img = product['image'] as String?;
    final lowStock = stock is int && stock <= 5;

    final tile = InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: highlight ? AppColors.terracotta : AppColors.border,
            width: highlight ? 2 : 1,
          ),
          boxShadow: highlight
              ? [
                  BoxShadow(
                    color: AppColors.terracotta.withValues(alpha: 0.35),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(18),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    img == null || img.isEmpty
                        ? Container(
                            color: AppColors.sand,
                            child: const Icon(
                              Icons.image_outlined,
                              size: 32,
                              color: AppColors.terracotta,
                            ),
                          )
                        : Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: AppColors.sand,
                              child: const Icon(
                                Icons.image_outlined,
                                color: AppColors.terracotta,
                              ),
                            ),
                          ),
                    if (lowStock)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LOW STOCK',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                    if (highlight)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'NEW',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '\$$price${(product['discount_percent'] as num? ?? 0) > 0 ? ' · −${product['discount_percent']}%' : ''}',
                        style: const TextStyle(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.inventory_2_outlined,
                        size: 12,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$stock',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (!highlight) return tile;

    // Pulse + scale so the new listing pops visually.
    return TweenAnimationBuilder<double>(
      key: ValueKey('pulse-${product['id']}'),
      tween: Tween(begin: 0.94, end: 1.0),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: tile,
    );
  }
}
