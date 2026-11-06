import 'dart:async';

import 'package:flutter/material.dart';

/// Light entrance motion used on home and list sections.
class RoniFadeSlide extends StatefulWidget {
  const RoniFadeSlide({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 420),
    this.offset = const Offset(0, 0.04),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<RoniFadeSlide> createState() => _RoniFadeSlideState();
}

class _RoniFadeSlideState extends State<RoniFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: widget.offset,
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      Future<void>.delayed(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _fade,
    child: SlideTransition(position: _slide, child: widget.child),
  );
}

/// Shrinks its child slightly while pressed, like the HTML `button:active`.
class RoniPressable extends StatefulWidget {
  const RoniPressable({super.key, required this.child, this.scale = .96});

  final Widget child;
  final double scale;

  @override
  State<RoniPressable> createState() => _RoniPressableState();
}

class _RoniPressableState extends State<RoniPressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: (_) => _set(true),
    onPointerUp: (_) => _set(false),
    onPointerCancel: (_) => _set(false),
    child: AnimatedScale(
      scale: _down ? widget.scale : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: widget.child,
    ),
  );
}

/// Heartbeat pulse for live dots and attention icons.
/// Respects the system reduce-motion setting.
class RoniPulse extends StatefulWidget {
  const RoniPulse({
    super.key,
    required this.child,
    this.minScale = .85,
    this.period = const Duration(milliseconds: 1800),
  });

  final Widget child;
  final double minScale;
  final Duration period;

  @override
  State<RoniPulse> createState() => _RoniPulseState();
}

class _RoniPulseState extends State<RoniPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: widget.minScale), weight: 50),
    TweenSequenceItem(tween: Tween(begin: widget.minScale, end: 1), weight: 50),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  Timer? _beat;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _beat?.cancel();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _beat = Timer.periodic(widget.period, (_) {
      if (mounted) _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _beat?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// Pops its child (scale up, then settle) whenever [trigger] changes.
/// Matches HTML `pop` / `bump` keyframes for hearts and the cart badge.
class RoniBump extends StatefulWidget {
  const RoniBump({
    super.key,
    required this.trigger,
    required this.child,
    this.peak = 1.35,
  });

  final Object? trigger;
  final Widget child;
  final double peak;

  @override
  State<RoniBump> createState() => _RoniBumpState();
}

class _RoniBumpState extends State<RoniBump>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1, end: widget.peak), weight: 40),
    TweenSequenceItem(tween: Tween(begin: widget.peak, end: 1), weight: 60),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(RoniBump oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.trigger != widget.trigger) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      ScaleTransition(scale: _scale, child: widget.child);
}

/// HTML `rxglow` - soft gold pulse around the Ronix coin (3.2s loop).
class RoniGlow extends StatefulWidget {
  const RoniGlow({
    super.key,
    required this.child,
    this.color = const Color(0xFFE6C36A),
    this.period = const Duration(milliseconds: 3200),
  });

  final Widget child;
  final Color color;
  final Duration period;

  @override
  State<RoniGlow> createState() => _RoniGlowState();
}

class _RoniGlowState extends State<RoniGlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: widget.period,
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _c,
    curve: Curves.easeInOut,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, child) {
      final g = _t.value;
      return DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: .15 + g * .45),
              blurRadius: 4 + g * 10,
              spreadRadius: g * 1.5,
            ),
          ],
        ),
        child: child,
      );
    },
    child: widget.child,
  );
}

/// HTML `.skel` shimmer for loading placeholders.
class RoniShimmer extends StatefulWidget {
  const RoniShimmer({
    super.key,
    required this.child,
    this.base,
    this.highlight,
  });

  final Widget child;
  final Color? base;
  final Color? highlight;

  @override
  State<RoniShimmer> createState() => _RoniShimmerState();
}

class _RoniShimmerState extends State<RoniShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
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
    final p = Theme.of(context);
    final soft = widget.base ?? p.colorScheme.surfaceContainerHighest;
    final line = widget.highlight ?? p.colorScheme.surface;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => LinearGradient(
          begin: Alignment(-1.0 - _c.value * 2, 0),
          end: Alignment(1.0 - _c.value * 2, 0),
          colors: [soft, line, soft],
          stops: const [0.25, 0.5, 0.75],
        ).createShader(bounds),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// HTML `#toast` - pill above the nav, slides up then fades out.
void showRoniToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(milliseconds: 2200),
  String? actionLabel,
  VoidCallback? onAction,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        48,
        0,
        48,
        88 + MediaQuery.paddingOf(context).bottom,
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.surface,
        ),
      ),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: const Color(0xFFE8C56A),
              onPressed: onAction,
            )
          : null,
    ),
  );
}

/// HTML `.skel` product-card placeholder (image + two lines).
class RoniProductSkeleton extends StatelessWidget {
  const RoniProductSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final soft = Theme.of(context).colorScheme.surfaceContainerHighest;
    Widget bar({required double height, double? width}) => RoniShimmer(
      child: Container(
        height: height,
        width: width ?? double.infinity,
        decoration: BoxDecoration(
          color: soft,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: RoniShimmer(child: ColoredBox(color: soft)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  bar(height: 12),
                  const SizedBox(height: 8),
                  bar(height: 12, width: 72),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Soft fade + rise used for every pushed boutique route.
class RoniPageRoute<T> extends PageRouteBuilder<T> {
  RoniPageRoute({
    required WidgetBuilder builder,
    super.settings,
    Duration duration = const Duration(milliseconds: 340),
  }) : super(
         transitionDuration: duration,
         reverseTransitionDuration: const Duration(milliseconds: 260),
         pageBuilder: (context, animation, secondaryAnimation) =>
             builder(context),
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
           if (reduce) return child;
           final curved = CurvedAnimation(
             parent: animation,
             curve: Curves.easeOutCubic,
             reverseCurve: Curves.easeInCubic,
           );
           return FadeTransition(
             opacity: curved,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: const Offset(0, 0.035),
                 end: Offset.zero,
               ).animate(curved),
               child: child,
             ),
           );
         },
       );
}

/// Theme-wide page transitions matching [RoniPageRoute].
class RoniPageTransitionsBuilder extends PageTransitionsBuilder {
  const RoniPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.03),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Bottom sheet with HTML-like `up` + scrim fade.
Future<T?> showRoniSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  Color? barrierColor,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? Colors.black.withValues(alpha: .5),
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      reverseDuration: Duration(milliseconds: 240),
      reverseCurve: Curves.easeInCubic,
    ),
    builder: builder,
  );
}

/// HTML `.card:hover` lift - used on product tiles (desktop / web).
class RoniHoverLift extends StatefulWidget {
  const RoniHoverLift({super.key, required this.child, this.lift = -3});

  final Widget child;
  final double lift;

  @override
  State<RoniHoverLift> createState() => _RoniHoverLiftState();
}

class _RoniHoverLiftState extends State<RoniHoverLift> {
  bool _over = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => _over = true),
    onExit: (_) => setState(() => _over = false),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      transform: Matrix4.translationValues(0, _over ? widget.lift : 0, 0),
      transformAlignment: Alignment.center,
      decoration: BoxDecoration(
        boxShadow: _over
            ? [
                BoxShadow(
                  color: const Color(0xFF0F1B33).withValues(alpha: .10),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: widget.child,
    ),
  );
}
