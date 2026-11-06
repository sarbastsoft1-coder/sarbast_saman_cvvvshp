import 'package:flutter/material.dart';

class Responsive {
  static const double mobileMax = 600;
  static const double tabletMax = 1000;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= mobileMax &&
      MediaQuery.sizeOf(context).width < tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletMax;

  /// Get the appropriate cross axis count for product grids based on screen width
  static int getGridCrossAxisCount(BuildContext context) {
    double width = MediaQuery.sizeOf(context).width;
    if (width < 400) return 2;
    if (width < 600) return 2;
    if (width < 800) return 3;
    if (width < 1000) return 4;
    if (width < 1200) return 5;
    return 6;
  }
}
