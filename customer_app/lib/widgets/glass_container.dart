import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import 'dart:math' as math;

/// Glassmorphic container — soft frosted panel with subtle gradient sheen.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final double blur;
  final Color? tint;
  final Border? border;
  final List<BoxShadow>? shadow;

  const GlassContainer({
    super.key,
    required this.child,
    this.radius = EarthTheme.radiusMd,
    this.padding = const EdgeInsets.all(16),
    this.blur = 18,
    this.tint,
    this.border,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (tint ?? Colors.white).withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(radius),
        border: border ??
            Border.all(
              color: Colors.white.withValues(alpha: 0.7),
              width: 1.2,
            ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x44FFFFFF),
            Color(0x08FFFFFF),
          ],
        ),
        boxShadow: shadow ??
            [
              BoxShadow(
                color: EarthTheme.forestGreen.withValues(alpha: 0.08),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
      ),
      child: child,
    );
  }
}

/// Primary gradient button with shine effect on press.
class GradientButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Gradient gradient;
  final double height;
  final double radius;
  final bool expanded;
  final bool loading;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry padding;

  const GradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.gradient = const LinearGradient(
      colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.height = 54,
    this.radius = EarthTheme.radiusMd,
    this.expanded = true,
    this.loading = false,
    this.textStyle,
    this.padding = const EdgeInsets.symmetric(horizontal: 22),
  });

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    final btn = Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: AnimatedContainer(
        duration: EarthTheme.durFast,
        curve: EarthTheme.curveOut,
        height: widget.height,
        decoration: BoxDecoration(
          gradient: widget.gradient,
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: _hover && !disabled
              ? EarthTheme.terracottaGlow
              : [
                  BoxShadow(
                    color: EarthTheme.terracotta.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // Shine
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.radius),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 80,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.30),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(EarthTheme.radiusMd),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: widget.loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Row(
                      mainAxisSize: widget.expanded
                          ? MainAxisSize.max
                          : MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.label,
                          style: widget.textStyle ??
                              const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _hover = true),
        onTapUp: (_) => setState(() => _hover = false),
        onTapCancel: () => setState(() => _hover = false),
        onTap: disabled ? null : widget.onPressed,
        child: widget.expanded ? SizedBox(width: double.infinity, child: btn) : btn,
      ),
    );
  }
}

/// Pill badge with optional dot prefix.
class PillBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final bool dot;
  final IconData? icon;
  final EdgeInsetsGeometry padding;
  final double radius;

  const PillBadge({
    super.key,
    required this.label,
    required this.color,
    this.textColor = Colors.white,
    this.dot = false,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    this.radius = EarthTheme.radiusPill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: textColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: textColor,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Soft gradient orb — used as decorative background blob.
class GradientOrb extends StatelessWidget {
  final double size;
  final Gradient gradient;
  final double opacity;

  const GradientOrb({
    super.key,
    required this.size,
    required this.gradient,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 30,
            spreadRadius: 2,
          ),
        ],
      ),
    );
  }
}

/// Soft pulsing glow around a child widget.
class GlowWrap extends StatefulWidget {
  final Widget child;
  final Color color;
  final double intensity;

  const GlowWrap({
    super.key,
    required this.child,
    this.color = EarthTheme.terracotta,
    this.intensity = 0.35,
  });

  @override
  State<GlowWrap> createState() => _GlowWrapState();
}

class _GlowWrapState extends State<GlowWrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value;
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: widget.intensity * (0.6 + t * 0.4)),
                blurRadius: 30 + t * 14,
                spreadRadius: 4 + t * 6,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Icon button with press scale and optional badge.
class SoftIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? color;
  final int? badgeCount;
  final double size;
  final double radius;
  final String? tooltip;

  const SoftIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.background,
    this.color,
    this.badgeCount,
    this.size = 40,
    this.radius = EarthTheme.radiusSm,
    this.tooltip,
  });

  @override
  State<SoftIconButton> createState() => _SoftIconButtonState();
}

class _SoftIconButtonState extends State<SoftIconButton> {
  @override
  Widget build(BuildContext context) {
    final btn = PressScale(
      onTap: widget.onTap,
      scale: 0.92,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.background ?? Colors.white,
          borderRadius: BorderRadius.circular(widget.radius),
          border: Border.all(color: EarthTheme.borderLight),
          boxShadow: EarthTheme.subtleShadow,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              widget.icon,
              size: widget.size * 0.5,
              color: widget.color ?? EarthTheme.forestGreen,
            ),
            if (widget.badgeCount != null && widget.badgeCount! > 0)
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: EarthTheme.terracotta,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: EarthTheme.warmSand,
                      width: 1.6,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.badgeCount! > 9 ? '9+' : '${widget.badgeCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (widget.tooltip != null) {
      return Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}

/// Animated underline link / "see all".
class AnimatedLink extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final double fontSize;

  const AnimatedLink({
    super.key,
    required this.label,
    this.onTap,
    this.color = EarthTheme.terracotta,
    this.fontSize = 13,
  });

  @override
  State<AnimatedLink> createState() => _AnimatedLinkState();
}

class _AnimatedLinkState extends State<AnimatedLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w700,
                color: widget.color,
              ),
            ),
            AnimatedContainer(
              duration: EarthTheme.durFast,
              width: _hover ? 18 : 0,
              height: 1.6,
              margin: const EdgeInsets.only(left: 4),
              color: widget.color,
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.arrow_forward_rounded,
              size: widget.fontSize + 2,
              color: widget.color,
            ),
          ],
        ),
      ),
    );
  }
}

/// Decorative confetti burst — used on order placed / reward claim.
class ConfettiBurst extends StatefulWidget {
  final int particleCount;
  final List<Color> colors;
  final double size;

  const ConfettiBurst({
    super.key,
    this.particleCount = 24,
    this.colors = const [
      EarthTheme.terracotta,
      EarthTheme.clayOchre,
      EarthTheme.sageGreen,
      EarthTheme.goldenGlow,
      EarthTheme.forestGreen,
      EarthTheme.coral,
    ],
    this.size = 220,
  });

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    final rnd = math.Random();
    _particles = List.generate(widget.particleCount, (i) {
      final angle = rnd.nextDouble() * math.pi * 2;
      final dist = 40 + rnd.nextDouble() * 80;
      return _Particle(
        dx: math.cos(angle) * dist,
        dy: math.sin(angle) * dist,
        rot: rnd.nextDouble() * math.pi * 2,
        color: widget.colors[i % widget.colors.length],
        size: 4 + rnd.nextDouble() * 6,
        delay: rnd.nextDouble() * 0.2,
      );
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: _particles.map((p) {
              final t = ((_ctrl.value - p.delay) / (1 - p.delay)).clamp(0.0, 1.0);
              final fade = (1 - t).clamp(0.0, 1.0);
              return Transform.translate(
                offset: Offset(p.dx * t, p.dy * t + (1 - t) * 0),
                child: Opacity(
                  opacity: fade,
                  child: Transform.rotate(
                    angle: p.rot * t * 2,
                    child: Container(
                      width: p.size,
                      height: p.size * 0.5,
                      decoration: BoxDecoration(
                        color: p.color,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double dx, dy, rot, size, delay;
  final Color color;
  _Particle({
    required this.dx,
    required this.dy,
    required this.rot,
    required this.size,
    required this.delay,
    required this.color,
  });
}
