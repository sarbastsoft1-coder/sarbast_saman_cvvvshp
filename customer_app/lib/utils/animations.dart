import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/earth_theme.dart';

// ───────────────────────────────────────────────────────────
//  Custom page route — shared-axis (X) transition
// ───────────────────────────────────────────────────────────
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  SharedAxisPageRoute({
    required WidgetBuilder builder,
    Duration duration = const Duration(milliseconds: 420),
    super.settings,
  }) : super(
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          pageBuilder: (ctx, anim, secAnim) => builder(ctx),
          transitionsBuilder: (ctx, anim, secAnim, child) {
            final curved = CurvedAnimation(parent: anim, curve: EarthTheme.curveOut);
            final fade = Tween<double>(begin: 0.0, end: 1.0).animate(curved);
            final slide = Tween<Offset>(
              begin: const Offset(0.10, 0),
              end: Offset.zero,
            ).animate(curved);
            return FadeTransition(
              opacity: fade,
              child: SlideTransition(position: slide, child: child),
            );
          },
        );
}

// ───────────────────────────────────────────────────────────
//  Staggered entrance — wrap each list item
// ───────────────────────────────────────────────────────────
class StaggeredFadeSlide extends StatelessWidget {
  final int index;
  final Duration baseDelay;
  final Duration itemDelay;
  final Duration duration;
  final Offset slideFrom;
  final Widget child;

  const StaggeredFadeSlide({
    super.key,
    required this.index,
    required this.child,
    this.baseDelay = Duration.zero,
    this.itemDelay = const Duration(milliseconds: 70),
    this.duration = const Duration(milliseconds: 520),
    this.slideFrom = const Offset(0, 0.12),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: duration,
      curve: EarthTheme.curveOut,
      builder: (context, value, c) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              slideFrom.dx * (1 - value),
              slideFrom.dy * (1 - value) * 60,
            ),
            child: c,
          ),
        );
      },
    );
  }
}

// Use this in lists — passes via an animation delay list.
class StaggeredItem extends StatefulWidget {
  final int index;
  final Duration delay;
  final Duration duration;
  final Widget child;

  const StaggeredItem({
    super.key,
    required this.index,
    required this.child,
    this.delay = const Duration(milliseconds: 60),
    this.duration = const Duration(milliseconds: 520),
  });

  @override
  State<StaggeredItem> createState() => _StaggeredItemState();
}

class _StaggeredItemState extends State<StaggeredItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: EarthTheme.curveOut),
    );
    _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: EarthTheme.curveOut));
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Animated counter (smooth interpolation between values)
// ───────────────────────────────────────────────────────────
class AnimatedCounter extends StatefulWidget {
  final double value;
  final int decimals;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.decimals = 0,
    this.style,
    this.duration = const Duration(milliseconds: 700),
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _old = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _anim = AlwaysStoppedAnimation(widget.value);
    _old = widget.value;
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _ctrl.dispose();
      _ctrl = AnimationController(vsync: this, duration: widget.duration);
      _anim = Tween<double>(begin: _old, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: EarthTheme.curveOut),
      );
      _old = widget.value;
      _ctrl.forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, _) {
        final v = _anim.value;
        final formatted = v.toStringAsFixed(widget.decimals);
        return Text(
          '${widget.prefix ?? ''}$formatted${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Shimmer skeleton loader
// ───────────────────────────────────────────────────────────
class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const Shimmer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? EarthTheme.shimmerBase;
    final highlight = widget.highlightColor ?? EarthTheme.shimmerHighlight;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final dx = (_ctrl.value * 2 - 1) * rect.width;
            return LinearGradient(
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
              begin: Alignment(dx - 1, -0.3),
              end: Alignment(dx + 1, 0.3),
            ).createShader(rect);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Pulsing dot (live indicator)
// ───────────────────────────────────────────────────────────
class PulseDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulseDot({super.key, required this.color, this.size = 8});

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size * 2.6,
      height: widget.size * 2.6,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final v = _ctrl.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: (1 - v).clamp(0.0, 1.0) * 0.55,
                child: Container(
                  width: widget.size * (1.0 + v * 2.0),
                  height: widget.size * (1.0 + v * 2.0),
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Floating element — gentle bob/rotate/sway
// ───────────────────────────────────────────────────────────
class FloatingElement extends StatefulWidget {
  final Widget child;
  final double amplitude;
  final double speed;
  final double rotate;
  final bool sway;

  const FloatingElement({
    super.key,
    required this.child,
    this.amplitude = 8,
    this.speed = 1,
    this.rotate = 0,
    this.sway = true,
  });

  @override
  State<FloatingElement> createState() => _FloatingElementState();
}

class _FloatingElementState extends State<FloatingElement>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (3500 / widget.speed).round()),
    )..repeat();
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
        final dy = -math.sin(t * math.pi * 2) * widget.amplitude;
        final dx = widget.sway
            ? math.cos(t * math.pi * 2) * widget.amplitude * 0.4
            : 0.0;
        final rot = math.sin(t * math.pi * 2) * widget.rotate;
        return Transform.translate(
          offset: Offset(dx, dy),
          child: Transform.rotate(angle: rot, child: child),
        );
      },
      child: widget.child,
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Press-scale wrapper — interactive feedback
// ───────────────────────────────────────────────────────────
class PressScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final Duration duration;
  final HitTestBehavior behavior;

  const PressScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.duration = const Duration(milliseconds: 140),
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? widget.scale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Animated bar chart — bars grow from baseline
// ───────────────────────────────────────────────────────────
class AnimatedBarChart extends StatelessWidget {
  final List<double> values;
  final double maxHeight;
  final Duration delayStep;
  final Duration duration;
  final Color Function(int, bool) colorFor;

  const AnimatedBarChart({
    super.key,
    required this.values,
    required this.colorFor,
    this.maxHeight = 60,
    this.delayStep = const Duration(milliseconds: 30),
    this.duration = const Duration(milliseconds: 700),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: maxHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(values.length, (i) {
          final h = values[i];
          final isUp = i == 0 || values[i] >= values[i - 1];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: h),
                duration: duration,
                curve: Curves.easeOutBack,
                builder: (context, value, _) {
                  return Container(
                    height: value,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorFor(i, isUp),
                          colorFor(i, isUp).withValues(alpha: 0.55),
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3.5),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Gradient text helper
// ───────────────────────────────────────────────────────────
class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  const GradientText({
    super.key,
    required this.text,
    required this.gradient,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => gradient.createShader(rect),
      child: Text(text, style: style),
    );
  }
}
