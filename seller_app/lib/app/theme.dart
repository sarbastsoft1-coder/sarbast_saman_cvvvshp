import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Roni seller visual language — blue glass HTML prototype (`roni-seller.html`).
///
/// Legacy constant names (`terracotta`, `forest`, …) are kept so existing
/// call sites compile and repaint in the new blue brand colours.
class AppColors {
  AppColors._();

  // Brand (HTML `--pri` / `--pri-d`)
  static const Color terracotta = Color(0xFF2F95FF); // primary blue
  static const Color terracottaDeep = Color(0xFF1C7FE6);
  static const Color terracottaSoft = Color(0xFFBFDDFF);
  static const Color clayOchre = Color(0xFF47A5FF);
  static const Color gold = Color(0xFFFF8F00); // accent / coin

  // Ink & neutrals (HTML `--ink` / `--muted`)
  static const Color forest = Color(0xFF0A0A0A); // primary CTA fill
  static const Color forestLight = Color(0xFF23282D);
  static const Color sage = Color(0xFF4C5055);
  static const Color sageLight = Color(0xFFE5F1FF);

  // Surfaces
  static const Color cream = Color(0xFFEAF3FF); // page wash
  static const Color sand = Color(0xFFC9E3FF);
  static const Color paper = Color(0xB8FFFFFF); // frosted card (~72%)
  static const Color paperSolid = Color(0xFFFFFFFF);
  static const Color field = Color(0xD9FFFFFF);
  static const Color border = Color(0x1F4C5055); // ~12% ink
  static const Color divider = Color(0x384C5055);

  // Status
  static const Color success = Color(0xFF0E7C3E);
  static const Color warning = Color(0xFFFF8F00);
  static const Color danger = Color(0xFFE5484D);
  static const Color info = Color(0xFF1F6FD1);

  // Text
  static const Color textPrimary = Color(0xFF0A0A0A);
  static const Color textSecondary = Color(0xFF30353A);
  static const Color textMuted = Color(0xFF666C72);
  static const Color textOnDark = Color(0xFFF3F6F9);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [Color(0xFF47A5FF), Color(0xFF2F95FF)],
  );
  static const LinearGradient forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0A0A0A), Color(0xFF23282D)],
  );
  static const LinearGradient warmGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF9ECDFF), Color(0xFFE6F2FF), Color(0xFFF4F9FF)],
    stops: [0.0, 0.55, 1.0],
  );
  static const LinearGradient auroraGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF47A5FF), Color(0xFF2F7FE0), Color(0xFF1D5FB8)],
    stops: [0.0, 0.6, 1.0],
  );
  static const LinearGradient payGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF47A5FF), Color(0xFF2F7FE0), Color(0xFF1D5FB8)],
  );
}

/// Centralized theme for the entire seller app.
class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Vazirmatn';

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.terracotta,
      primary: AppColors.terracotta,
      onPrimary: Colors.white,
      secondary: AppColors.forest,
      onSecondary: AppColors.textOnDark,
      surface: AppColors.paperSolid,
      onSurface: AppColors.textPrimary,
      error: AppColors.danger,
    );

    final textTheme = GoogleFonts.interTextTheme().apply(
      fontFamily: _fontFamily,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: _fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.cream,
      textTheme: textTheme.copyWith(
        displayLarge: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.4,
        ),
        displayMedium: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        headlineSmall: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleLarge: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
        titleMedium: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        bodyMedium: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
        labelLarge: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.paperSolid.withValues(alpha: 0.85),
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xF2FFFFFF)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.field,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppColors.terracotta, width: 1.6),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.field,
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          side: const BorderSide(color: AppColors.divider),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(1000),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.terracottaDeep,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.field,
        selectedColor: AppColors.forest,
        labelStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(1000),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 24,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.forest,
        contentTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AppColors.textOnDark,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
