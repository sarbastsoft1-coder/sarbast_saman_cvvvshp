import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../models/models.dart';
import 'glass_container.dart' show PillBadge;

class ProductCard extends StatefulWidget {
  final Product product;
  final bool isFavorite;
  final double terraRate;
  final VoidCallback onToggleFav;
  final VoidCallback onAddToCart;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.isFavorite,
    required this.terraRate,
    required this.onToggleFav,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with TickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final AnimationController _favCtrl;
  late final Animation<double> _lift;
  late final Animation<double> _favScale;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _lift = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _hoverCtrl, curve: EarthTheme.curveOut),
    );
    _favCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
      value: widget.isFavorite ? 1 : 0,
    );
    _favScale = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _favCtrl, curve: Curves.elasticOut),
    );
  }

  @override
  void didUpdateWidget(covariant ProductCard old) {
    super.didUpdateWidget(old);
    if (old.isFavorite != widget.isFavorite) {
      _favCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    _favCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_hoverCtrl, _favCtrl]),
      builder: (context, _) {
        final lift = _lift.value;
        return GestureDetector(
          onTap: widget.onTap,
          onTapDown: (_) => _hoverCtrl.forward(),
          onTapUp: (_) => _hoverCtrl.reverse(),
          onTapCancel: () => _hoverCtrl.reverse(),
          child: Transform.translate(
            offset: Offset(0, -lift * 6),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(EarthTheme.radiusMd),
                border: Border.all(
                  color: Color.lerp(
                    EarthTheme.borderLight,
                    EarthTheme.terracottaSoft,
                    lift,
                  )!,
                ),
                boxShadow: [
                  BoxShadow(
                    color: EarthTheme.forestGreen.withValues(
                      alpha: 0.05 + lift * 0.06,
                    ),
                    blurRadius: 14 + lift * 16,
                    offset: Offset(0, 6 + lift * 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image area
                  Expanded(
                    flex: 5,
                    child: Stack(
                      children: [
                        // Background gradient orb
                        Positioned(
                          left: -10,
                          bottom: -10,
                          child: Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  EarthTheme.categoryFg(widget.product.category)
                                      .withValues(alpha: 0.20),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  EarthTheme.goldenGlow
                                      .withValues(alpha: 0.25),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: EarthTheme.categoryBg(widget.product.category),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(EarthTheme.radiusMd),
                            ),
                          ),
                          child: Center(
                            child: Hero(
                              tag: 'product-emoji-${widget.product.id}',
                              child: Text(
                                widget.product.emoji,
                                style: const TextStyle(fontSize: 54),
                              ),
                            ),
                          ),
                        ),
                        // Favorite button with elastic scale
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: widget.onToggleFav,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(
                                      alpha: 0.08,
                                    ),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: AnimatedBuilder(
                                  animation: _favCtrl,
                                  builder: (context, _) {
                                    return Transform.scale(
                                      scale: 1.0 +
                                          (_favScale.value - 1.0) *
                                              (1 - _favCtrl.value),
                                      child: Icon(
                                        widget.isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        size: 16,
                                        color: widget.isFavorite
                                            ? EarthTheme.danger
                                            : EarthTheme.muted,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Eco chip
                        Positioned(
                          top: 8,
                          left: 8,
                          child: PillBadge(
                            label: 'ECO',
                            color: EarthTheme.sageGreen,
                            textColor: Colors.white,
                            icon: Icons.eco_rounded,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Info area
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.product.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: EarthTheme.charcoal,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Icon(
                                    Icons.storefront_rounded,
                                    size: 10,
                                    color: EarthTheme.mutedSoft,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      widget.product.seller,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: EarthTheme.muted,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '\$${widget.product.price.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: EarthTheme.forestGreen,
                                    ),
                                  ),
                                  Text(
                                    '🪙 ${widget.product.terraPrice(widget.terraRate).toStringAsFixed(1)}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: EarthTheme.clayOchre,
                                    ),
                                  ),
                                ],
                              ),
                              // Add to cart with bounce
                              GestureDetector(
                                onTap: widget.onAddToCart,
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        EarthTheme.terracotta,
                                        EarthTheme.clayOchre,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: EarthTheme.terracotta
                                            .withValues(alpha: 0.35),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
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
      },
    );
  }
}
