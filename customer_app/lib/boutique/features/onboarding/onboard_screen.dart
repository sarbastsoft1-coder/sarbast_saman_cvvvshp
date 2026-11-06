import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../widgets/roni_icons.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

class _Slide {
  const _Slide({
    required this.title,
    required this.body,
    required this.kind,
  });
  final String title;
  final String body;
  final _SceneKind kind;
}

enum _SceneKind { inspect, delivery, verified }

/// Interactive welcome flow — full-bleed animated scenes, parallax page drag,
/// tappable progress, pressable CTA. Swipe or tap to advance.
class OnboardScreen extends StatefulWidget {
  const OnboardScreen({super.key});

  @override
  State<OnboardScreen> createState() => _OnboardScreenState();
}

class _OnboardScreenState extends State<OnboardScreen> {
  final _page = PageController();
  double _pageValue = 0;
  int _index = 0;

  static const _slides = <_Slide>[
    _Slide(
      kind: _SceneKind.inspect,
      title: 'سەرەتا ببینە، دواتر پارە بدە',
      body:
          'پێش گەیاندن وێنەی کاڵاکەت دەبینیت. تەنها بۆ ئەوە پارە دەدەیت کە دەیهێڵیتەوە.',
    ),
    _Slide(
      kind: _SceneKind.delivery,
      title: 'یەک کرێی گەیاندن',
      body:
          'هەرچەند فرۆشیار بن، یەک کرێ دەدەیت. یەکەم گەیاندنت بێبەرامبەرە.',
    ),
    _Slide(
      kind: _SceneKind.verified,
      title: 'فرۆشیاری پشکنراو',
      body: 'بازاڕی فرۆشیارە پشکنراوەکانی کوردستان. پارە لە کاتی گەیاندن.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _page.addListener(() {
      setState(() => _pageValue = _page.page ?? _index.toDouble());
    });
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _finish() {
    HapticFeedback.lightImpact();
    Navigator.of(context).pushReplacementNamed(BoutiqueRoutes.otpLogin);
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      _finish();
      return;
    }
    HapticFeedback.selectionClick();
    _page.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _goTo(int i) {
    HapticFeedback.selectionClick();
    _page.animateToPage(
      i,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final last = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Atmospheric wash behind scenes — not a flat white stage.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  BoutiqueColors.goldWash,
                  p.bg,
                  BoutiqueColors.softPink.withValues(alpha: 0.65),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const RonixLogo(size: 32),
                      const Spacer(),
                      TextButton(
                        onPressed: _finish,
                        child: Text(
                          'تێپەڕین',
                          style: TextStyle(
                            fontFamily: BoutiqueTokens.fontFamily,
                            fontWeight: FontWeight.w700,
                            color: p.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _page,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) {
                      final slide = _slides[i];
                      final delta = (_pageValue - i).clamp(-1.0, 1.0);
                      return _OnboardPage(
                        slide: slide,
                        delta: delta,
                        active: (1 - delta.abs()).clamp(0.0, 1.0),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _slides.length; i++)
                      GestureDetector(
                        onTap: () => _goTo(i),
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 10,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            width: i == _index ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(99),
                              gradient: i == _index
                                  ? BoutiqueColors.goldGradient
                                  : null,
                              color: i == _index ? null : p.line,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 22),
                  child: RoniPressable(
                    child: GoldButton(
                      label: last ? 'دەست پێبکە' : 'دواتر',
                      icon: last
                          ? Icons.arrow_back_rounded
                          : Icons.arrow_back_ios_new_rounded,
                      onPressed: _next,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({
    required this.slide,
    required this.delta,
    required this.active,
  });

  final _Slide slide;
  final double delta;
  final double active;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            flex: 5,
            child: Transform.translate(
              offset: Offset(-delta * 28, delta.abs() * 10),
              child: Transform.scale(
                scale: 0.92 + active * 0.08,
                child: Opacity(
                  opacity: 0.45 + active * 0.55,
                  child: _InteractiveScene(
                    kind: slide.kind,
                    active: active,
                    drag: delta,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Transform.translate(
            offset: Offset(-delta * 16, 0),
            child: Opacity(
              opacity: active,
              child: Column(
                children: [
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: p.fg,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.body,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontSize: 14.5,
                      height: 1.85,
                      color: p.muted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _InteractiveScene extends StatefulWidget {
  const _InteractiveScene({
    required this.kind,
    required this.active,
    required this.drag,
  });

  final _SceneKind kind;
  final double active;
  final double drag;

  @override
  State<_InteractiveScene> createState() => _InteractiveSceneState();
}

class _InteractiveSceneState extends State<_InteractiveScene>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loop;
  Offset _touch = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce && _loop.isAnimating) _loop.stop();

    return LayoutBuilder(
      builder: (context, box) {
        return GestureDetector(
          onPanUpdate: (d) {
            setState(() {
              _touch = Offset(
                (_touch.dx + d.delta.dx * 0.35).clamp(-24.0, 24.0),
                (_touch.dy + d.delta.dy * 0.35).clamp(-18.0, 18.0),
              );
            });
          },
          onPanEnd: (_) {
            setState(() => _touch = Offset.zero);
            HapticFeedback.selectionClick();
          },
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _touch = const Offset(0, -8));
            Future<void>.delayed(const Duration(milliseconds: 180), () {
              if (mounted) setState(() => _touch = Offset.zero);
            });
          },
          child: AnimatedBuilder(
            animation: _loop,
            builder: (context, _) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                transform: Matrix4.translationValues(_touch.dx, _touch.dy, 0),
                child: CustomPaint(
                  size: Size(box.maxWidth, box.maxHeight),
                  painter: _ScenePainter(
                    kind: widget.kind,
                    t: reduce ? 0.35 : _loop.value,
                    active: widget.active,
                    drag: widget.drag,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ScenePainter extends CustomPainter {
  _ScenePainter({
    required this.kind,
    required this.t,
    required this.active,
    required this.drag,
  });

  final _SceneKind kind;
  final double t;
  final double active;
  final double drag;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final breath = math.sin(t * math.pi * 2) * 6 * active;

    // Soft stage disc — atmosphere, not a card.
    final stage = Paint()
      ..shader = RadialGradient(
        colors: [
          BoutiqueColors.goldBright.withValues(alpha: 0.18 * active),
          BoutiqueColors.goldWash.withValues(alpha: 0.05),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy + 20), radius: 160));
    canvas.drawCircle(Offset(cx, cy + 24), 150, stage);

    switch (kind) {
      case _SceneKind.inspect:
        _paintInspect(canvas, cx, cy, breath);
      case _SceneKind.delivery:
        _paintDelivery(canvas, cx, cy, breath);
      case _SceneKind.verified:
        _paintVerified(canvas, cx, cy, breath);
    }
  }

  void _paintInspect(Canvas canvas, double cx, double cy, double breath) {
    final phone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx + drag * -8, cy + breath),
        width: 118,
        height: 196,
      ),
      const Radius.circular(22),
    );
    canvas.drawRRect(
      phone,
      Paint()..color = BoutiqueColors.ink,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx + drag * -8, cy + breath - 4),
          width: 100,
          height: 168,
        ),
        const Radius.circular(14),
      ),
      Paint()..color = const Color(0xFFF7F1E4),
    );

    // Product tile inside phone.
    final tile = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 38 + drag * -8, cy - 52 + breath, 76, 70),
      const Radius.circular(12),
    );
    canvas.drawRRect(tile, Paint()..color = BoutiqueColors.softPink);
    canvas.drawCircle(
      Offset(cx + drag * -8, cy - 24 + breath),
      16,
      Paint()..color = BoutiqueColors.goldDeep.withValues(alpha: 0.85),
    );

    // Floating “inspect” badge — interactive feel.
    final badgeY = cy - 70 + breath - math.sin(t * math.pi * 2) * 5;
    final badge = Offset(cx + 58 + drag * 10, badgeY);
    canvas.drawCircle(
      badge,
      28,
      Paint()..color = BoutiqueColors.successGreen,
    );
    final check = Path()
      ..moveTo(badge.dx - 10, badge.dy)
      ..lineTo(badge.dx - 2, badge.dy + 8)
      ..lineTo(badge.dx + 11, badge.dy - 8);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // “سەرەتا ببینە” chip.
    final chip = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(cx - 70 + drag * 6, cy + 78 + breath),
        width: 96,
        height: 34,
      ),
      const Radius.circular(17),
    );
    canvas.drawRRect(chip, Paint()..color = Colors.white);
    canvas.drawRRect(
      chip,
      Paint()
        ..color = BoutiqueColors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintDelivery(Canvas canvas, double cx, double cy, double breath) {
    // Three packages converging into one truck path.
    for (var i = 0; i < 3; i++) {
      final spread = (1 - active) * 40 + (1 - t) * 8;
      final x = cx - 70 + i * 36 + drag * (8 - i * 2) + spread * (i - 1);
      final y = cy - 10 + breath + (i == 1 ? -8 : 6);
      final box = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 42, height: 36),
        const Radius.circular(8),
      );
      canvas.drawRRect(
        box,
        Paint()
          ..color = [
            BoutiqueColors.goldDeep,
            BoutiqueColors.ink,
            BoutiqueColors.successGreen,
          ][i],
      );
      canvas.drawLine(
        Offset(x - 16, y - 4),
        Offset(x + 16, y - 4),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..strokeWidth = 2,
      );
    }

    // Road + truck.
    final roadY = cy + 70 + breath * 0.3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 120, roadY, 240, 10),
        const Radius.circular(5),
      ),
      Paint()..color = BoutiqueColors.line2,
    );
    final truckX = cx - 40 + math.sin(t * math.pi * 2) * 18 + drag * -12;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(truckX, roadY - 38, 78, 36),
      const Radius.circular(10),
    );
    canvas.drawRRect(body, Paint()..color = BoutiqueColors.ink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(truckX + 56, roadY - 28, 28, 26),
        const Radius.circular(8),
      ),
      Paint()..color = BoutiqueColors.goldDeep,
    );
    canvas.drawCircle(
      Offset(truckX + 18, roadY - 2),
      8,
      Paint()..color = const Color(0xFF2A2418),
    );
    canvas.drawCircle(
      Offset(truckX + 68, roadY - 2),
      8,
      Paint()..color = const Color(0xFF2A2418),
    );

    // Free-delivery spark.
    canvas.drawCircle(
      Offset(cx + 78 + drag * 6, cy - 48 + breath),
      26,
      Paint()..color = BoutiqueColors.goldBright,
    );
  }

  void _paintVerified(Canvas canvas, double cx, double cy, double breath) {
    final pulse = 1 + math.sin(t * math.pi * 2) * 0.04 * active;
    final shieldCenter = Offset(cx + drag * -6, cy + breath - 8);
    canvas.save();
    canvas.translate(shieldCenter.dx, shieldCenter.dy);
    canvas.scale(pulse);

    final shield = Path()
      ..moveTo(0, -70)
      ..cubicTo(48, -58, 58, -20, 52, 20)
      ..cubicTo(40, 58, 12, 78, 0, 88)
      ..cubicTo(-12, 78, -40, 58, -52, 20)
      ..cubicTo(-58, -20, -48, -58, 0, -70)
      ..close();

    canvas.drawPath(
      shield,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            BoutiqueColors.goldBright,
            BoutiqueColors.goldDeep,
          ],
        ).createShader(const Rect.fromLTWH(-60, -80, 120, 180)),
    );
    canvas.drawPath(
      shield,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    final check = Path()
      ..moveTo(-22, 4)
      ..lineTo(-6, 22)
      ..lineTo(28, -18);
    canvas.drawPath(
      check,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    // Orbiting trust dots.
    for (var i = 0; i < 5; i++) {
      final a = t * math.pi * 2 + i * (math.pi * 2 / 5);
      final r = 108.0;
      final o = Offset(
        cx + math.cos(a) * r + drag * 4,
        cy + math.sin(a) * (r * 0.55) + breath,
      );
      canvas.drawCircle(
        o,
        5,
        Paint()..color = BoutiqueColors.ink.withValues(alpha: 0.55),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      old.t != t || old.active != active || old.drag != drag || old.kind != kind;
}
