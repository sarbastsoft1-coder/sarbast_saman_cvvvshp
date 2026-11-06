import 'package:flutter/material.dart';
import 'providers/notification_provider.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const EarthShopAdminApp());
}

class AdminTheme {
  // Pre-existing constant names preserved for compatibility
  static const Color terracotta = Color(0xFFB0802A); // Roni bronze/gold accent
  static const Color forestGreen = Color(0xFF2E2418); // Roni charcoal
  static const Color forestDark = Color(0xFF241B12); // Roni ink (deepest)
  static const Color warmSand = Color(0xFFFCF8F1); // Roni warm ivory surface
  static const Color sageGreen = Color(0xFF3D7C4F); // Roni success green
  static const Color sageLight = Color(0xFFFBF1DC); // Roni gold wash
  static const Color clayOchre = Color(0xFFC79A3C); // Roni gold
  static const Color earthBorder = Color(0xFFEDE2D0); // Roni border

  // Additional Roni tokens
  static const Color card = Color(0xFFFFFFFF);
  static const Color goldBright = Color(0xFFD7A94A);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFB8862B), Color(0xFFD9A94A)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: warmSand,
      primaryColor: terracotta,
      colorScheme: const ColorScheme.light(
        primary: terracotta,
        onPrimary: Colors.white,
        secondary: forestDark,
        onSecondary: Colors.white,
        surface: card,
        onSurface: forestGreen,
        error: Color(0xFFC2410C),
        onError: Colors.white,
      ),
      fontFamily: 'Vazirmatn',
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: earthBorder),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: forestDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Vazirmatn',
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: terracotta,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: forestDark,
          side: const BorderSide(color: earthBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: earthBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: earthBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: terracotta, width: 1.6),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _FadeSlidePageTransitions(),
          TargetPlatform.iOS: _FadeSlidePageTransitions(),
          TargetPlatform.macOS: _FadeSlidePageTransitions(),
          TargetPlatform.windows: _FadeSlidePageTransitions(),
          TargetPlatform.linux: _FadeSlidePageTransitions(),
          TargetPlatform.fuchsia: _FadeSlidePageTransitions(),
        },
      ),
    );
  }
}

class _FadeSlidePageTransitions extends PageTransitionsBuilder {
  const _FadeSlidePageTransitions();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return child;
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class EarthShopAdminApp extends StatelessWidget {
  const EarthShopAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Roni Admin Control Panel',
      theme: AdminTheme.themeData,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      builder: (context, child) => NotificationScope(
        provider: NotificationProvider.instance,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
