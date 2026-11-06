import 'package:flutter/material.dart';
import '../core/theme/boutique_colors.dart';
import '../models/product.dart';
import 'product_art.dart';
import 'roni_icons.dart';
import 'roni_motion.dart';

class ProductArtwork extends StatelessWidget {
  const ProductArtwork({super.key, required this.product});
  final BoutiqueProduct product;

  Widget _illustration(BoxConstraints constraints) {
    final side = (constraints.biggest.shortestSide * 0.72).clamp(56.0, 140.0);
    return Center(
      child: ProductArt(kind: ProductArt.fromKey(product.art), size: side),
    );
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: product.name,
    image: true,
    child: SizedBox.expand(
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (product.imageUrl?.isNotEmpty == true) {
            return Image.network(
              product.imageUrl!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, error, stack) => _illustration(constraints),
            );
          }
          return _illustration(constraints);
        },
      ),
    ),
  );
}

/// Product tile matching the ink & gold HTML `.card`: white card, art panel
/// with sale badge, heart and ink add button, then name, sale price, rating
/// and seller.
class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onToggleWishlist,
    required this.onAddToBag,
    required this.isWishlisted,
  });
  final BoutiqueProduct product;
  final VoidCallback onTap, onToggleWishlist, onAddToBag;
  final bool isWishlisted;
  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final hasRealPhoto = product.imageUrl?.isNotEmpty == true;
    return RoniHoverLift(
      child: RoniPressable(
        scale: .97,
        child: Material(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            onLongPress: onAddToBag,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
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
                        start: 8,
                        top: 8,
                        child: SaleBadge(percent: product.discountPercent),
                      ),
                    // HTML `.fav` / `.add` sit at physical left → end in RTL.
                    PositionedDirectional(
                      end: 6,
                      top: 6,
                      child: _RoundButton(
                        tooltip: isWishlisted
                            ? 'لابردن لە دڵخوازەکان'
                            : 'زیادکردن بۆ دڵخوازەکان',
                        onPressed: onToggleWishlist,
                        background: p.surface,
                        icon: RoniBump(
                          trigger: isWishlisted,
                          child: RoniIcon(
                            isWishlisted
                                ? RoniIconKind.heartFill
                                : RoniIconKind.heart,
                            size: 18,
                            color: isWishlisted ? p.sale : p.fg,
                          ),
                        ),
                      ),
                    ),
                    if (hasRealPhoto)
                      PositionedDirectional(
                        start: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: BoutiqueColors.ink.withValues(alpha: .62),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RoniIcon(
                                RoniIconKind.camera,
                                size: 11,
                                color: Colors.white,
                                strokeWidth: 1.6,
                              ),
                              SizedBox(width: 3),
                              Text(
                                'وێنەی ڕاستەقینە',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 10.5,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    PositionedDirectional(
                      end: 8,
                      bottom: 8,
                      child: _RoundButton(
                        tooltip: 'زیادکردن بۆ سەبەتە',
                        onPressed: onAddToBag,
                        background: BoutiqueColors.ink,
                        elevated: true,
                        icon: const RoniIcon(
                          RoniIconKind.plus,
                          size: 18,
                          color: BoutiqueColors.white,
                          strokeWidth: 2.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Builder(
                      builder: (context) {
                        final (title, latin) = product.nameParts;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 14,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                                color: p.fg,
                              ),
                            ),
                            if (latin != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                latin,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11.5,
                                  height: 1.35,
                                  fontWeight: FontWeight.w400,
                                  color: p.muted,
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 3),
                    Wrap(
                      spacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        Text(
                          product.formatAmount(product.price),
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: product.hasDiscount ? p.sale : p.fg,
                          ),
                        ),
                        if (product.hasDiscount)
                          Text(
                            product.formatAmount(product.oldPrice!),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11.5,
                              color: p.muted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    if (product.rating > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          RoniIcon(
                            RoniIconKind.star,
                            size: 14,
                            color: p.gold,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            product.rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12.5,
                              color: p.muted,
                            ),
                          ),
                          if (product.reviews > 0) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${product.reviews}+ هەڵسەنگاندن',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  color: p.muted,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (product.seller.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: p.brand2,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              product.seller,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 11.5,
                                color: p.muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.tooltip,
    required this.onPressed,
    required this.background,
    required this.icon,
    this.elevated = false,
  });
  final String tooltip;
  final VoidCallback onPressed;
  final Color background;
  final Widget icon;
  final bool elevated;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: elevated
          ? [
              BoxShadow(
                color: BoutiqueColors.ink.withValues(alpha: .25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    ),
    child: RoniPressable(
      scale: .88,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          constraints: const BoxConstraints.tightFor(width: 40, height: 40),
          padding: EdgeInsets.zero,
          icon: icon,
        ),
      ),
    ),
  );
}

class SaleBadge extends StatelessWidget {
  const SaleBadge({super.key, required this.percent});
  final int percent;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '$percent percent discount',
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: BoutiqueColors.rose,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '−$percent%',
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}
