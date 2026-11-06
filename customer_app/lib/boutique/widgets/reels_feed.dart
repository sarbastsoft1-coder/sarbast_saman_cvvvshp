import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/product_share.dart';

import '../core/theme/boutique_colors.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../providers/wishlist_provider.dart';
import 'animated_add_button.dart';
import 'glass_container.dart';
import 'product_art.dart';

/// Vertical full-screen reels-style product feed.
/// Each page occupies the viewport, with snapping enabled.
class ReelsFeed extends StatefulWidget {
  final List<BoutiqueProduct> products;
  final ValueChanged<BoutiqueProduct> onOpenDetails;
  const ReelsFeed({
    super.key,
    required this.products,
    required this.onOpenDetails,
  });

  @override
  State<ReelsFeed> createState() => _ReelsFeedState();
}

class _ReelsFeedState extends State<ReelsFeed> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'هیچ بەرهەمێک نەدۆزرایەوە',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              color: BoutiqueColors.muted,
            ),
          ),
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            scrollDirection: Axis.vertical,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.products.length,
            itemBuilder: (context, i) {
              final product = widget.products[i];
              return _ReelPage(
                product: product,
                onOpenDetails: () => widget.onOpenDetails(product),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.products.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              width: active ? 22 : 8,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active
                    ? BoutiqueColors.dustyPink
                    : BoutiqueColors.dustyPink.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ReelPage extends StatefulWidget {
  final BoutiqueProduct product;
  final VoidCallback onOpenDetails;
  const _ReelPage({required this.product, required this.onOpenDetails});

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heartCtrl;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final wishlist = context.read<WishlistProvider>();
    wishlist.toggle(widget.product);
    if (wishlist.contains(widget.product.id)) {
      _heartCtrl.forward(from: 0);
    }
  }

  Future<void> _share() => shareProduct(context, widget.product);

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wishlisted = context.watch<WishlistProvider>().contains(product.id);

    return GestureDetector(
      onTap: widget.onOpenDetails,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Immersive background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        product.accent.withValues(alpha: 0.85),
                        product.accent.withValues(alpha: 0.55),
                        BoutiqueColors.beige.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: Center(
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 400),
                      scale: 1,
                      child: ProductArt(
                        kind: ProductArt.fromKey(product.art),
                        size: 180,
                      ),
                    ),
                  ),
                ),
              ),
              // Bottom gradient for text contrast
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
              // Top badge
              Positioned(
                top: 18,
                right: 18,
                child: GlassContainer(
                  borderRadius: 999,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  color: Colors.white.withValues(alpha: 0.28),
                  borderColor: Colors.white.withValues(alpha: 0.45),
                  child: Text(
                    product.category,
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              // Floating interaction buttons
              Positioned(
                right: 14,
                bottom: 28,
                child: _SideActions(
                  product: product,
                  wishlisted: wishlisted,
                  onLike: _toggleLike,
                  onShare: _share,
                ),
              ),
              // Bottom product info & CTA
              Positioned(
                left: 18,
                right: 90,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.92),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                          child: const Center(
                            child: Text('🌸', style: TextStyle(fontSize: 18)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.seller,
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'بۆتیکی ئێمە',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.shortDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.formatAmount(product.price),
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (product.hasDiscount)
                              Text(
                                product.formatAmount(product.oldPrice!),
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 125,
                          child: AnimatedAddButton(
                            label: 'زیادکردن',
                            height: 48,
                            radius: 24,
                            onPressed: () =>
                                context.read<CartProvider>().add(product),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Heart pulse animation overlay
              IgnorePointer(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _heartCtrl,
                    builder: (context, _) {
                      if (_heartCtrl.value == 0) return const SizedBox();
                      return Transform.scale(
                        scale: 1 + _heartCtrl.value * 1.6,
                        child: Opacity(
                          opacity: 1 - _heartCtrl.value,
                          child: const Icon(
                            Icons.favorite_rounded,
                            color: Colors.white,
                            size: 110,
                          ),
                        ),
                      );
                    },
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

class _SideActions extends StatelessWidget {
  final BoutiqueProduct product;
  final bool wishlisted;
  final VoidCallback onLike;
  final VoidCallback onShare;
  const _SideActions({
    required this.product,
    required this.wishlisted,
    required this.onLike,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SideIconButton(
          icon: wishlisted
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          label: wishlisted ? 'دڵخوازە' : 'دڵخواز',
          color: wishlisted ? BoutiqueColors.rose : Colors.white,
          onTap: onLike,
        ),
        const SizedBox(height: 14),
        _SideIconButton(
          icon: Icons.shopping_bag_rounded,
          label: 'زیادکردن',
          color: Colors.white,
          onTap: () {
            context.read<CartProvider>().add(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: BoutiqueColors.charcoal,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                content: const Text(
                  'داواکارییەکەت زیاد کرا ✓',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: Colors.white,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        _SideIconButton(
          icon: Icons.ios_share_rounded,
          label: 'هاوبەشکردن',
          color: Colors.white,
          onTap: onShare,
        ),
      ],
    );
  }
}

class _SideIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SideIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          GlassContainer(
            borderRadius: 999,
            width: 52,
            height: 52,
            color: Colors.white.withValues(alpha: 0.18),
            borderColor: Colors.white.withValues(alpha: 0.32),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
