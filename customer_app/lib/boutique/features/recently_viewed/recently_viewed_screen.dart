import '../../widgets/responsive_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/recently_viewed_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/store_components.dart';

/// Browsing history. Pops the most recently viewed item to the top of the
/// grid; supports add-to-cart, wishlist toggle, and clear-all.
class RecentlyViewedScreen extends StatelessWidget {
  const RecentlyViewedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recent = context.watch<RecentlyViewedProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final items = recent.items;

    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(title: const Text('بینیوەی دوایی')),
      body: items.isEmpty
          ? const StoreEmpty(
              title: 'هیچ مێژوویەک نییە',
              message:
                  'بەرهەمەکانی کە دەیانبینیت لێرە دەردەکەون. سەیری بەرهەمەکانمان بکە!',
              icon: Icons.history_rounded,
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: RoniSectionHeader(
                    title: '${items.length} بەرهەم',
                    actionLabel: 'پاککردنەوەی مێژوو',
                    onAction: () => _confirmClear(context),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  sliver: SliverGrid(
                    gridDelegate: ResponsiveProductGrid(
                      textScale: MediaQuery.textScalerOf(context).scale(1),
                    ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final product = items[i];
                      return ProductCard(
                        product: product,
                        isWishlisted: wishlist.contains(product.id),
                        onTap: () => Navigator.of(context).pushNamed(
                          BoutiqueRoutes.productDetails,
                          arguments: product,
                        ),
                        onToggleWishlist: () => wishlist.toggle(product),
                        onAddToBag: () =>
                            context.read<CartProvider>().add(product),
                      );
                    }, childCount: items.length),
                  ),
                ),
              ],
            ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: BoutiqueColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('پاککردنەوەی مێژووەکە؟'),
        content: const Text(
          'دڵنیایت دەتەوێت هەموو بینیوەی دواییەکانت بسڕیتەوە؟',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            color: BoutiqueColors.softCharcoal,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('هەڵوەشاندنەوە'),
          ),
          GoldButton(
            label: 'بەڵێ، بسڕەوە',
            expand: false,
            height: 46,
            onPressed: () {
              context.read<RecentlyViewedProvider>().clear();
              Navigator.of(dialogContext).pop();
            },
          ),
        ],
      ),
    );
  }
}
