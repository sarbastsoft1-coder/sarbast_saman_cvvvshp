import 'package:flutter/material.dart';

import '../core/theme/boutique_colors.dart';

/// Floating "زیادی بکە بۆ جانتاکەم" button.
///
/// The button softly pulses to attract attention. After tapping it morphs into
/// a soft green checkmark state for ~1.4s before smoothly reverting to the
/// default dusty pink.
class AnimatedAddButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String label;
  final double height;
  final double radius;
  final IconData icon;

  const AnimatedAddButton({
    super.key,
    required this.onPressed,
    this.label = 'زیادی بکە بۆ جانتاکەم',
    this.height = 56,
    this.radius = 30,
    this.icon = Icons.shopping_bag_rounded,
  });

  @override
  State<AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<AnimatedAddButton>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _successController;
  late final Animation<double> _pulse;
  bool _success = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _pulse = Tween<double>(begin: 1.0, end: 1.045).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_success) return;
    widget.onPressed();
    setState(() => _success = true);
    await _successController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    if (!mounted) return;
    await _successController.reverse();
    if (!mounted) return;
    setState(() => _success = false);
  }

  @override
  Widget build(BuildContext context) {
    final color = _success
        ? BoutiqueColors.successGreen
        : BoutiqueColors.dustyPink;
    return ScaleTransition(
      scale: _pulse,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        height: widget.height,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(widget.radius),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.45),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(widget.radius),
            onTap: _handleTap,
            splashColor: Colors.white.withValues(alpha: 0.18),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(
                      begin: 0.92,
                      end: 1.0,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: Row(
                  key: ValueKey(_success),
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _success ? Icons.check_circle_rounded : widget.icon,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _success ? 'زیادکرا ✓' : widget.label,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
