import 'package:flutter/material.dart';

/// EarthShop Design System — Rich Earthy Aesthetic
/// Three signature moods:
///   • Daylight — Warm Sand + Sage (default)
///   • Twilight — Forest + Ochre (accents)
///   • Midnight — Deep Forest (splash & hero gradients)
class EarthTheme {
  // ─── Primary Palette ───
  static const Color terracotta = Color(0xFFC86D51);
  static const Color terracottaDark = Color(0xFFA65239);
  static const Color terracottaLight = Color(0xFFE89679);
  static const Color terracottaSoft = Color(0x1FC86D51);
  static const Color terracottaFaint = Color(0x0FC86D51);

  static const Color forestGreen = Color(0xFF233D34);
  static const Color forestGreenDark = Color(0xFF152721);
  static const Color forestGreenMid = Color(0xFF1A3229);
  static const Color forestGreenSoft = Color(0x14233D34);

  static const Color sageGreen = Color(0xFF748E7B);
  static const Color sageLight = Color(0xFFE3ECE5);
  static const Color sageSoft = Color(0x26748E7B);
  static const Color mint = Color(0xFFB8D4C2);
  static const Color mintFaint = Color(0xFFEDF4EF);

  static const Color clayOchre = Color(0xFFD29054);
  static const Color ochreLight = Color(0xFFF7EBDD);
  static const Color ochreDeep = Color(0xFFB6743D);
  static const Color goldenGlow = Color(0xFFF5C16C);

  static const Color coral = Color(0xFFE07A5F);
  static const Color sky = Color(0xFFA8C5D6);

  // ─── Neutrals ───
  static const Color warmSand = Color(0xFFF9F7F2);
  static const Color warmSandLight = Color(0xFFFBFAF6);
  static const Color linen = Color(0xFFEFECE4);
  static const Color linenLight = Color(0xFFF5F2EA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color charcoal = Color(0xFF1F2421);
  static const Color graphite = Color(0xFF2D3530);
  static const Color slate = Color(0xFF4A5550);
  static const Color muted = Color(0xFF6E756F);
  static const Color mutedSoft = Color(0xFF9AA09B);
  static const Color border = Color(0xFFE2DDD3);
  static const Color borderLight = Color(0xFFECE7DE);
  static const Color borderFaint = Color(0xFFF3EFE7);

  // ─── Status ───
  static const Color success = Color(0xFF3B7A57);
  static const Color successLight = Color(0xFF7BB892);
  static const Color successBg = Color(0xFFEAF4EE);
  static const Color warning = Color(0xFFD9822B);
  static const Color warningBg = Color(0xFFFDF3E7);
  static const Color danger = Color(0xFFE07A5F);
  static const Color dangerBg = Color(0xFFFBEAE6);

  // ─── Radii ───
  static const double radiusXs = 6;
  static const double radiusSm = 10;
  static const double radiusMd = 16;
  static const double radiusLg = 24;
  static const double radiusXl = 32;
  static const double radiusPill = 999;

  // ─── Spacing scale ───
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double space32 = 32;
  static const double space48 = 48;

  // ─── Animation constants ───
  static const Duration durFast = Duration(milliseconds: 180);
  static const Duration dur = Duration(milliseconds: 320);
  static const Duration durSlow = Duration(milliseconds: 520);
  static const Duration durXL = Duration(milliseconds: 900);
  static const Curve curveOut = Curves.easeOutCubic;
  static const Curve curveInOut = Curves.easeInOutCubic;
  static const Curve curveSpring = Cubic(0.34, 1.56, 0.64, 1);

  // ─── Shadows ───
  static List<BoxShadow> get subtleShadow => [
        BoxShadow(
          color: forestGreen.withValues(alpha: 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: forestGreen.withValues(alpha: 0.06),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: forestGreen.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get terracottaGlow => [
        BoxShadow(
          color: terracotta.withValues(alpha: 0.32),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: terracotta.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get forestGlow => [
        BoxShadow(
          color: forestGreen.withValues(alpha: 0.28),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get ochreGlow => [
        BoxShadow(
          color: clayOchre.withValues(alpha: 0.30),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  // ─── Gradients ───
  static const LinearGradient heroGradient = LinearGradient(
    colors: [forestGreen, Color(0xFF1A3229)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [forestGreen, Color(0xFF1A3229), Color(0xFF0F201B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sunsetGradient = LinearGradient(
    colors: [terracotta, clayOchre, goldenGlow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient forestGradient = LinearGradient(
    colors: [sageGreen, forestGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFFB8D4C2), Color(0xFFE3ECE5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient skyGradient = LinearGradient(
    colors: [Color(0xFFD6E4EE), Color(0xFFF7F2E6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardHighlight = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x14FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pageOverlay = LinearGradient(
    colors: [Color(0x00FFFFFF), Color(0x60F9F7F2)],
    begin: Alignment.center,
    end: Alignment.bottomCenter,
  );

  // ─── Category Backgrounds ───
  static Color categoryBg(String cat) {
    switch (cat) {
      case 'ceramics':
        return const Color(0xFFF5E6DE);
      case 'food':
        return const Color(0xFFFDF3E7);
      case 'textiles':
        return const Color(0xFFE3ECE5);
      case 'tea':
        return const Color(0xFFE8EFE3);
      case 'wood':
        return const Color(0xFFF0E8DC);
      case 'soaps':
        return const Color(0xFFEBF2F7);
      case 'candles':
        return const Color(0xFFFDF8ED);
      default:
        return linenLight;
    }
  }

  // ─── Category Foregrounds (subtle accents) ───
  static Color categoryFg(String cat) {
    switch (cat) {
      case 'ceramics':
        return terracotta;
      case 'food':
        return clayOchre;
      case 'textiles':
        return sageGreen;
      case 'tea':
        return success;
      case 'wood':
        return ochreDeep;
      case 'soaps':
        return const Color(0xFF6A8AAB);
      case 'candles':
        return goldenGlow;
      default:
        return sageGreen;
    }
  }

  // ─── Shimmer colors ───
  static const Color shimmerBase = Color(0xFFEFECE4);
  static const Color shimmerHighlight = Color(0xFFFBFAF6);

  // ─── Text theme ───
  static const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w800,
      color: forestGreen,
      height: 1.05,
      letterSpacing: -1.0,
    ),
    displayMedium: TextStyle(
      fontSize: 34,
      fontWeight: FontWeight.w800,
      color: forestGreen,
      height: 1.1,
      letterSpacing: -0.5,
    ),
    displaySmall: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w800,
      color: forestGreen,
      height: 1.15,
      letterSpacing: -0.3,
    ),
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: forestGreen,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: forestGreen,
      height: 1.25,
    ),
    headlineSmall: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: forestGreen,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: charcoal,
      height: 1.35,
    ),
    titleMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: charcoal,
      height: 1.4,
    ),
    titleSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: charcoal,
      letterSpacing: 0.4,
    ),
    bodyLarge: TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: graphite,
      height: 1.55,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: graphite,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: muted,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: charcoal,
      letterSpacing: 0.2,
    ),
    labelMedium: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: muted,
      letterSpacing: 0.4,
    ),
    labelSmall: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: muted,
      letterSpacing: 0.6,
    ),
  );

  // ─── ThemeData ───
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: warmSand,
      primaryColor: terracotta,
      colorScheme: ColorScheme.fromSeed(
        seedColor: terracotta,
        primary: terracotta,
        secondary: forestGreen,
        surface: surface,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: forestGreen),
        titleTextStyle: TextStyle(
          color: forestGreen,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestGreen,
          side: const BorderSide(color: border, width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: terracotta,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: forestGreen,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: terracotta,
        unselectedItemColor: muted,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: warmSandLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: terracotta, width: 1.6),
        ),
        labelStyle: const TextStyle(color: muted, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: mutedSoft, fontWeight: FontWeight.w500),
      ),
      dividerTheme: const DividerThemeData(
        color: borderLight,
        thickness: 1,
        space: 0,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
