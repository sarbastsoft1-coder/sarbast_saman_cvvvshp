import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/challenges_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/responsive_grid.dart';
import '../../widgets/store_components.dart';

class SellerStoreScreen extends StatelessWidget {
  const SellerStoreScreen({super.key, required this.seller});
  final String seller;

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final products = catalog.products.where((p) => p.seller == seller || (seller.isNotEmpty && p.seller.contains(seller))).toList();
    final list = products.isEmpty ? catalog.products.take(6).toList() : products;
    final name = seller.isEmpty ? 'دووکانی فرۆشیار' : seller;
    final initial = name.characters.first;

    return Scaffold(
      backgroundColor: BoutiqueColors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              height: 120,
              color: BoutiqueColors.softPink,
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_forward_rounded),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -34),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: BoutiqueColors.gold,
                            shape: BoxShape.circle,
                            border: Border.all(color: BoutiqueColors.cream, width: 4),
                          ),
                          alignment: Alignment.center,
                          child: Text(initial, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF3D2700))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                              const Text('لە Roni · فرۆشیاری پشکنراو', style: TextStyle(fontSize: 12, color: BoutiqueColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      children: const [
                        _Pill(ok: true, label: 'فرۆشیاری پشکنراو'),
                        _Pill(ok: false, label: 'دروستکراوی کوردستان'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: GoldButton(label: 'فۆڵۆ بکە', height: 44, icon: Icons.add, onPressed: () {
                          context.read<ChallengesProvider>().markProgress('follow');
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فۆڵۆ کرا ✓')));
                        })),
                        const SizedBox(width: 8),
                        Expanded(child: GhostButton(label: 'نامە بنێرە', height: 44, icon: Icons.chat_bubble_outline, onPressed: () {
                          Navigator.pushNamed(context, BoutiqueRoutes.chats);
                        })),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text('بەرهەم (${list.length})', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
            sliver: SliverGrid(
              gridDelegate: ResponsiveProductGrid(textScale: MediaQuery.textScalerOf(context).scale(1)),
              delegate: SliverChildBuilderDelegate((context, i) {
                final product = list[i];
                final wishlist = context.watch<WishlistProvider>();
                return ProductCard(
                  product: product,
                  isWishlisted: wishlist.contains(product.id),
                  onTap: () => Navigator.pushNamed(context, BoutiqueRoutes.productDetails, arguments: product),
                  onToggleWishlist: () => wishlist.toggle(product),
                  onAddToBag: () => context.read<CartProvider>().add(product),
                );
              }, childCount: list.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.ok, required this.label});
  final bool ok;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: ok ? BoutiqueColors.statusDeliveredWash : BoutiqueColors.dustyPink,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ok ? BoutiqueColors.successGreen : Colors.white)),
  );
}

/// Opens seller store from a product argument or seller name string.
BoutiqueProduct? productArg(Object? args) => args is BoutiqueProduct ? args : null;
