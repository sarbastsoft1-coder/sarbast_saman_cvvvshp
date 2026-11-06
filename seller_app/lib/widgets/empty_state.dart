import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Small decorative icons reused across empty / hero states.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: AppColors.brandGradient,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 42, color: Colors.white),
          ),
          const SizedBox(height: 18),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textMuted),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Subtle floating-orbs background used on the splash + login screens.
class FloatingOrbsBackground extends StatefulWidget {
  const FloatingOrbsBackground({super.key, this.seed = 7, this.colors});
  final int seed;
  final List<Color>? colors;

  @override
  State<FloatingOrbsBackground> createState() =>
      _FloatingOrbsBackgroundState();
}

class _FloatingOrbsBackgroundState extends State<FloatingOrbsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.colors ??
        const [
          AppColors.terracottaSoft,
          AppColors.gold,
          AppColors.sageLight,
          AppColors.clayOchre,
        ];
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return CustomPaint(
          painter: _OrbsPainter(
            t: _ctrl.value,
            seed: widget.seed,
            colors: palette,
          ),
          child: const SizedBox.expand(),
        );
      },
    );
  }
}

class _OrbsPainter extends CustomPainter {
  _OrbsPainter({required this.t, required this.seed, required this.colors});
  final double t;
  final int seed;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed);
    for (int i = 0; i < 6; i++) {
      final radius = size.shortestSide * (0.18 + rnd.nextDouble() * 0.18);
      final cx = rnd.nextDouble() * size.width;
      final cy = rnd.nextDouble() * size.height;
      final dx = math.sin((t * 2 * math.pi) + i) * 36;
      final dy = math.cos((t * 2 * math.pi) + i * 0.7) * 36;
      final color = colors[i % colors.length].withValues(alpha: 0.28);
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ).createShader(
          Rect.fromCircle(center: Offset(cx + dx, cy + dy), radius: radius),
        );
      canvas.drawCircle(Offset(cx + dx, cy + dy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrbsPainter old) => old.t != t;
}

/// Decorative animated progress ring – used on the splash screen.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 96,
    this.stroke = 4,
    this.color = AppColors.terracotta,
    this.trackColor = Colors.white24,
  });

  final double progress; // 0..1
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      builder: (context, value, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  strokeWidth: stroke,
                  value: value,
                  color: color,
                  backgroundColor: trackColor,
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}