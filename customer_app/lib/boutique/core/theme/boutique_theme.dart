import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/roni_motion.dart';
import 'boutique_colors.dart';
import 'boutique_tokens.dart';

/// Centralized typography, themes, and component styling for the boutique.
///
/// Everything here is derived from [BoutiqueTokens] and [RoniPalette] so the
/// app has one spacing, radius, type and motion language. The palette is
/// resolved per brightness, which matters because Roni boots in dark mode —
/// a theme that only worked in light would leave half the app unreadable.
class BoutiqueTheme {
  BoutiqueTheme._();

  /// Preferred font family. Falls back to the platform default when the asset
  /// is unavailable, which still renders Kurdish Sorani beautifully.
  static const String _fontFamily = BoutiqueTokens.fontFamily;

  // ------------------------------------------------------------------ Theme

  static ThemeData get light => _build(RoniPalette.light, Brightness.light);

  static ThemeData get dark => _build(RoniPalette.dark, Brightness.dark);

  static ThemeData _build(RoniPalette p, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // The text scale is the token scale — nine sizes, no more.
    final text = TextTheme(
      displayLarge: BoutiqueTokens.display.copyWith(color: p.fg),
      displayMedium: BoutiqueTokens.display.copyWith(
        color: p.fg,
        fontSize: 26,
      ),
      headlineLarge: BoutiqueTokens.title1.copyWith(color: p.fg),
      headlineMedium: BoutiqueTokens.title1.copyWith(color: p.fg),
      headlineSmall: BoutiqueTokens.title2.copyWith(color: p.fg),
      titleLarge: BoutiqueTokens.title2.copyWith(color: p.fg),
      titleMedium: BoutiqueTokens.title3.copyWith(color: p.fg),
      titleSmall: BoutiqueTokens.title4.copyWith(color: p.fg),
      bodyLarge: BoutiqueTokens.body.copyWith(color: p.fg),
      bodyMedium: BoutiqueTokens.body.copyWith(color: p.muted),
      bodySmall: BoutiqueTokens.bodySmall.copyWith(color: p.muted),
      labelLarge: BoutiqueTokens.label.copyWith(color: p.fg),
      labelMedium: BoutiqueTokens.label.copyWith(color: p.muted),
      labelSmall: BoutiqueTokens.caption.copyWith(color: p.onSurfaceVariant),
    );

    final onBrand = isDark ? BoutiqueColors.ink : BoutiqueColors.white;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: _fontFamily,
      scaffoldBackgroundColor: p.bg,
      canvasColor: p.bg,
      primaryColor: p.brand2,
      extensions: [p],
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: p.brand2,
        onPrimary: onBrand,
        secondary: p.brand2,
        onSecondary: onBrand,
        surface: p.surface,
        onSurface: p.fg,
        surfaceContainerHighest: p.soft,
        outline: p.borderStrong,
        outlineVariant: p.line,
        error: p.sale,
        onError: BoutiqueColors.white,
      ),
      cardTheme: CardThemeData(
        color: p.card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusLg),
          side: BorderSide(color: p.line),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.brand2,
          foregroundColor: onBrand,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.surface,
          foregroundColor: p.fg,
          elevation: 0,
          minimumSize: const Size(48, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.fg,
          backgroundColor: p.surface,
          minimumSize: const Size(48, 52),
          side: BorderSide(color: p.borderStrong),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brand2,
          textStyle: const TextStyle(
            fontFamily: _fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: p.fg,
          minimumSize: const Size(
            BoutiqueTokens.tapTarget,
            BoutiqueTokens.tapTarget,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceSunken,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: BoutiqueTokens.lg,
          vertical: BoutiqueTokens.lg,
        ),
        hintStyle: TextStyle(
          color: p.muted,
          fontFamily: _fontFamily,
          fontSize: 15,
        ),
        labelStyle: TextStyle(color: p.muted, fontFamily: _fontFamily),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          borderSide: BorderSide(color: p.brand2, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          borderSide: BorderSide(color: p.sale),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
          borderSide: BorderSide(color: p.sale, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.fg,
        contentTextStyle: TextStyle(
          color: p.bg,
          fontFamily: _fontFamily,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusMd),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surface,
        selectedColor: p.fg,
        side: BorderSide(color: p.line),
        labelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.fg,
        ),
        secondaryLabelStyle: TextStyle(
          fontFamily: _fontFamily,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.bg,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusPill),
        ),
      ),
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: p.fg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: text.titleLarge,
        iconTheme: IconThemeData(color: p.fg),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(BoutiqueTokens.radiusXl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusXl),
        ),
      ),
      dividerTheme: DividerThemeData(color: p.line, thickness: 1, space: 1),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: p.soft,
        elevation: 0,
        height: 74,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand2,
        linearTrackColor: p.line,
        circularTrackColor: p.line,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.fg,
          borderRadius: BorderRadius.circular(BoutiqueTokens.radiusXs),
        ),
        textStyle: TextStyle(color: p.bg, fontFamily: _fontFamily, fontSize: 12),
      ),
      iconTheme: IconThemeData(color: p.fg),
      splashColor: p.brand2.withValues(alpha: 0.10),
      highlightColor: p.brand2.withValues(alpha: 0.06),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: RoniPageTransitionsBuilder(),
          TargetPlatform.iOS: RoniPageTransitionsBuilder(),
          TargetPlatform.macOS: RoniPageTransitionsBuilder(),
          TargetPlatform.windows: RoniPageTransitionsBuilder(),
          TargetPlatform.linux: RoniPageTransitionsBuilder(),
          TargetPlatform.fuchsia: RoniPageTransitionsBuilder(),
        },
      ),
    );
  }
}
