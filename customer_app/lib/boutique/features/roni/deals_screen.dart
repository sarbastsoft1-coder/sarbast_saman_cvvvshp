import '../../widgets/responsive_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_components.dart';

/// Deals page (pushed from home) — discounted products, biggest saving first.
class DealsScreen extends StatefulWidget {
  const DealsScreen({super.key});

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  /// Rolling countdown used by the flash-deal banner.
  late DateTime _endsAt;
  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endsAt = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  Duration get _remaining {
    final left = _endsAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  String get _countdownLabel {
    final d = _remaining;
    return '${d.inHours % 24}h ${d.inMinutes % 60}m ${d.inSeconds % 60}s';
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final deals = catalog.products.where((p) => p.hasDiscount).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<CatalogProvider>().load();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ئۆفەرەکان',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              deals.isEmpty
                                  ? 'هێشتا ئۆفەرێک نییە'
                                  : '${deals.length} بەرهەم بە داشکاندن',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      RoniIconButton(
                        icon: Icons.search_rounded,
                        tooltip: 'گەڕان',
                        onPressed: () =>
                            Navigator.pushNamed(context, BoutiqueRoutes.search),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _FlashBanner(label: _countdownLabel)),
              if (deals.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: StoreEmpty(
                    title: 'هێشتا ئۆفەرێک نییە',
                    message: 'کاتێک داشکاندنی نوێ دەست پێکرد، لێرە دەردەکەوێت.',
                    icon: Icons.local_offer_outlined,
                  ),
                )
              else ...[
                const SliverToBoxAdapter(
                  child: RoniSectionHeader(
                    title: 'زۆرترین داشکاندن',
                    padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) => SliverGrid(
                      gridDelegate: ResponsiveProductGrid(
                        textScale: MediaQuery.textScalerOf(context).scale(1),
                      ),
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final product = deals[i];
                        final wishlist = context.watch<WishlistProvider>();
                        return ProductCard(
                          product: product,
                          isWishlisted: wishlist.contains(product.id),
                          onTap: () => Navigator.pushNamed(
                            context,
                            BoutiqueRoutes.productDetails,
                            arguments: product,
                          ),
                          onToggleWishlist: () => wishlist.toggle(product),
                          onAddToBag: () =>
                              context.read<CartProvider>().add(product),
                        );
                      }, childCount: deals.length),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 28)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Gold flash-sale banner with a live countdown.
class _FlashBanner extends StatelessWidget {
  const _FlashBanner({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: BoutiqueColors.goldGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: BoutiqueColors.floatingShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.bolt_rounded,
                color: BoutiqueColors.white,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'فرۆشتنی خێرای ئەمڕۆ',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: BoutiqueColors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'کاتی بەسەردەچوون: $label',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: BoutiqueColors.white.withValues(alpha: .92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
