import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../core/constants/boutique_constants.dart';
import '../core/theme/boutique_colors.dart';
import '../core/theme/boutique_tokens.dart';
import '../models/product.dart';
import 'animated_add_button.dart';

/// Hero section used at the top of the Home screen.
///
/// Animates a 3D-feeling product placeholder (a rotating handbag silhouette)
/// and offers the "زیادی بکە بۆ جانتاکەم" call-to-action.
class HeroProduct extends StatefulWidget {
  final BoutiqueProduct product;
  final VoidCallback onAdd;
  final VoidCallback? onTap;

  const HeroProduct({
    super.key,
    required this.product,
    required this.onAdd,
    this.onTap,
  });

  @override
  State<HeroProduct> createState() => _HeroProductState();
}

class _HeroProductState extends State<HeroProduct>
    with TickerProviderStateMixin {
  late final AnimationController _rotateController;
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final palette = RoniPalette.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusXxl),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            palette.brand2.withValues(alpha: 0.18),
            palette.surfaceSunken.withValues(alpha: 0.65),
            palette.card,
          ],
        ),
        border: Border.all(color: palette.line),
        boxShadow: BoutiqueTokens.shadowCard(palette),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: palette.card,
                        borderRadius: BorderRadius.circular(
                          BoutiqueTokens.radiusPill,
                        ),
                        border: Border.all(color: palette.line),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('✨', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'تایبەت بۆ تۆ',
                            style: TextStyle(
                              fontFamily: BoutiqueTokens.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: palette.fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (p.hasDiscount)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: palette.sale,
                          borderRadius: BorderRadius.circular(
                            BoutiqueTokens.radiusPill,
                          ),
                        ),
                        child: Text(
                          '${p.discountPercent}%-',
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 200,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _BackgroundGlow(color: p.accent),
                      AnimatedBuilder(
                        animation: Listenable.merge([
                          _rotateController,
                          _floatController,
                        ]),
                        builder: (context, _) {
                          final rot = _rotateController.value * 2 * math.pi;
                          final dy =
                              math.sin(_floatController.value * math.pi) * 8;
                          return Transform.translate(
                            offset: Offset(0, -dy),
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0015)
                                ..rotateY(rot)
                                ..rotateZ(math.sin(rot) * 0.06),
                              child: _HeroBagModel(
                                emoji: p.emoji,
                                color: p.accent,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Builder(
                  builder: (context) {
                    final (title, latin) = p.nameParts;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: BoutiqueTokens.fontFamily,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: palette.fg,
                          ),
                        ),
                        if (latin != null)
                          Text(
                            latin,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: BoutiqueTokens.fontFamily,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: palette.muted,
                            ),
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  p.shortDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontSize: 13,
                    color: palette.muted,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.formatAmount(p.price),
                      style: TextStyle(
                        fontFamily: BoutiqueTokens.fontFamily,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: palette.fg,
                      ),
                    ),
                    if (p.hasDiscount)
                      Text(
                        p.formatAmount(p.oldPrice!),
                        style: TextStyle(
                          fontFamily: BoutiqueTokens.fontFamily,
                          fontSize: 13,
                          color: palette.muted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 170,
                child: AnimatedAddButton(
                  onPressed: widget.onAdd,
                  label: 'زیادکردن',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  final Color color;
  const _BackgroundGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _HeroBagModel extends StatelessWidget {
  final String emoji;
  final Color color;
  const _HeroBagModel({required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    // Placeholder 3D-feeling "bag" model built from gradients + emoji.
    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(36),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.55),
            color.withValues(alpha: 0.25),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle highlight ring to enhance the 3D illusion.
          Positioned(
            top: 14,
            left: 14,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.20),
              ),
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 86)),
        ],
      ),
    );
  }
}
