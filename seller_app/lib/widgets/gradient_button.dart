import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Primary CTA — HTML `.btn.red` is actually black `#0A0A0A` with pill radius.
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.gradient,
    this.width,
    this.height = 48,
    this.solidColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Gradient? gradient;
  final Color? solidColor;
  final double? width;
  final double height;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressCtrl;
  late final Animation<double> _pressAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 0.04,
    );
    _pressAnim = CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _setPressed(bool pressed) {
    if (pressed) {
      _pressCtrl.forward();
    } else {
      _pressCtrl.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.isLoading;
    final fill = widget.solidColor ?? AppColors.forest;
    final useGradient = widget.gradient != null;

    return AnimatedBuilder(
      animation: _pressAnim,
      builder: (context, _) {
        return Transform.translate(
          offset: Offset(0, _pressAnim.value * 4),
          child: Opacity(
            opacity: disabled ? 0.55 : 1.0,
            child: InkWell(
              borderRadius: BorderRadius.circular(1000),
              onTap: disabled
                  ? null
                  : () {
                      _setPressed(true);
                      Future.delayed(const Duration(milliseconds: 100),
                          () => _setPressed(false));
                      widget.onPressed?.call();
                    },
              onHighlightChanged: (v) => _setPressed(v),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: useGradient ? null : fill,
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(1000),
                  boxShadow: disabled
                      ? null
                      : [
                          BoxShadow(
                            color: (useGradient
                                    ? AppColors.terracotta
                                    : fill)
                                .withValues(alpha: 0.28),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.icon != null) ...[
                              Icon(widget.icon, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              widget.label,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
