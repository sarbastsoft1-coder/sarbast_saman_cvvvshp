import 'package:flutter/material.dart';

import 'boutique_colors.dart';

/// Design tokens for the Roni storefront.
///
/// Every screen should measure itself against this scale instead of inventing
/// its own spacing, radii, type sizes and durations. The goal is that the app
/// reads as one designed system rather than a collection of hand-tuned
/// screens: a 16px gutter here means a 16px gutter everywhere.
///
/// The numbers below are not arbitrary — they were derived from a census of
/// the existing code (≈340 `TextStyle` literals, ≈220 padding sites, ≈90
/// radius sites), collapsing 29 font sizes into 9, 14 radii into 7, and 37
/// durations into 9.
class BoutiqueTokens {
  BoutiqueTokens._();

  // ---------------------------------------------------------------- Spacing
  /// 4pt base grid. `xxs` (2) exists only for icon-level nudges.
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;
  static const double xxxl = 24;
  static const double huge = 32;
  static const double giant = 40;
  static const double massive = 48;

  /// Standard screen gutter — every full-width page uses this.
  static const double gutter = xl;

  /// Standard card interior padding.
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);

  /// Standard page padding for scroll views.
  static const EdgeInsets pagePadding = EdgeInsets.symmetric(
    horizontal: gutter,
  );

  /// Vertical rhythm between stacked sections on a page.
  static const double sectionGap = xxl;

  // ----------------------------------------------------------------- Radius
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusXxl = 32;
  static const double radiusPill = 999;

  // ------------------------------------------------------------- Hit targets
  /// Minimum interactive size (WCAG 2.5.8 / Material minimum is 48, but 44
  /// is the practical floor for dense commerce rows).
  static const double tapTarget = 44;

  /// Compact icon button inside a card — still comfortably tappable.
  static const double tapTargetCompact = 40;

  // ------------------------------------------------------------ Typography
  static const String fontFamily = 'Vazirmatn';

  /// Editorial display size for hero and empty-state headlines.
  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.2,
  );

  /// Screen titles.
  static const TextStyle title1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.3,
    height: 1.25,
  );

  /// Section and card titles.
  static const TextStyle title2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.3,
  );

  /// Sub-section titles, product names on cards.
  static const TextStyle title3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.35,
  );

  /// Emphasised body copy, list rows.
  static const TextStyle title4 = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  /// Default reading size.
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.55,
  );

  /// Secondary body copy.
  static const TextStyle bodySmall = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Labels, chips, buttons.
  static const TextStyle label = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.35,
  );

  /// Small metadata under an item.
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  /// All-caps section eyebrow.
  static const TextStyle overline = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    height: 1.3,
  );

  /// Micro label — badges, chips.
  static const TextStyle micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  /// Price on cards and rows.
  static const TextStyle price = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  /// Price on the product detail screen.
  static const TextStyle priceLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
    height: 1.15,
  );

  /// Struck-through original price.
  static const TextStyle priceStrike = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.3,
    decoration: TextDecoration.lineThrough,
  );

  // ------------------------------------------------------------------ Motion
  /// Press feedback.
  static const Duration instant = Duration(milliseconds: 120);

  /// Small state changes (colour, icon swaps).
  static const Duration fast = Duration(milliseconds: 160);

  /// Default transition — chips, cards, sheets.
  static const Duration base = Duration(milliseconds: 200);

  /// Emphasised segment movement.
  static const Duration emphasized = Duration(milliseconds: 240);

  /// Larger surfaces — bottom sheets.
  static const Duration sheet = Duration(milliseconds: 320);

  /// Route transitions.
  static const Duration route = Duration(milliseconds: 340);

  /// Entrance animations.
  static const Duration entrance = Duration(milliseconds: 420);

  /// Ambient pulse.
  static const Duration pulse = Duration(milliseconds: 600);

  /// Loading shimmer.
  static const Duration shimmer = Duration(milliseconds: 1100);

  static const Curve curveStandard = Curves.easeOutCubic;
  static const Curve curveEmphasized = Curves.easeOutBack;
  static const Curve curveExit = Curves.easeInCubic;
  static const Curve curveAmbient = Curves.easeInOut;

  /// Standard press scale for tappable surfaces.
  static const double pressScale = 0.97;

  /// Stagger step used when a list of sections fades in.
  static const Duration stagger = Duration(milliseconds: 40);

  // -------------------------------------------------------------- Elevation
  /// Resting card. Hairline border, no shadow.
  static List<BoxShadow> get shadowNone => const [];

  /// Cards that lift on hover (desktop / web).
  static List<BoxShadow> shadowCard(RoniPalette p) => [
    BoxShadow(
      color: p.fg.withValues(alpha: 0.06),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  /// Floating elements — add-to-cart buttons, sticky bars.
  static List<BoxShadow> shadowRaised(RoniPalette p) => [
    BoxShadow(
      color: p.fg.withValues(alpha: 0.14),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: p.fg.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  /// Sheets and dialogs.
  static List<BoxShadow> shadowOverlay(RoniPalette p) => [
    BoxShadow(
      color: p.fg.withValues(alpha: 0.18),
      blurRadius: 36,
      offset: const Offset(0, 14),
    ),
  ];

  /// Scrim behind modal surfaces.
  static Color scrim(RoniPalette p) => p.fg.withValues(alpha: 0.55);

  // --------------------------------------------------------------- Layout
  /// Maximum content width. The app is capped so it stays readable on wide
  /// screens instead of stretching product cards into letterboxes.
  static const double maxContentWidth = 520;

  /// Number of product columns on a phone-sized grid.
  static const int gridColumns = 2;

  /// Product grid gutters.
  static const double gridGap = xl;
}
