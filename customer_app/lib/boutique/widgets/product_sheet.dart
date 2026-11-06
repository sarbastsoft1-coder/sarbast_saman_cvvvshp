import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/routes/boutique_routes.dart';
import '../core/theme/boutique_colors.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/recently_viewed_provider.dart';
import '../providers/wishlist_provider.dart';
import 'product_card.dart';
import 'roni_motion.dart';

/// Opens product detail as a bottom sheet on phone widths (HTML `#sheet`),
/// or as a full route on wider layouts.
Future<void> openProductDetail(
  BuildContext context,
  BoutiqueProduct product,
) async {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  if (wide) {
    await Navigator.of(
      context,
    ).pushNamed(BoutiqueRoutes.productDetails, arguments: product);
    return;
  }
  // HTML `@keyframes up` + scrim `fade`.
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'داخستن',
    barrierColor: Colors.black.withValues(alpha: .5),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, a1, a2) => SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ProductBottomSheet(product: product),
      ),
    ),
    transitionBuilder: (ctx, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .12),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class ProductBottomSheet extends StatefulWidget {
  const ProductBottomSheet({super.key, required this.product});
  final BoutiqueProduct product;

  @override
  State<ProductBottomSheet> createState() => _ProductBottomSheetState();
}

class _ProductBottomSheetState extends State<ProductBottomSheet> {
  String? _size;
  Color? _color;

  @override
  void initState() {
    super.initState();
    _size = widget.product.availableSizes.firstOrNull;
    _color = widget.product.availableColors.firstOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<RecentlyViewedProvider>().track(widget.product);
      }
    });
  }

  void _add({required bool checkout}) {
    context.read<CartProvider>().add(
      widget.product,
      size: _size,
      color: _color,
    );
    Navigator.pop(context);
    if (checkout) {
      Navigator.of(context).pushNamed(BoutiqueRoutes.checkout);
      return;
    }
    showRoniToast(
      context,
      'خرایە ناو سەبەتە',
      actionLabel: 'سەبەتە',
      onAction: () => BoutiqueRoutes.openCart(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final p = RoniPalette.of(context);
    final wishlist = context.watch<WishlistProvider>();
    final saved = wishlist.contains(product.id);
    final maxH = MediaQuery.sizeOf(context).height * 0.88;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 480, maxHeight: maxH),
        child: Material(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: Color.alphaBlend(
                              product.accent.withValues(alpha: .14),
                              p.soft,
                            ),
                            child: ProductArtwork(product: product),
                          ),
                          if (product.hasDiscount)
                            PositionedDirectional(
                              start: 12,
                              top: 12,
                              child: SaleBadge(
                                percent: product.discountPercent,
                              ),
                            ),
                          PositionedDirectional(
                            end: 12,
                            top: 12,
                            child: Material(
                              color: p.surface,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: 'داخستن',
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(Icons.close_rounded, color: p.fg),
                              ),
                            ),
                          ),
                          PositionedDirectional(
                            start: 12,
                            bottom: 12,
                            child: Material(
                              color: p.surface,
                              shape: const CircleBorder(),
                              child: IconButton(
                                tooltip: saved
                                    ? 'لابردن لە دڵخواز'
                                    : 'دڵخواز',
                                onPressed: () => wishlist.toggle(product),
                                icon: Icon(
                                  saved
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: saved ? p.sale : p.fg,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            product.name,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 18,
                              height: 1.4,
                              fontWeight: FontWeight.w800,
                              color: p.fg,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.end,
                            children: [
                              Text(
                                product.formatAmount(product.price),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: product.hasDiscount ? p.sale : p.fg,
                                ),
                              ),
                              if (product.hasDiscount)
                                Text(
                                  product.formatAmount(product.oldPrice!),
                                  style: TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 13,
                                    color: p.muted,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                            ],
                          ),
                          if (product.seller.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Material(
                              color: p.soft,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () {
                                  Navigator.pop(context);
                                  Navigator.pushNamed(
                                    context,
                                    BoutiqueRoutes.store,
                                    arguments: product.seller,
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: p.brand2,
                                        child: Text(
                                          product.seller.isNotEmpty
                                              ? product.seller[0]
                                              : 'R',
                                          style: TextStyle(
                                            color: p.onGold,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              product.seller,
                                              style: TextStyle(
                                                fontFamily: 'Vazirmatn',
                                                fontWeight: FontWeight.w700,
                                                color: p.fg,
                                              ),
                                            ),
                                            Text(
                                              'فرۆشیاری پشتڕاستکراو',
                                              style: TextStyle(
                                                fontFamily: 'Vazirmatn',
                                                fontSize: 12,
                                                color: p.muted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.chevron_left_rounded,
                                        color: p.muted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (product.availableSizes.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'قەبارە',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w700,
                                color: p.fg,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final s in product.availableSizes)
                                  ChoiceChip(
                                    label: Text(s),
                                    selected: _size == s,
                                    onSelected: (_) =>
                                        setState(() => _size = s),
                                  ),
                              ],
                            ),
                          ],
                          if (product.availableColors.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            Text(
                              'ڕەنگ',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontWeight: FontWeight.w700,
                                color: p.fg,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              children: [
                                for (final c in product.availableColors)
                                  GestureDetector(
                                    onTap: () => setState(() => _color = c),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: c,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: _color == c
                                              ? p.brand2
                                              : p.line,
                                          width: _color == c ? 2.5 : 1,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pushNamed(
                                context,
                                BoutiqueRoutes.productDetails,
                                arguments: product,
                              );
                            },
                            child: Text(
                              'وردەکاری زیاتر',
                              style: TextStyle(color: p.brand2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _add(checkout: false),
                          child: const Text('سەبەتە'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: RoniPressable(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: BoutiqueColors.goldGradient,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () => _add(checkout: true),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Center(
                                    child: Text(
                                      'کڕین',
                                      style: TextStyle(
                                        fontFamily: 'Vazirmatn',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: BoutiqueColors.onGold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
