import 'package:flutter/material.dart';

/// Illustration keys matching the Claude HTML product SVGs (`p-honey`, `p-scarf`, …).
enum ProductArtKind {
  pan,
  scarf,
  dress,
  kettle,
  heater,
  blanket,
  bag,
  kid,
  soap,
  shoe,
  vest,
  jar,
}

/// Renders a flat product illustration on a soft surface — same look as the HTML mock.
class ProductArt extends StatelessWidget {
  const ProductArt({super.key, required this.kind, this.size = 96});

  final ProductArtKind kind;
  final double size;

  static ProductArtKind fromKey(String? key) {
    switch (key) {
      case 'scarf':
        return ProductArtKind.scarf;
      case 'dress':
        return ProductArtKind.dress;
      case 'kettle':
        return ProductArtKind.kettle;
      case 'heater':
        return ProductArtKind.heater;
      case 'blanket':
        return ProductArtKind.blanket;
      case 'bag':
        return ProductArtKind.bag;
      case 'kid':
        return ProductArtKind.kid;
      case 'soap':
        return ProductArtKind.soap;
      case 'shoe':
        return ProductArtKind.shoe;
      case 'vest':
        return ProductArtKind.vest;
      case 'jar':
        return ProductArtKind.jar;
      case 'pan':
      default:
        return ProductArtKind.pan;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _ProductArtPainter(kind),
    );
  }
}

class _ProductArtPainter extends CustomPainter {
  _ProductArtPainter(this.kind);
  final ProductArtKind kind;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide / 64;
    canvas.scale(s, s);
    switch (kind) {
      case ProductArtKind.pan:
        _pan(canvas);
      case ProductArtKind.scarf:
        _scarf(canvas);
      case ProductArtKind.dress:
        _dress(canvas);
      case ProductArtKind.kettle:
        _kettle(canvas);
      case ProductArtKind.heater:
        _heater(canvas);
      case ProductArtKind.blanket:
        _blanket(canvas);
      case ProductArtKind.bag:
        _bag(canvas);
      case ProductArtKind.kid:
        _kid(canvas);
      case ProductArtKind.soap:
        _soap(canvas);
      case ProductArtKind.shoe:
        _shoe(canvas);
      case ProductArtKind.vest:
        _vest(canvas);
      case ProductArtKind.jar:
        _jar(canvas);
    }
  }

  void _shadow(
    Canvas canvas, {
    double cx = 32,
    double cy = 56,
    double rx = 18,
  }) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: 5),
      Paint()..color = const Color(0x14000000),
    );
  }

  void _pan(Canvas canvas) {
    _shadow(canvas, cx: 30, cy: 55, rx: 24);
    final handle = Path()
      ..moveTo(46, 33.5)
      ..lineTo(60, 29)
      ..lineTo(61.6, 33.9)
      ..lineTo(47.6, 38.5)
      ..close();
    canvas.drawPath(handle, Paint()..color = const Color(0xFF7A4E2A));
    canvas.drawPath(
      Path()
        ..moveTo(46, 33.5)
        ..lineTo(49, 32.5)
        ..lineTo(50.6, 37.4)
        ..lineTo(47.6, 38.5)
        ..close(),
      Paint()..color = const Color(0xFF2B2F36),
    );
    canvas.drawOval(
      const Rect.fromLTWH(4, 25, 46, 22),
      Paint()..color = const Color(0xFF2B2F36),
    );
    canvas.drawOval(
      const Rect.fromLTWH(7, 26.7, 40, 17.6),
      Paint()..color = const Color(0xFF4A5059),
    );
    final dots = Paint()..color = const Color(0xFF8F969F);
    for (final p in [
      const Offset(18, 34),
      const Offset(24, 38.5),
      const Offset(31, 33),
      const Offset(36, 37.5),
      const Offset(27, 36),
      const Offset(40, 34),
    ]) {
      canvas.drawCircle(p, 0.9, dots);
    }
  }

  void _scarf(Canvas canvas) {
    _shadow(canvas, cy: 58, rx: 17);
    canvas.drawPath(
      Path()
        ..moveTo(13, 11)
        ..lineTo(51, 11)
        ..lineTo(44, 25)
        ..lineTo(20, 25)
        ..close(),
      Paint()..color = const Color(0xFF8E5BD0),
    );
    canvas.drawPath(
      Path()
        ..moveTo(21, 23)
        ..lineTo(15, 55)
        ..lineTo(24, 51)
        ..lineTo(28, 55)
        ..lineTo(32, 25)
        ..close(),
      Paint()..color = const Color(0xFF7A45C2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(40, 23)
        ..lineTo(44, 50)
        ..lineTo(36, 47)
        ..lineTo(37, 25)
        ..close(),
      Paint()..color = const Color(0xFFA27BE0),
    );
    final gold = Paint()..color = const Color(0xFFF8C24A);
    canvas.drawCircle(const Offset(25, 16), 1.8, gold);
    canvas.drawCircle(const Offset(32, 16), 1.8, gold);
    canvas.drawCircle(const Offset(39, 16), 1.8, gold);
  }

  void _dress(Canvas canvas) {
    _shadow(canvas, cy: 58, rx: 15);
    canvas.drawPath(
      Path()
        ..moveTo(26, 12)
        ..lineTo(10, 25)
        ..lineTo(15, 30)
        ..lineTo(26, 21)
        ..close(),
      Paint()..color = const Color(0xFFE85466),
    );
    canvas.drawPath(
      Path()
        ..moveTo(38, 12)
        ..lineTo(54, 25)
        ..lineTo(49, 30)
        ..lineTo(38, 21)
        ..close(),
      Paint()..color = const Color(0xFFE85466),
    );
    canvas.drawPath(
      Path()
        ..moveTo(26, 8)
        ..lineTo(38, 8)
        ..lineTo(41, 14)
        ..lineTo(38, 17)
        ..lineTo(46, 56)
        ..lineTo(18, 56)
        ..lineTo(26, 17)
        ..lineTo(23, 14)
        ..close(),
      Paint()..color = const Color(0xFFD63447),
    );
    canvas.drawPath(
      Path()
        ..moveTo(27, 8)
        ..lineTo(37, 8)
        ..lineTo(32, 14)
        ..close(),
      Paint()..color = const Color(0xFFF8C24A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(23, 27, 18, 4),
        const Radius.circular(1),
      ),
      Paint()..color = const Color(0xFFF8C24A),
    );
    final gold = Paint()..color = const Color(0xFFF8C24A);
    canvas.drawCircle(const Offset(32, 39), 1.7, gold);
    canvas.drawCircle(const Offset(26, 46), 1.7, gold);
    canvas.drawCircle(const Offset(38, 46), 1.7, gold);
  }

  void _kettle(Canvas canvas) {
    _shadow(canvas, cy: 57, rx: 17);
    canvas.drawPath(
      Path()
        ..moveTo(21, 25)
        ..cubicTo(21, 9, 43, 9, 43, 25),
      Paint()
        ..color = const Color(0xFF2B2F36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      Path()
        ..moveTo(44, 41)
        ..lineTo(55, 29)
        ..lineTo(57.4, 31.1)
        ..lineTo(47, 47)
        ..close(),
      Paint()..color = const Color(0xFFAEB8C1),
    );
    canvas.drawPath(
      Path()
        ..moveTo(18, 54)
        ..lineTo(46, 54)
        ..lineTo(43, 30)
        ..cubicTo(43, 22, 21, 22, 21, 30)
        ..close(),
      Paint()..color = const Color(0xFFC9D1D8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(17, 50, 30, 5),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFF2B2F36),
    );
  }

  void _heater(Canvas canvas) {
    _shadow(canvas, cy: 58, rx: 16);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 9, 38, 42),
        const Radius.circular(7),
      ),
      Paint()..color = const Color(0xFFE9EBEE),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(17.5, 15, 29, 26),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF2B2F36),
    );
    final bars = [
      (18.5, const Color(0xFFFF7006)),
      (24.5, const Color(0xFFFFB23F)),
      (30.5, const Color(0xFFFF7006)),
      (36.0, const Color(0xFFFFB23F)),
    ];
    for (final (y, c) in bars) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(21, y, 22, y == 36 ? 2.5 : 3.2),
          const Radius.circular(1.5),
        ),
        Paint()..color = c,
      );
    }
  }

  void _blanket(Canvas canvas) {
    _shadow(canvas, cy: 58, rx: 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(10, 14, 44, 36),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFB83A3A),
    );
    canvas.drawRect(
      const Rect.fromLTWH(10, 20, 44, 4),
      Paint()..color = const Color(0xFFF2C14E),
    );
    canvas.drawRect(
      const Rect.fromLTWH(10, 40, 44, 4),
      Paint()..color = const Color(0xFF2F5D8C),
    );
    canvas.drawPath(
      Path()
        ..moveTo(27, 32)
        ..lineTo(32, 28)
        ..lineTo(37, 32)
        ..lineTo(32, 36)
        ..close(),
      Paint()..color = const Color(0xFFFFFFFF),
    );
  }

  void _bag(Canvas canvas) {
    _shadow(canvas, cy: 59, rx: 17);
    canvas.drawPath(
      Path()
        ..moveTo(22, 15)
        ..cubicTo(22, 8, 42, 8, 42, 15)
        ..lineTo(42, 17)
        ..lineTo(38, 17)
        ..lineTo(38, 15)
        ..cubicTo(38, 11, 26, 11, 26, 15)
        ..lineTo(26, 17)
        ..lineTo(22, 17)
        ..close(),
      Paint()..color = const Color(0xFF1F5FB8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 16, 38, 41),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF2F7DE1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19.5, 35, 25, 15),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFFF8D91A),
    );
  }

  void _kid(Canvas canvas) {
    _shadow(canvas, cy: 58, rx: 16);
    canvas.drawCircle(
      const Offset(21.5, 18),
      5.5,
      Paint()..color = const Color(0xFFFFB3CA),
    );
    canvas.drawCircle(
      const Offset(42.5, 18),
      5.5,
      Paint()..color = const Color(0xFFFFB3CA),
    );
    canvas.drawPath(
      Path()
        ..moveTo(26, 10)
        ..lineTo(38, 10)
        ..lineTo(40, 16)
        ..lineTo(38, 19)
        ..lineTo(48, 53)
        ..lineTo(16, 53)
        ..lineTo(26, 19)
        ..lineTo(24, 16)
        ..close(),
      Paint()..color = const Color(0xFFFF8FB1),
    );
    canvas.drawPath(
      Path()
        ..moveTo(27.5, 24)
        ..lineTo(32, 26.2)
        ..lineTo(36.5, 24)
        ..lineTo(36.5, 30.4)
        ..lineTo(32, 28.2)
        ..lineTo(27.5, 30.4)
        ..close(),
      Paint()..color = const Color(0xFFF8D91A),
    );
  }

  void _soap(Canvas canvas) {
    _shadow(canvas, cy: 55, rx: 22);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(26, 19, 29, 17),
        const Radius.circular(5),
      ),
      Paint()..color = const Color(0xFF6E9A3A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 30, 32, 22),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFF8DB255),
    );
  }

  void _shoe(Canvas canvas) {
    _shadow(canvas, cy: 55, rx: 24);
    canvas.drawPath(
      Path()
        ..moveTo(7, 41)
        ..cubicTo(7, 33, 11, 26, 17, 24)
        ..lineTo(23, 30)
        ..cubicTo(29, 33, 37, 35, 45, 36)
        ..cubicTo(51, 36.8, 56, 39, 56, 43)
        ..lineTo(56, 46)
        ..lineTo(7, 46)
        ..close(),
      Paint()..color = const Color(0xFFF6F0E4),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(7, 46, 49, 6),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFF8A6A45),
    );
  }

  void _vest(Canvas canvas) {
    _shadow(canvas, cy: 59, rx: 16);
    canvas.drawPath(
      Path()
        ..moveTo(22, 7)
        ..lineTo(42, 7)
        ..lineTo(51, 15)
        ..lineTo(46, 22)
        ..lineTo(43, 19)
        ..lineTo(43, 57)
        ..lineTo(21, 57)
        ..lineTo(21, 19)
        ..lineTo(18, 22)
        ..lineTo(13, 15)
        ..close(),
      Paint()..color = const Color(0xFFD9C8AC),
    );
    canvas.drawRect(
      const Rect.fromLTWH(21, 31, 22, 7),
      Paint()..color = const Color(0xFFD63447),
    );
  }

  void _jar(Canvas canvas) {
    _shadow(canvas, cy: 58, rx: 14);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 8, 24, 8),
        const Radius.circular(2.5),
      ),
      Paint()..color = const Color(0xFFA0703F),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(18, 16, 28, 35),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFE6F2F5),
    );
  }

  @override
  bool shouldRepaint(covariant _ProductArtPainter oldDelegate) =>
      oldDelegate.kind != kind;
}
