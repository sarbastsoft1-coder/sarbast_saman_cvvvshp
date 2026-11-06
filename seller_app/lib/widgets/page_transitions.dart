import 'package:flutter/material.dart';

/// Reusable wrapper that fades + slides a child in from below.
/// Pass an [index] for a natural stagger when several items appear together.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 520),
    this.beginOffset = const Offset(0, 0.08),
    this.curve = Curves.easeOutCubic,
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset beginOffset;
  final Curve curve;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _opacity = CurvedAnimation(parent: _ctrl, curve: widget.curve);
    _offset = Tween<Offset>(begin: widget.beginOffset, end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: widget.curve));
    Future.delayed(widget.delay, () {
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
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// A simple staggered list builder – wraps each child in a FadeSlideIn whose
/// delay grows with the index.
class StaggeredList extends StatelessWidget {
  const StaggeredList({
    super.key,
    required this.children,
    this.spacing = 12,
    this.itemDelay = const Duration(milliseconds: 70),
    this.initialDelay = const Duration(milliseconds: 80),
    this.duration = const Duration(milliseconds: 480),
    this.axis = Axis.vertical,
    this.shrinkWrap = true,
    this.physics,
  });

  final List<Widget> children;
  final double spacing;
  final Duration itemDelay;
  final Duration initialDelay;
  final Duration duration;
  final Axis axis;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    if (axis == Axis.horizontal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: physics,
        child: Row(
          children: [
            for (int i = 0; i < children.length; i++) ...[
              FadeSlideIn(
                delay: initialDelay + itemDelay * i,
                duration: duration,
                child: children[i],
              ),
              if (i != children.length - 1) SizedBox(width: spacing),
            ],
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: shrinkWrap ? MainAxisSize.min : MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          FadeSlideIn(
            delay: initialDelay + itemDelay * i,
            duration: duration,
            child: children[i],
          ),
          if (i != children.length - 1) SizedBox(height: spacing),
        ],
      ],
    );
  }
}