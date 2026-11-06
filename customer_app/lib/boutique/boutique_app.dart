import 'models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/customer_provider.dart';

import '../localization/fallback_localizations.dart';
import 'core/routes/boutique_routes.dart';
import 'core/theme/boutique_colors.dart';
import 'core/theme/boutique_theme.dart';
import 'providers/auction_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/challenges_provider.dart';
import 'providers/checkout_provider.dart';
import 'providers/coins_provider.dart';
import 'providers/invite_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/notifications_provider.dart';
import 'providers/orders_provider.dart';
import 'providers/recently_viewed_provider.dart';
import 'providers/reviews_provider.dart';
import 'providers/roni_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/wishlist_provider.dart';
import 'services/commerce_api.dart';

/// Root widget for the boutique customer app.
class BoutiqueApp extends StatefulWidget {
  const BoutiqueApp({
    super.key,
    this.preferences,
    this.catalogLoader,
    this.api,
  });
  final SharedPreferences? preferences;
  final Future<List<BoutiqueProduct>> Function()? catalogLoader;

  /// Overridable so tests can inject a fake transport.
  final CommerceApi? api;

  @override
  State<BoutiqueApp> createState() => _BoutiqueAppState();
}

class _BoutiqueAppState extends State<BoutiqueApp> {
  late final CommerceApi _api = widget.api ?? CommerceApi();
  late final AuthProvider _auth;
  late final NotificationsProvider _notifications;
  late final CustomerProvider _customer;
  late final CoinsProvider _coins;
  late final AuctionProvider _auction;
  late final WishlistProvider _wishlist;
  late final OrdersProvider _orders;
  late final RoniProvider _roni;
  late final CartProvider _cart;
  late final CatalogProvider _catalog;

  @override
  void initState() {
    super.initState();
    _auth = AuthProvider(api: _api, preferences: widget.preferences);
    _notifications = NotificationsProvider(
      api: _api,
      preferences: widget.preferences,
    );
    _customer = CustomerProvider(api: _api, preferences: widget.preferences);
    _coins = CoinsProvider(api: _api, preferences: widget.preferences);
    _auction = AuctionProvider(api: _api, preferences: widget.preferences);
    _wishlist = WishlistProvider(api: _api, preferences: widget.preferences);
    _orders = OrdersProvider(api: _api, preferences: widget.preferences);
    _roni = RoniProvider(api: _api);
    _cart = CartProvider(preferences: widget.preferences);
    _catalog = CatalogProvider(
      api: _api,
      loader: widget.catalogLoader,
      onProductsLoaded: _cart.syncProducts,
    )..load();

    _auth.addListener(_syncToken);
    _auth.addListener(_onAuthChanged);
    _auth.restore().then((_) {
      _syncToken();
      if (_auth.isSignedIn) _onAuthChanged();
    });
  }

  void _syncToken() {
    final token = _auth.isSignedIn ? _auth.token : null;
    if (_api.token != token) _api.useToken(token);
  }

  /// Account-scoped data: load on sign-in, clear/stop on sign-out.
  void _onAuthChanged() {
    if (_auth.isSignedIn) {
      _notifications
        ..reset()
        ..refresh(full: true)
        ..startPolling();
      _orders.refreshFromApi();
      _customer.refreshFromApi();
      _wishlist.refreshFromApi();
      _coins.refresh();
      _auction.refresh();
      _roni.refresh();
    } else {
      _notifications.reset();
      _coins.reset();
      _orders.clearForGuest();
      _customer.clearForGuest();
    }
  }

  @override
  void dispose() {
    _auth
      ..removeListener(_syncToken)
      ..removeListener(_onAuthChanged)
      ..dispose();
    _notifications.dispose();
    _coins.dispose();
    _auction.dispose();
    _wishlist.dispose();
    _orders.dispose();
    _roni.dispose();
    _customer.dispose();
    _catalog.dispose();
    if (widget.api == null) _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SharedPreferences?>.value(value: widget.preferences),
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),
        ChangeNotifierProvider<CustomerProvider>.value(value: _customer),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
        ChangeNotifierProvider(create: (_) => BoutiqueNavProvider()),
        ChangeNotifierProvider<CoinsProvider>.value(value: _coins),
        ChangeNotifierProvider<AuctionProvider>.value(value: _auction),
        ChangeNotifierProvider(create: (_) => ChallengesProvider()),
        ChangeNotifierProvider(create: (_) => InviteProvider()),
        ChangeNotifierProvider<RoniProvider>.value(value: _roni),
        ChangeNotifierProvider<CartProvider>.value(value: _cart),
        ChangeNotifierProvider<CheckoutProvider>(
          create: (_) => CheckoutProvider(api: _api),
        ),
        ChangeNotifierProvider<WishlistProvider>.value(value: _wishlist),
        ChangeNotifierProvider<CatalogProvider>.value(value: _catalog),
        ChangeNotifierProvider<OrdersProvider>.value(value: _orders),
        ChangeNotifierProvider(
          create: (_) =>
              RecentlyViewedProvider(preferences: widget.preferences),
        ),
        ChangeNotifierProvider(
          create: (_) => ReviewsProvider(preferences: widget.preferences),
        ),
        ChangeNotifierProvider<NotificationsProvider>.value(
          value: _notifications,
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) {
          const locale = Locale('ku');
          final themeMode = switch (settings.themeMode) {
            BoutiqueThemeMode.light => ThemeMode.light,
            BoutiqueThemeMode.dark => ThemeMode.dark,
            BoutiqueThemeMode.system => ThemeMode.system,
          };
          return MaterialApp(
            title: 'Ronix',
            debugShowCheckedModeBanner: false,
            theme: BoutiqueTheme.light,
            darkTheme: BoutiqueTheme.dark,
            themeMode: themeMode,
            onGenerateRoute: BoutiqueRoutes.onGenerateRoute,
            locale: locale,
            supportedLocales: const [
              Locale('ku'),
              Locale('ckb'),
              Locale('ar'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              FallbackMaterialLocalizationsDelegate(),
              FallbackWidgetsLocalizationsDelegate(),
              FallbackCupertinoLocalizationsDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            builder: (context, child) {
              // The status and system bars have to follow the resolved theme.
              // Roni boots in dark mode, so a hard-coded "dark icons on cream"
              // overlay left the status bar unreadable on the dark header.
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final p = RoniPalette.of(context);
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: p.bg,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarDividerColor: Colors.transparent,
                ),
                child: Directionality(
                  textDirection: TextDirection.rtl,
                  child: MediaQuery(
                    data: MediaQuery.of(context).copyWith(
                      textScaler: MediaQuery.of(context).textScaler.clamp(
                        minScaleFactor: 0.9,
                        maxScaleFactor: 1.2,
                      ),
                    ),
                    child: Builder(
                      builder: (context) {
                        return ColoredBox(
                          color: p.bg,
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1280),
                              child: ColoredBox(color: p.surface, child: child!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
