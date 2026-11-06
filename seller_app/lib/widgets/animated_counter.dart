import 'package:flutter/material.dart';

/// Animates an integer or double count from 0 to a target value when it
/// becomes visible.  Used on the dashboard for KPI cards.
class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    required this.textBuilder,
    this.duration = const Duration(milliseconds: 1100),
    this.curve = Curves.easeOutCubic,
    this.delay = Duration.zero,
    this.refreshKey,
  });

  /// Numeric target.  Strings are not supported – format in [textBuilder].
  final num value;

  /// Called with the interpolated numeric value so you control the formatting.
  final String Function(num value) textBuilder;

  final Duration duration;
  final Curve curve;
  final Duration delay;
  final Object? refreshKey;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<num> _animation;
  num _displayed = 0;
  late num _target;

  @override
  void initState() {
    super.initState();
    _target = widget.value;
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _animation = Tween<num>(begin: 0, end: _target).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    )..addListener(() {
        setState(() => _displayed = _animation.value);
      });
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value || old.refreshKey != widget.refreshKey) {
      _target = widget.value;
      _animation = Tween<num>(
        begin: _displayed,
        end: _target,
      ).animate(
        CurvedAnimation(parent: _controller, curve: widget.curve),
      );
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      widget.textBuilder(_displayed),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}