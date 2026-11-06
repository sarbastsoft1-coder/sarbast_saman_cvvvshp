import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme/boutique_colors.dart';
import '../providers/cart_provider.dart';
import 'roni_icons.dart';
import 'roni_motion.dart';

/// Floating pill bar — Home · Categories · Ronix · Cart · Me.
/// Modern motion: sliding gold blob, spring icon pop, floating Ronix coin.
class BoutiqueBottomNavigation extends StatelessWidget {
  const BoutiqueBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });
  final int currentIndex;
  final ValueChanged<int> onTap;

  static const cartIndex = 3;
  static const ronixIndex = 2;
  static const _count = 5;

  static const _items = <({RoniIconKind? icon, String label})>[
    (icon: RoniIconKind.home, label: 'سەرەکی'),
    (icon: RoniIconKind.grid, label: 'بەشەکان'),
    (icon: null, label: 'Ronix'),
    (icon: RoniIconKind.cart, label: 'سەبەتە'),
    (icon: RoniIconKind.person, label: 'من'),
  ];

  void _tap(int i) {
    HapticFeedback.selectionClick();
    onTap(i);
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartProvider>().itemCount;
    final p = RoniPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Color.lerp(p.surface, p.chev, 0.07)!,
                          p.surface.withValues(alpha: .97),
                        ]
                      : [p.surface, Color.lerp(p.surface, p.soft, 0.6)!],
                ),
                border: Border.all(
                  color: isDark
                      ? Color.lerp(p.line, p.chev, 0.4)!.withValues(alpha: .9)
                      : p.line,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? .55 : .14),
                    blurRadius: isDark ? 34 : 24,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: p.chev.withValues(alpha: isDark ? .14 : .08),
                    blurRadius: 20,
                    spreadRadius: -4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(5, 5, 5, 6),
                child: SizedBox(
                  height: 62,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final slot = constraints.maxWidth / _count;
                      final showBlob = currentIndex != ronixIndex;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Sliding gold selection blob (skips Ronix — coin is the hero).
                          AnimatedPositionedDirectional(
                            duration: reduce
                                ? Duration.zero
                                : const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                            start: currentIndex * slot + 3,
                            top: 2,
                            bottom: 2,
                            width: slot - 6,
                            child: IgnorePointer(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 220),
                                opacity: showBlob ? 1 : 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    gradient: LinearGradient(
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                      colors: isDark
                                          ? [
                                              p.brand2.withValues(alpha: .22),
                                              p.chev.withValues(alpha: .10),
                                            ]
                                          : [
                                              p.soft,
                                              p.chev.withValues(alpha: .22),
                                            ],
                                    ),
                                    border: Border.all(
                                      color: p.chev.withValues(
                                        alpha: isDark ? .4 : .55,
                                      ),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: p.chev.withValues(alpha: .18),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              for (var i = 0; i < _items.length; i++)
                                Expanded(
                                  child: _NavItem(
                                    key: ValueKey('nav-$i'),
                                    icon: _items[i].icon,
                                    label: _items[i].label,
                                    selected: currentIndex == i,
                                    isRonix: i == ronixIndex,
                                    badge: i == cartIndex && cartCount > 0
                                        ? cartCount
                                        : null,
                                    onTap: () => _tap(i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isRonix,
    this.badge,
  });

  final RoniIconKind? icon;
  final String label;
  final bool selected;
  final bool isRonix;
  final VoidCallback onTap;
  final int? badge;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> with TickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final Animation<double> _popScale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.22,
      ).chain(CurveTween(curve: Curves.easeOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.22,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 65,
    ),
  ]).animate(_pop);

  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.isRonix) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
        if (!reduce) _float.repeat(reverse: true);
      });
    }
  }

  @override
  void didUpdateWidget(covariant _NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.selected && widget.selected) {
      final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (!reduce) {
        _pop.forward(from: 0);
        if (widget.isRonix) _spin.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    _float.dispose();
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final color = widget.selected ? p.brand2 : p.muted;

    if (widget.isRonix) {
      return Semantics(
        selected: widget.selected,
        button: true,
        label: widget.label,
        child: RoniPressable(
          scale: .92,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: Stack(
              // The coin is a raised centre action: it is positioned out of
              // flow so it can float above the bar without pushing the label
              // out of it. Laying the coin out in the same column as the
              // label overflowed the bar by 8px at 1.2x text scale.
              clipBehavior: Clip.none,
              alignment: Alignment.bottomCenter,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 220),
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        height: 1.05,
                        fontWeight:
                            widget.selected ? FontWeight.w800 : FontWeight.w700,
                        color: color,
                      ),
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 3),
                    _GoldDot(active: widget.selected, color: p.chev),
                  ],
                ),
                Positioned(
                  bottom: 24,
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_float, _spin, _popScale]),
                    builder: (context, child) {
                      final bob = (_float.value - 0.5) * 5;
                      final lift = widget.selected ? -4.0 : 0.0;
                      final turn = Curves.easeOutCubic.transform(_spin.value);
                      // Gentle half-turn shimmer on select.
                      final angle = turn * math.pi * 2 * 0.08;
                      return Transform.translate(
                        offset: Offset(0, lift + bob),
                        child: Transform.scale(
                          scale: _popScale.value *
                              (widget.selected ? 1.06 : 1.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.002)
                              ..rotateY(angle),
                            child: child,
                          ),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: p.surface,
                            blurRadius: 0,
                            spreadRadius: 3.5,
                          ),
                          if (widget.selected)
                            BoxShadow(
                              color: p.chev,
                              blurRadius: 0,
                              spreadRadius: 6,
                            ),
                          BoxShadow(
                            color: p.chev.withValues(
                              alpha: widget.selected ? .55 : .28,
                            ),
                            blurRadius: widget.selected ? 20 : 12,
                            spreadRadius: widget.selected ? 2 : 0,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: widget.selected ? .38 : .22,
                            ),
                            blurRadius: widget.selected ? 16 : 9,
                            offset: Offset(0, widget.selected ? 8 : 4),
                          ),
                        ],
                      ),
                      child: const RoniGlow(
                        child: _CoinShimmer(child: RonixCoin(size: 50)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Semantics(
      selected: widget.selected,
      button: true,
      child: RoniPressable(
        scale: .92,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: _popScale,
                      child: AnimatedScale(
                        scale: widget.selected ? 1.08 : 1,
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutBack,
                        child: AnimatedSlide(
                          offset: widget.selected
                              ? Offset.zero
                              : const Offset(0, 0.06),
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOutCubic,
                          child: RoniIcon(
                            widget.icon!,
                            size: 22,
                            color: color,
                            strokeWidth: widget.selected ? 2.2 : 1.85,
                          ),
                        ),
                      ),
                    ),
                    if (widget.badge != null)
                      PositionedDirectional(
                        start: 10,
                        top: -8,
                        child: RoniBump(
                          trigger: widget.badge,
                          peak: 1.5,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 18),
                            height: 18,
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: p.sale,
                              borderRadius: BorderRadius.circular(9),
                              boxShadow: [
                                BoxShadow(
                                  color: p.sale.withValues(alpha: .4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: Border.all(color: p.surface, width: 1.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              widget.badge! > 99 ? '99+' : '${widget.badge}',
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 220),
                  opacity: widget.selected ? 1 : 0.72,
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11,
                      height: 1.1,
                      fontWeight:
                          widget.selected ? FontWeight.w700 : FontWeight.w600,
                      color: color,
                    ),
                    child: Text(
                      widget.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                _GoldDot(active: widget.selected, color: p.chev),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoldDot extends StatelessWidget {
  const _GoldDot({required this.active, required this.color});
  final bool active;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      height: 3,
      width: active ? 16 : 0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: .55)],
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: color.withValues(alpha: .55),
                  blurRadius: 6,
                ),
              ]
            : null,
      ),
    );
  }
}

/// Soft light sweep across the Ronix coin (modern metal feel).
class _CoinShimmer extends StatefulWidget {
  const _CoinShimmer({required this.child});
  final Widget child;

  @override
  State<_CoinShimmer> createState() => _CoinShimmerState();
}

class _CoinShimmerState extends State<_CoinShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2800),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final t = _c.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.2 + t * 2.4, -0.4),
              end: Alignment(-0.4 + t * 2.4, 0.4),
              colors: const [
                Color(0x00FFFFFF),
                Color(0x66FFF3C4),
                Color(0x00FFFFFF),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
