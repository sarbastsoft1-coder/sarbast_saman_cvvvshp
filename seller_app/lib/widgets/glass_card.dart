import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Frosted glass card matching HTML `.card` (white ~72%, blur border, soft blue shadow).
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.gradient,
    this.onTap,
    this.borderRadius,
    this.boxShadow,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(24);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: padding,
          decoration: BoxDecoration(
            gradient: gradient,
            color: gradient == null
                ? (color ?? AppColors.paperSolid.withValues(alpha: 0.85))
                : null,
            borderRadius: radius,
            border: Border.all(
              color: borderColor ?? const Color(0xF2FFFFFF),
              width: 1,
            ),
            boxShadow: boxShadow ??
                const [
                  BoxShadow(
                    color: Color(0x1A1E64B4),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}
