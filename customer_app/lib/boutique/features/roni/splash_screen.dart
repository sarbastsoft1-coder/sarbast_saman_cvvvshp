import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../widgets/roni_icons.dart';
import '../../widgets/roni_motion.dart';

/// Interactive Roni splash — brand-first ink stage, parallax gold atmosphere,
/// tap-to-shine wordmark, swipe-up or CTA to continue. Never auto-advances.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, this.onGetStarted});

  final VoidCallback? onGetStarted;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ambient;
  late final AnimationController _enter;
  late final AnimationController _shine;
  Offset _parallax = Offset.zero;
  bool _pressedLogo = false;

  @override
  void initState() {
    super.initState();
    _ambient = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _enter = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted) _shine.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _ambient.dispose();
    _enter.dispose();
    _shine.dispose();
    super.dispose();
  }

  void _goStart() {
    HapticFeedback.lightImpact();
    (widget.onGetStarted ??
        () => Navigator.of(context).pushReplacementNamed(BoutiqueRoutes.lang))();
  }

  void _goLogin() {
    Navigator.of(context).pushReplacementNamed(BoutiqueRoutes.auth);
  }

  void _onPointer(Offset local, Size size) {
    final dx = ((local.dx / size.width) - 0.5) * 2;
    final dy = ((local.dy / size.height) - 0.5) * 2;
    setState(() => _parallax = Offset(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0)));
  }

  void _burstShine() {
    HapticFeedback.selectionClick();
    setState(() => _pressedLogo = true);
    _shine.forward(from: 0);
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _pressedLogo = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce && _ambient.isAnimating) _ambient.stop();

    return Scaffold(
      backgroundColor: BoutiqueColors.ink,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return Listener(
            onPointerMove: (e) => _onPointer(e.localPosition, size),
            onPointerHover: (e) => _onPointer(e.localPosition, size),
            child: GestureDetector(
              onVerticalDragEnd: (d) {
                if ((d.primaryVelocity ?? 0) < -420) _goStart();
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: BoutiqueColors.headerGradient,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _ambient,
                    builder: (context, _) => CustomPaint(
                      painter: _SplashAtmospherePainter(
                        t: reduce ? 0 : _ambient.value,
                        parallax: _parallax,
                      ),
                    ),
                  ),
                  // Soft vignette so type stays readable.
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                        stops: const [0, 0.45, 1],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_enter, _shine]),
                      builder: (context, _) {
                        final e = CurvedAnimation(
                          parent: _enter,
                          curve: Curves.easeOutCubic,
                        ).value;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                          child: Column(
                            children: [
                              const Spacer(flex: 2),
                              Opacity(
                                opacity: e.clamp(0, 1),
                                child: Transform.translate(
                                  offset: Offset(0, (1 - e) * 28),
                                  child: _BrandMark(
                                    shine: _shine.value,
                                    pressed: _pressedLogo,
                                    onTap: _burstShine,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),
                              Opacity(
                                opacity: ((e - 0.25) / 0.75).clamp(0, 1),
                                child: Transform.translate(
                                  offset: Offset(
                                    0,
                                    (1 - ((e - 0.25) / 0.75).clamp(0, 1)) * 16,
                                  ),
                                  child: const Column(
                                    children: [
                                      Text(
                                        'بە دڵی ئارام بکڕە',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: BoutiqueTokens.fontFamily,
                                          fontSize: 24,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.35,
                                        ),
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'بازاڕی فرۆشیارە پشکنراوەکانی کوردستان.\nسەرەتا ببینە، دواتر پارە بدە.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: BoutiqueTokens.fontFamily,
                                          fontSize: 14,
                                          height: 1.9,
                                          color: Color(0xFFB7A98E),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const Spacer(flex: 3),
                              Opacity(
                                opacity: ((e - 0.45) / 0.55).clamp(0, 1),
                                child: Column(
                                  children: [
                                    _SwipeHint(pulse: _ambient),
                                    const SizedBox(height: 18),
                                    RoniPressable(
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 54,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            gradient: BoutiqueColors.goldGradient,
                                            borderRadius: BorderRadius.circular(
                                              BoutiqueTokens.radiusMd,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: BoutiqueColors.goldBright
                                                    .withValues(alpha: 0.28),
                                                blurRadius: 24,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _goStart,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                BoutiqueTokens.radiusMd,
                                              ),
                                              child: const Center(
                                                child: Text(
                                                  'دەست پێبکە',
                                                  style: TextStyle(
                                                    fontFamily:
                                                        BoutiqueTokens.fontFamily,
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
                                    const SizedBox(height: 10),
                                    TextButton(
                                      onPressed: _goLogin,
                                      child: const Text(
                                        'هەر حسابێکت هەیە؟ وەرچێ',
                                        style: TextStyle(
                                          fontFamily: BoutiqueTokens.fontFamily,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: BoutiqueColors.muted2,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'هەولێر · کوردستان',
                                      style: TextStyle(
                                        fontFamily: BoutiqueTokens.fontFamily,
                                        fontSize: 11.5,
                                        color: Color(0xFF7A7263),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({
    required this.shine,
    required this.pressed,
    required this.onTap,
  });

  final double shine;
  final bool pressed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Soft gold halo behind the wordmark.
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        BoutiqueColors.goldBright.withValues(alpha: 0.22),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                ShaderMask(
                  blendMode: BlendMode.srcATop,
                  shaderCallback: (bounds) {
                    final x = (shine * 1.6) - 0.3;
                    return LinearGradient(
                      begin: Alignment(-1 + x * 2, -0.2),
                      end: Alignment(-0.4 + x * 2, 0.4),
                      colors: const [
                        Colors.white,
                        Color(0xFFFFF4D4),
                        Colors.white,
                      ],
                      stops: const [0.35, 0.5, 0.65],
                    ).createShader(bounds);
                  },
                  child: const RonixLogo(size: 148),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: BoutiqueColors.goldGradient,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'پەنجە بنێ — درەوشانەوە',
              style: TextStyle(
                fontFamily: BoutiqueTokens.fontFamily,
                fontSize: 11.5,
                color: BoutiqueColors.goldBright.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SwipeHint extends StatelessWidget {
  const _SwipeHint({required this.pulse});
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final y = math.sin(pulse.value * math.pi * 2) * 5;
        return Opacity(
          opacity: 0.75,
          child: Transform.translate(
            offset: Offset(0, y),
            child: const Column(
              children: [
                Icon(
                  Icons.keyboard_arrow_up_rounded,
                  color: BoutiqueColors.goldBright,
                  size: 22,
                ),
                Text(
                  'بۆ سەرەوە ڕاکێشە یان دەست پێبکە',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB7A98E),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SplashAtmospherePainter extends CustomPainter {
  _SplashAtmospherePainter({required this.t, required this.parallax});

  final double t;
  final Offset parallax;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5 + parallax.dx * 18;
    final cy = size.height * 0.38 + parallax.dy * 14;

    void orb(Offset c, double r, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: r));
      canvas.drawCircle(c, r, paint);
    }

    orb(
      Offset(
        cx + math.cos(t * math.pi * 2) * 40,
        cy + math.sin(t * math.pi * 2) * 18,
      ),
      size.width * 0.42,
      BoutiqueColors.goldBright.withValues(alpha: 0.16),
    );
    orb(
      Offset(
        cx - 70 + math.sin(t * math.pi * 2) * 28,
        cy + 90 + math.cos(t * math.pi * 2) * 22,
      ),
      size.width * 0.28,
      const Color(0xFF8A6416).withValues(alpha: 0.22),
    );
    orb(
      Offset(
        cx + 90 + math.cos(t * math.pi * 2 + 1.2) * 20,
        cy - 60,
      ),
      size.width * 0.2,
      BoutiqueColors.logoMark.withValues(alpha: 0.12),
    );

    // Fine drifting sparkles.
    final spark = Paint()..color = BoutiqueColors.goldBright.withValues(alpha: 0.35);
    for (var i = 0; i < 14; i++) {
      final a = (t + i / 14) * math.pi * 2;
      final r = 60.0 + (i % 5) * 28.0;
      final p = Offset(
        cx + math.cos(a + i) * r + parallax.dx * (6 + i),
        cy + math.sin(a * 0.8 + i * 0.7) * (r * 0.55) + parallax.dy * 4,
      );
      canvas.drawCircle(p, 1.4 + (i % 3) * 0.5, spark);
    }
  }

  @override
  bool shouldRepaint(covariant _SplashAtmospherePainter old) =>
      old.t != t || old.parallax != parallax;
}
