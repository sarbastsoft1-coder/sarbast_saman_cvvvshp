import 'dart:ui';
import 'package:flutter/material.dart';

import '../core/theme/boutique_colors.dart';

/// A reusable glassmorphism container with backdrop blur, soft border, and
/// translucent fill. Used for the bottom navigation, overlay cards, and
/// floating actions.
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final Color color;
  final double blur;
  final Color borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  const GlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.color = BoutiqueColors.glassLight,
    this.blur = 18,
    this.borderColor = const Color(0x33FFFFFF),
    this.borderWidth = 1,
    this.shadows,
    this.padding = EdgeInsets.zero,
    this.width,
    this.height,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: blur > 0
            ? ImageFilter.blur(sigmaX: blur, sigmaY: blur)
            : ImageFilter.blur(sigmaX: 0, sigmaY: 0),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          alignment: alignment,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
          child: child,
        ),
      ),
    );

    if (shadows != null && shadows!.isNotEmpty) {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
        ),
        child: content,
      );
    }

    return content;
  }
}
