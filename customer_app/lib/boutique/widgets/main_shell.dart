import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/cart/cart_screen.dart';
import '../features/home/home_screen.dart';
import '../features/products/products_screen.dart';
import '../features/roni/coins_screen.dart';
import '../features/profile/profile_screen.dart';
import '../core/constants/boutique_constants.dart';
import '../core/routes/boutique_routes.dart';
import '../providers/catalog_provider.dart';
import '../providers/navigation_provider.dart';
import '../core/theme/boutique_colors.dart';
import 'bottom_navigation.dart';
import 'roni_icons.dart';

/// Tab order follows the ink & gold HTML prototype:
/// Home · Categories · Ronix · Cart · Me.
class BoutiqueMainShell extends StatefulWidget {
  const BoutiqueMainShell({super.key, this.initialIndex});
  final int? initialIndex;
  @override
  State<BoutiqueMainShell> createState() => _BoutiqueMainShellState();
}

class _BoutiqueMainShellState extends State<BoutiqueMainShell> {
  static const _screens = [
    HomeScreen(),
    ProductsScreen(),
    CoinsScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  static const labels = ['سەرەکی', 'بەشەکان', 'Ronix', 'سەبەتە', 'من'];

  static const icons = [
    Icons.home_outlined,
    Icons.grid_view_outlined,
    Icons.monetization_on_outlined,
    Icons.shopping_cart_outlined,
    Icons.person_outline_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _maybeShowSplash();
    if (widget.initialIndex != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<BoutiqueNavProvider>().switchTab(widget.initialIndex!);
        }
      });
    }
  }

  Future<void> _maybeShowSplash() async {
    final prefs = context.read<SharedPreferences?>();
    if (prefs == null) return;
    if (prefs.getBool(BoutiqueConstants.splashSeenKey) ?? false) return;
    await prefs.setBool(BoutiqueConstants.splashSeenKey, true);
    if (!mounted) return;
    await Navigator.of(context).pushNamed(BoutiqueRoutes.splash);
  }

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<BoutiqueNavProvider>();
    final index = nav.currentIndex.clamp(0, _screens.length - 1);
    if (nav.pendingCategory != null) {
      final category = nav.pendingCategory!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<CatalogProvider>().selectCategory(category);
        nav.clearPendingCategory();
      });
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            constraints.maxWidth >= 900 && constraints.maxHeight >= 600;
        final p = RoniPalette.of(context);
        return Scaffold(
          backgroundColor: p.bg,
          extendBody: false,
          body: SafeArea(
            // Home paints its dark header band up under the status bar.
            top: index != 0 || wide,
            bottom: false,
            child: Row(
              children: [
                if (wide)
                  Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: BorderDirectional(
                        end: BorderSide(color: p.line),
                      ),
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            children: [
                              const RonixLogo(size: 56),
                              const SizedBox(height: 10),
                              Text(
                                'بە دڵی ئارام بکڕە',
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 11,
                                  color: p.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        for (var i = 0; i < labels.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              selectedTileColor: p.soft,
                              selectedColor: p.brand2,
                              selected: index == i,
                              leading: Icon(
                                icons[i],
                                color: index == i ? p.brand2 : p.muted,
                              ),
                              title: Text(
                                labels[i],
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 13,
                                  color: index == i ? p.brand2 : p.fg,
                                ),
                              ),
                              onTap: () => nav.switchTab(i),
                            ),
                          ),
                        const Spacer(),
                      ],
                    ),
                  ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      for (var i = 0; i < _screens.length; i++)
                        IgnorePointer(
                          ignoring: i != index,
                          child: AnimatedOpacity(
                            opacity: i == index ? 1 : 0,
                            duration: const Duration(milliseconds: 340),
                            curve: Curves.easeOutCubic,
                            child: AnimatedSlide(
                              offset: i == index
                                  ? Offset.zero
                                  : const Offset(0, 0.02),
                              duration: const Duration(milliseconds: 380),
                              curve: Curves.easeOutCubic,
                              child: TickerMode(
                                enabled: i == index,
                                child: _screens[i],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: wide
              ? null
              : BoutiqueBottomNavigation(
                  currentIndex: index,
                  onTap: nav.switchTab,
                ),
        );
      },
    );
  }
}
