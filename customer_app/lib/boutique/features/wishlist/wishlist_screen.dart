import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

/// Saved items, pushed on top of the shell (not a tab).
class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('دڵخوازەکانم'),
            Text(
              wishlist.isEmpty
                  ? 'هێشتا هیچ بەرهەمێکت نییە'
                  : '${wishlist.count} بەرهەم',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (!wishlist.isEmpty)
            TextButton(
              onPressed: wishlist.clear,
              child: const Text('پاککردنەوەی هەموو'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: wishlist.isEmpty
          ? StoreEmpty(
              title: 'هێشتا هیچ بەرهەمێکت لە دڵخوازەکان نییە',
              message:
                  'بەرهەمە دڵخوازەکانت لێرە دەردەکەون. کلیک لە ❤ بکە '
                  'لەسەر بەرهەمەکان.',
              icon: Icons.favorite_rounded,
              action: GoldButton(
                label: 'گەڕان لە نێو بەرهەمەکاندا',
                icon: Icons.grid_view_rounded,
                expand: false,
                onPressed: () => BoutiqueRoutes.openTab(context, 1),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
              itemCount: wishlist.items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) => RoniFadeSlide(
                delay: Duration(milliseconds: 40 * i),
                child: _WishlistCard(
                  product: wishlist.items[i],
                  onOpen: () => Navigator.of(context).pushNamed(
                    BoutiqueRoutes.productDetails,
                    arguments: wishlist.items[i],
                  ),
                  onToggle: () => wishlist.toggle(wishlist.items[i]),
                  onRemove: () => wishlist.remove(wishlist.items[i].id),
                  onAddToBag: () {
                    context.read<CartProvider>().add(wishlist.items[i]);
                    showRoniToast(context, 'خرایە ناو سەبەتە');
                  },
                ),
              ),
            ),
    );
  }
}

class _WishlistCard extends StatelessWidget {
  const _WishlistCard({
    required this.product,
    required this.onOpen,
    required this.onToggle,
    required this.onRemove,
    required this.onAddToBag,
  });

  final BoutiqueProduct product;
  final VoidCallback onOpen, onToggle, onRemove, onAddToBag;

  @override
  Widget build(BuildContext context) => RoniCard(
    padding: const EdgeInsets.all(12),
    onTap: onOpen,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 92,
                height: 112,
                child: ProductArtwork(product: product),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.category,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 10.5,
                      color: BoutiqueColors.muted,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      color: BoutiqueColors.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RatingRow(product: product),
                  const SizedBox(height: 8),
                  _PriceLine(product: product),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _TonalAction(
              tooltip: 'لابردن لە دڵخواز',
              icon: Icons.favorite_rounded,
              color: BoutiqueColors.rose,
              onPressed: onToggle,
            ),
            const SizedBox(width: 8),
            _TonalAction(
              tooltip: 'سڕینەوە لە دڵخوازەکان',
              icon: Icons.delete_outline_rounded,
              color: BoutiqueColors.softCharcoal,
              onPressed: onRemove,
            ),
            const Spacer(),
            GoldButton(
              label: 'زیادی بکە',
              icon: Icons.add_shopping_cart_rounded,
              expand: false,
              height: 42,
              radius: 14,
              onPressed: onAddToBag,
            ),
          ],
        ),
      ],
    ),
  );
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.product});
  final BoutiqueProduct product;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Icon(
        Icons.star_rounded,
        size: 15,
        color: BoutiqueColors.goldBright,
      ),
      const SizedBox(width: 4),
      Text(
        product.rating.toStringAsFixed(1),
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: BoutiqueColors.charcoal,
        ),
      ),
      const SizedBox(width: 6),
      Text(
        '(${product.reviews})',
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 11,
          color: BoutiqueColors.muted,
        ),
      ),
    ],
  );
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.product});
  final BoutiqueProduct product;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            product.formatAmount(product.price),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: BoutiqueColors.charcoal,
            ),
          ),
        ),
      ),
      if (product.hasDiscount) ...[
        const SizedBox(width: 8),
        Text(
          product.formatAmount(product.oldPrice!),
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            color: BoutiqueColors.muted,
            decoration: TextDecoration.lineThrough,
          ),
        ),
        const SizedBox(width: 8),
        SaleBadge(percent: product.discountPercent),
      ],
    ],
  );
}

class _TonalAction extends StatelessWidget {
  const _TonalAction({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton.filledTonal(
    tooltip: tooltip,
    onPressed: onPressed,
    iconSize: 18,
    style: IconButton.styleFrom(
      backgroundColor: BoutiqueColors.goldWash,
      foregroundColor: color,
    ),
    icon: Icon(icon),
  );
}
