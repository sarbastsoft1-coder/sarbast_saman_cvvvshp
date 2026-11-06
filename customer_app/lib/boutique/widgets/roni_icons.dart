import 'package:flutter/material.dart';

/// Icons & logo mark copied from `roni_web_prototype/roni-shop.html`
/// (same viewBoxes / path data / stroke 1.9).
class RoniIcon extends StatelessWidget {
  const RoniIcon(
    this.kind, {
    super.key,
    this.size = 22,
    this.color,
    this.strokeWidth = 1.9,
  });

  final RoniIconKind kind;
  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? Colors.white;
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _RoniIconPainter(kind, c, strokeWidth)),
    );
  }
}

enum RoniIconKind {
  home,
  grid,
  cart,
  person,
  bell,
  search,
  heart,
  heartFill,
  shieldCheck,
  cash,
  camera,
  filter,
  plus,
  star,
  chevron,
}

class _RoniIconPainter extends CustomPainter {
  _RoniIconPainter(this.kind, this.color, this.stroke);

  final RoniIconKind kind;
  final Color color;
  final double stroke;

  Paint get _stroke => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    canvas.save();
    canvas.scale(s / 24, s / 24);

    switch (kind) {
      // nav: M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z
      case RoniIconKind.home:
        canvas.drawPath(
          Path()
            ..moveTo(3, 10.5)
            ..lineTo(12, 3)
            ..lineTo(21, 10.5)
            ..lineTo(21, 20)
            ..cubicTo(21, 20.55, 20.55, 21, 20, 21)
            ..lineTo(15, 21)
            ..lineTo(15, 15)
            ..lineTo(9, 15)
            ..lineTo(9, 21)
            ..lineTo(4, 21)
            ..cubicTo(3.45, 21, 3, 20.55, 3, 20)
            ..close(),
          _stroke,
        );
      case RoniIconKind.grid:
        for (final r in const [
          Rect.fromLTWH(3.5, 3.5, 7, 7),
          Rect.fromLTWH(13.5, 3.5, 7, 7),
          Rect.fromLTWH(3.5, 13.5, 7, 7),
          Rect.fromLTWH(13.5, 13.5, 7, 7),
        ]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(r, const Radius.circular(1.5)),
            _stroke,
          );
        }
      // M3 4h2l2.2 11h10.6L20 7H6.2 + circles
      case RoniIconKind.cart:
        canvas.drawPath(
          Path()
            ..moveTo(3, 4)
            ..lineTo(5, 4)
            ..lineTo(7.2, 15)
            ..lineTo(17.8, 15)
            ..lineTo(20, 7)
            ..lineTo(6.2, 7),
          _stroke,
        );
        canvas.drawCircle(const Offset(9, 19.5), 1.5, _stroke);
        canvas.drawCircle(const Offset(17, 19.5), 1.5, _stroke);
      case RoniIconKind.person:
        canvas.drawCircle(const Offset(12, 8), 4, _stroke);
        canvas.drawPath(
          Path()
            ..moveTo(4, 21)
            ..cubicTo(5.5, 17, 8.5, 15, 12, 15)
            ..cubicTo(15.5, 15, 18.5, 17, 20, 21),
          _stroke,
        );
      // header bell
      case RoniIconKind.bell:
        canvas.drawPath(
          Path()
            ..moveTo(6, 16)
            ..lineTo(6, 11)
            ..cubicTo(6, 7.686, 8.686, 5, 12, 5)
            ..cubicTo(15.314, 5, 18, 7.686, 18, 11)
            ..lineTo(18, 16)
            ..lineTo(20, 18)
            ..lineTo(4, 18)
            ..close(),
          _stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(10, 20)
            ..cubicTo(10.667, 21.333, 13.333, 21.333, 14, 20),
          _stroke,
        );
      // search: circle 11,11 r7 + M20 20l-3.5-3.5
      case RoniIconKind.search:
        final sp = _stroke..strokeWidth = 2;
        canvas.drawCircle(const Offset(11, 11), 7, sp);
        canvas.drawLine(const Offset(20, 20), const Offset(16.5, 16.5), sp);
      case RoniIconKind.heart:
        canvas.drawPath(_heartPath(), _stroke..strokeWidth = 2);
      case RoniIconKind.heartFill:
        canvas.drawPath(
          _heartPath(),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );
      // trust shield
      case RoniIconKind.shieldCheck:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3)
            ..lineTo(19, 6)
            ..lineTo(19, 11)
            ..cubicTo(19, 16, 15.5, 19.5, 12, 21)
            ..cubicTo(8.5, 19.5, 5, 16, 5, 11)
            ..lineTo(5, 6)
            ..close(),
          _stroke..strokeWidth = 2,
        );
        canvas.drawPath(
          Path()
            ..moveTo(9, 12)
            ..lineTo(11, 14)
            ..lineTo(15, 10),
          _stroke..strokeWidth = 2,
        );
      // trust cash / wallet
      case RoniIconKind.cash:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 6, 18, 12),
            const Radius.circular(2),
          ),
          _stroke..strokeWidth = 2,
        );
        canvas.drawCircle(const Offset(12, 12), 2.5, _stroke);
      // trust camera
      case RoniIconKind.camera:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(3, 6, 18, 14),
            const Radius.circular(2),
          ),
          _stroke..strokeWidth = 2,
        );
        canvas.drawCircle(const Offset(12, 13), 3.5, _stroke);
        canvas.drawPath(
          Path()
            ..moveTo(8, 6)
            ..lineTo(9.5, 4)
            ..lineTo(14.5, 4)
            ..lineTo(16, 6),
          _stroke,
        );
      // filter: M4 6h16M7 12h10M10 18h4
      case RoniIconKind.filter:
        final p = _stroke..strokeWidth = 2;
        canvas.drawLine(const Offset(4, 6), const Offset(20, 6), p);
        canvas.drawLine(const Offset(7, 12), const Offset(17, 12), p);
        canvas.drawLine(const Offset(10, 18), const Offset(14, 18), p);
      case RoniIconKind.plus:
        canvas.drawLine(const Offset(12, 6), const Offset(12, 18), _stroke);
        canvas.drawLine(const Offset(6, 12), const Offset(18, 12), _stroke);
      case RoniIconKind.star:
        canvas.drawPath(
          Path()
            ..moveTo(12, 3.5)
            ..lineTo(14.2, 9)
            ..lineTo(20, 9.4)
            ..lineTo(15.6, 13.2)
            ..lineTo(17.2, 19)
            ..lineTo(12, 15.8)
            ..lineTo(6.8, 19)
            ..lineTo(8.4, 13.2)
            ..lineTo(4, 9.4)
            ..lineTo(9.8, 9)
            ..close(),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..isAntiAlias = true,
        );
      case RoniIconKind.chevron:
        canvas.drawPath(
          Path()
            ..moveTo(14, 6)
            ..lineTo(8, 12)
            ..lineTo(14, 18),
          _stroke,
        );
    }
    canvas.restore();
  }

  /// HTML gives heart: M12 20s-7-4.4-7-10a4 4 0 0 1 7-2.6A4 4 0 0 1 19 10c0 5.6-7 10-7 10z
  Path _heartPath() => Path()
    ..moveTo(12, 20)
    ..cubicTo(5, 15.6, 5, 10, 5, 10)
    ..cubicTo(5, 7.79, 6.79, 6, 9, 6)
    ..cubicTo(10.2, 6, 11.3, 6.55, 12, 7.4)
    ..cubicTo(12.7, 6.55, 13.8, 6, 15, 6)
    ..cubicTo(17.21, 6, 19, 7.79, 19, 10)
    ..cubicTo(19, 15.6, 12, 20, 12, 20)
    ..close();

  @override
  bool shouldRepaint(covariant _RoniIconPainter old) =>
      old.kind != kind || old.color != color || old.stroke != stroke;
}

/// Brand mark — gold Ronix coin medallion (`assets/images/ronix_logo.png`).
class RonixLogo extends StatelessWidget {
  const RonixLogo({
    super.key,
    this.size = 48,
    this.circular = true,
  });

  final double size;
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/images/ronix_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Image.asset(
        'assets/images/ronix_coin.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (_, _, _) => _RonixLogoFallback(size: size),
      ),
    );
    if (!circular) return image;
    return ClipOval(child: image);
  }
}

class _RonixLogoFallback extends StatelessWidget {
  const _RonixLogoFallback({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFF9A6B1A), Color(0xFFE8C56A), Color(0xFFF3D789)],
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
          ),
        ),
        child: Text(
          'R',
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.w800,
            fontSize: size * .42,
            color: const Color(0xFF1F1606),
            height: 1,
          ),
        ),
      );
}

/// Compact brand mark for headers (same coin as [RonixLogo]).
class RoniLogoMark extends StatelessWidget {
  const RoniLogoMark({super.key, this.height = 28, this.color});
  final double height;
  /// Kept for call-site compatibility; coin art ignores tint.
  final Color? color;

  @override
  Widget build(BuildContext context) => RonixLogo(size: height);
}

/// HTML `.rx` Ronix coin — prefer webp extracted from the artifact.
class RonixCoin extends StatelessWidget {
  const RonixCoin({super.key, this.size = 40, this.elevated = false});
  final double size;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final coin = Image.asset(
      'assets/images/ronix_coin.webp',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(
        'assets/images/ronix_coin.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF9A6B1A), Color(0xFFE8C56A), Color(0xFFF3D789)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
          ),
          child: Text(
            'R',
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontWeight: FontWeight.w800,
              fontSize: size * .42,
              color: const Color(0xFF1F1606),
              height: 1,
            ),
          ),
        ),
      ),
    );
    return ClipOval(child: coin);
  }
}
