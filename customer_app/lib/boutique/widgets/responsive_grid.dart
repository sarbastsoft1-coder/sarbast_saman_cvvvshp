import 'package:flutter/rendering.dart';

/// Uses the space actually available to a grid, including tablet split view
/// and the desktop navigation rail, rather than the device's screen width.
class ResponsiveProductGrid extends SliverGridDelegate {
  const ResponsiveProductGrid({this.textScale = 1});
  final double textScale;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final width = constraints.crossAxisExtent;
    final columns = width < 280 ? 1 : (width / 180).floor().clamp(2, 6);
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisExtent: 318 + 80 * (textScale - 1).clamp(0, 1),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
    ).getLayout(constraints);
  }

  @override
  bool shouldRelayout(ResponsiveProductGrid oldDelegate) =>
      textScale != oldDelegate.textScale;
}
