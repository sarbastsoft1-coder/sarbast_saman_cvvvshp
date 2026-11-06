import 'package:flutter/material.dart';

/// Roni visual language — ink & gold customer prototype (Roni Shop artifact).
///
/// Constant names predate this palette (terracotta / red eras) but are kept
/// so existing call sites compile and repaint in the new brand colours.
class BoutiqueColors {
  BoutiqueColors._();

  // ---------------------------------------------------------------- Surfaces
  /// Page / phone chrome background — HTML `--bg`.
  static const Color beige = Color(0xFFF6F4EF);
  /// Legacy name = primary accent. Now HTML `--brand2` deep gold.
  static const Color dustyPink = Color(0xFF8A6416);
  /// Soft primary wash (`--soft`).
  static const Color softPink = Color(0xFFF1EADB);
  static const Color cream = Color(0xFFF6F4EF);
  static const Color white = Color(0xFFFFFFFF);
  /// Nested surfaces (`--soft` on white cards).
  static const Color surface = Color(0xFFF6F4EF);

  // ------------------------------------------------------------------- Text
  static const Color charcoal = Color(0xFF17130D);
  static const Color softCharcoal = Color(0xFF3A3326);
  static const Color muted = Color(0xFF6B6457);

  // ---------------------------------------------------------------- Accents
  static const Color successGreen = Color(0xFF06724D);
  static const Color successGreenSoft = Color(0xFF8FD9BC);
  /// Rating stars (`--gold`). Darkened from `#F59E0B` so it clears 3:1 on the
  /// light card surface — the old value scored 2.15:1.
  static const Color gold = Color(0xFFB07407);
  /// Sale price, discount badge, favourite heart (`--sale`).
  static const Color rose = Color(0xFFC22136);
  static const Color saleWash = Color(0xFFFDE8EB);
  /// Logo chevron + header tab underline (`--chev`).
  static const Color logoMark = Color(0xFFE6C36A);

  // ----------------------------------------------------------------- Header
  /// Dark header band gradient (`--hdr1` → `--hdr2`).
  static const Color header1 = Color(0xFF17130D);
  static const Color header2 = Color(0xFF3A2D15);
  static const LinearGradient headerGradient = LinearGradient(
    colors: [header1, header2],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // ------------------------------------------------------------ Roni brand
  static const Color goldDeep = Color(0xFF8A6416);
  static const Color goldBright = Color(0xFFE8C873);
  static const Color goldWash = Color(0xFFFBF3E2);
  static const Color ink = Color(0xFF17130D);
  static const Color logo = Color(0xFF17130D);
  static const Color primaryInk = Color(0xFF6E4F10);
  static const Color card = Color(0xFFFFFFFF);
  /// Text on gold CTAs (`.buy` / `.btn`).
  static const Color onGold = Color(0xFF1F1606);

  static const Color redDark = Color(0xFF6E4F10);
  static const Color redWash = Color(0xFFFBF8F1);
  static const Color line = Color(0xFFE6DFD0);
  static const Color line2 = Color(0xFFD6CDB9);
  /// Secondary metadata text. Darkened from `#948B79` (3.37:1) to clear 4.5:1.
  static const Color muted2 = Color(0xFF7A7263);

  /// Primary CTA fill — gold gradient (HTML `.buy` / `.btn`).
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFB8862B), Color(0xFFE8C873)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  /// Soft gold wash for chips / selected chrome.
  static const LinearGradient goldWashGradient = LinearGradient(
    colors: [Color(0xFFFBF8F1), Color(0xFFF1EADB)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  // ----------------------------------------------------------- Status colors
  // Foregrounds are dark enough to clear 4.5:1 against their own wash.
  static const Color statusShipped = Color(0xFF1B4FA8);
  static const Color statusShippedWash = Color(0xFFE9F0FC);
  static const Color statusCancelled = Color(0xFFB01B2E);
  static const Color statusCancelledWash = Color(0xFFFDECEC);
  static const Color statusDelivered = Color(0xFF06724D);
  static const Color statusDeliveredWash = Color(0xFFE3F5EE);
  static const Color statusProcessing = Color(0xFF9A5B00);
  static const Color statusProcessingWash = Color(0xFFFFF1E0);

  // -------------------------------------------------------- Borders/dividers
  static const Color border = Color(0xFFE6DFD0);
  static const Color divider = Color(0xFFE6DFD0);

  static const Color glassLight = Color(0xCCFFFFFF);
  static const Color glassLightThin = Color(0x99FFFFFF);
  static const Color glassDark = Color(0x66000000);
  static const Color glassPink = Color(0xE6F1EADB);
  static const Color glassBeige = Color(0xE6F6F4EF);

  // ---------------------------------------------------------------- Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF17130D).withValues(alpha: 0.06),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get floatingShadow => [
    BoxShadow(
      color: const Color(0xFF17130D).withValues(alpha: 0.14),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get barShadow => [
    BoxShadow(
      color: const Color(0xFF17130D).withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, -4),
    ),
  ];

  // ------------------------------------------------------------- Dark tokens
  /// Premium dark gold surfaces (screenshot / HTML dark).
  static const Color darkBg = Color(0xFF0B0907);
  static const Color darkSurface = Color(0xFF17140F);
  static const Color darkSoft = Color(0xFF262018);
  static const Color darkFg = Color(0xFFF6F1E8);
  static const Color darkMuted = Color(0xFFB0A690);
  static const Color darkLine = Color(0xFF3D3526);
  static const Color darkBrand2 = Color(0xFFE8C56A);
  static const Color darkSale = Color(0xFFFF6B81);
  static const Color darkSaleSoft = Color(0xFF3D1A24);
  static const Color darkGold = Color(0xFFF5C84A);
  static const Color darkOk = Color(0xFF3DDBA8);

  /// Dark status tones — readable on the dark surface.
  static const Color darkStatusShipped = Color(0xFF8FB6FF);
  static const Color darkStatusShippedWash = Color(0xFF16233A);
  static const Color darkStatusCancelled = Color(0xFFFF8A99);
  static const Color darkStatusCancelledWash = Color(0xFF3A1A21);
  static const Color darkStatusDelivered = Color(0xFF5FD6AE);
  static const Color darkStatusDeliveredWash = Color(0xFF123026);
  static const Color darkStatusProcessing = Color(0xFFF2B45C);
  static const Color darkStatusProcessingWash = Color(0xFF3A2A11);

  /// Metallic gold gradient for CTAs / coins (dark + light).
  static const LinearGradient metalGoldGradient = LinearGradient(
    colors: [Color(0xFF9A6B1A), Color(0xFFE8C56A), Color(0xFFF3D789)],
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
  );

  static const LinearGradient darkBannerGold = LinearGradient(
    colors: [Color(0xFF1A140A), Color(0xFF5A4018), Color(0xFF8A6416)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );
}

/// Semantic Roni palette resolved from [ThemeData] (light or dark).
///
/// The app boots in dark mode, so anything that paints a raw light literal
/// instead of reading this palette will look broken on first launch. This
/// class is the single source of truth for surface, text, accent and status
/// colour in both brightnesses.
@immutable
class RoniPalette extends ThemeExtension<RoniPalette> {
  const RoniPalette({
    required this.bg,
    required this.surface,
    required this.soft,
    required this.fg,
    required this.muted,
    required this.line,
    required this.brand2,
    required this.sale,
    required this.saleSoft,
    required this.gold,
    required this.ok,
    required this.chev,
    required this.card,
    required this.onGold,
    this.surfaceRaised = BoutiqueColors.white,
    this.surfaceSunken = BoutiqueColors.beige,
    this.onSurfaceVariant = BoutiqueColors.muted2,
    this.borderStrong = BoutiqueColors.line2,
    this.statusProcessing = BoutiqueColors.statusProcessing,
    this.statusProcessingWash = BoutiqueColors.statusProcessingWash,
    this.statusShipped = BoutiqueColors.statusShipped,
    this.statusShippedWash = BoutiqueColors.statusShippedWash,
    this.statusDelivered = BoutiqueColors.statusDelivered,
    this.statusDeliveredWash = BoutiqueColors.statusDeliveredWash,
    this.statusCancelled = BoutiqueColors.statusCancelled,
    this.statusCancelledWash = BoutiqueColors.statusCancelledWash,
  });

  final Color bg;
  final Color surface;
  final Color soft;
  final Color fg;
  final Color muted;
  final Color line;
  final Color brand2;
  final Color sale;
  final Color saleSoft;
  final Color gold;
  final Color ok;
  final Color chev;
  final Color card;
  final Color onGold;

  /// A surface lifted above [card] — sheets, floating panels.
  final Color surfaceRaised;

  /// A surface recessed below [bg] — wells, track backgrounds.
  final Color surfaceSunken;

  /// Tertiary text: timestamps, hints, disabled-but-readable labels.
  final Color onSurfaceVariant;

  /// A divider strong enough to read as an edge (3:1 against the surface).
  final Color borderStrong;

  final Color statusProcessing;
  final Color statusProcessingWash;
  final Color statusShipped;
  final Color statusShippedWash;
  final Color statusDelivered;
  final Color statusDeliveredWash;
  final Color statusCancelled;
  final Color statusCancelledWash;

  static const light = RoniPalette(
    bg: BoutiqueColors.beige,
    surface: BoutiqueColors.white,
    soft: BoutiqueColors.softPink,
    fg: BoutiqueColors.charcoal,
    muted: BoutiqueColors.muted,
    line: BoutiqueColors.line,
    brand2: BoutiqueColors.dustyPink,
    sale: BoutiqueColors.rose,
    saleSoft: BoutiqueColors.saleWash,
    gold: BoutiqueColors.gold,
    ok: BoutiqueColors.successGreen,
    chev: BoutiqueColors.logoMark,
    card: BoutiqueColors.card,
    onGold: BoutiqueColors.onGold,
    surfaceRaised: BoutiqueColors.white,
    surfaceSunken: BoutiqueColors.beige,
    onSurfaceVariant: BoutiqueColors.muted2,
    borderStrong: BoutiqueColors.line2,
  );

  static const dark = RoniPalette(
    bg: BoutiqueColors.darkBg,
    surface: BoutiqueColors.darkSurface,
    soft: BoutiqueColors.darkSoft,
    fg: BoutiqueColors.darkFg,
    muted: BoutiqueColors.darkMuted,
    line: BoutiqueColors.darkLine,
    brand2: BoutiqueColors.darkBrand2,
    sale: BoutiqueColors.darkSale,
    saleSoft: BoutiqueColors.darkSaleSoft,
    gold: BoutiqueColors.darkGold,
    ok: BoutiqueColors.darkOk,
    chev: BoutiqueColors.logoMark,
    card: BoutiqueColors.darkSurface,
    onGold: Color(0xFF1F1606),
    surfaceRaised: BoutiqueColors.darkSoft,
    surfaceSunken: Color(0xFF0F0D0A),
    onSurfaceVariant: Color(0xFF8E8776),
    borderStrong: Color(0xFF4C4433),
    statusProcessing: BoutiqueColors.darkStatusProcessing,
    statusProcessingWash: BoutiqueColors.darkStatusProcessingWash,
    statusShipped: BoutiqueColors.darkStatusShipped,
    statusShippedWash: BoutiqueColors.darkStatusShippedWash,
    statusDelivered: BoutiqueColors.darkStatusDelivered,
    statusDeliveredWash: BoutiqueColors.darkStatusDeliveredWash,
    statusCancelled: BoutiqueColors.darkStatusCancelled,
    statusCancelledWash: BoutiqueColors.darkStatusCancelledWash,
  );

  static RoniPalette of(BuildContext context) =>
      Theme.of(context).extension<RoniPalette>() ?? light;

  /// Dark mode is the app's default; callers that need a mode-agnostic
  /// surface should use this rather than hard-coding white or black.
  bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  @override
  RoniPalette copyWith({
    Color? bg,
    Color? surface,
    Color? soft,
    Color? fg,
    Color? muted,
    Color? line,
    Color? brand2,
    Color? sale,
    Color? saleSoft,
    Color? gold,
    Color? ok,
    Color? chev,
    Color? card,
    Color? onGold,
    Color? surfaceRaised,
    Color? surfaceSunken,
    Color? onSurfaceVariant,
    Color? borderStrong,
    Color? statusProcessing,
    Color? statusProcessingWash,
    Color? statusShipped,
    Color? statusShippedWash,
    Color? statusDelivered,
    Color? statusDeliveredWash,
    Color? statusCancelled,
    Color? statusCancelledWash,
  }) => RoniPalette(
    bg: bg ?? this.bg,
    surface: surface ?? this.surface,
    soft: soft ?? this.soft,
    fg: fg ?? this.fg,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    brand2: brand2 ?? this.brand2,
    sale: sale ?? this.sale,
    saleSoft: saleSoft ?? this.saleSoft,
    gold: gold ?? this.gold,
    ok: ok ?? this.ok,
    chev: chev ?? this.chev,
    card: card ?? this.card,
    onGold: onGold ?? this.onGold,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    surfaceSunken: surfaceSunken ?? this.surfaceSunken,
    onSurfaceVariant: onSurfaceVariant ?? this.onSurfaceVariant,
    borderStrong: borderStrong ?? this.borderStrong,
    statusProcessing: statusProcessing ?? this.statusProcessing,
    statusProcessingWash:
        statusProcessingWash ?? this.statusProcessingWash,
    statusShipped: statusShipped ?? this.statusShipped,
    statusShippedWash: statusShippedWash ?? this.statusShippedWash,
    statusDelivered: statusDelivered ?? this.statusDelivered,
    statusDeliveredWash: statusDeliveredWash ?? this.statusDeliveredWash,
    statusCancelled: statusCancelled ?? this.statusCancelled,
    statusCancelledWash: statusCancelledWash ?? this.statusCancelledWash,
  );

  @override
  RoniPalette lerp(ThemeExtension<RoniPalette>? other, double t) {
    if (other is! RoniPalette) return this;
    return RoniPalette(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      soft: Color.lerp(soft, other.soft, t)!,
      fg: Color.lerp(fg, other.fg, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      brand2: Color.lerp(brand2, other.brand2, t)!,
      sale: Color.lerp(sale, other.sale, t)!,
      saleSoft: Color.lerp(saleSoft, other.saleSoft, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      chev: Color.lerp(chev, other.chev, t)!,
      card: Color.lerp(card, other.card, t)!,
      onGold: Color.lerp(onGold, other.onGold, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      surfaceSunken: Color.lerp(surfaceSunken, other.surfaceSunken, t)!,
      onSurfaceVariant:
          Color.lerp(onSurfaceVariant, other.onSurfaceVariant, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      statusProcessing:
          Color.lerp(statusProcessing, other.statusProcessing, t)!,
      statusProcessingWash:
          Color.lerp(statusProcessingWash, other.statusProcessingWash, t)!,
      statusShipped: Color.lerp(statusShipped, other.statusShipped, t)!,
      statusShippedWash:
          Color.lerp(statusShippedWash, other.statusShippedWash, t)!,
      statusDelivered: Color.lerp(statusDelivered, other.statusDelivered, t)!,
      statusDeliveredWash:
          Color.lerp(statusDeliveredWash, other.statusDeliveredWash, t)!,
      statusCancelled:
          Color.lerp(statusCancelled, other.statusCancelled, t)!,
      statusCancelledWash:
          Color.lerp(statusCancelledWash, other.statusCancelledWash, t)!,
    );
  }
}
