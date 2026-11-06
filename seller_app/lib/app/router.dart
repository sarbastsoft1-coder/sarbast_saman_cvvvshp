import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/add_product_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/edit_product_screen.dart';
import '../screens/login_screen.dart';
import '../screens/main_shell.dart';
import '../screens/notifications_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/order_detail_screen.dart';
import '../screens/orders_screen.dart';
import '../screens/products_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settlements_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/splash_screen.dart';
import '../services/api_service.dart';
import 'routes.dart';

/// Custom page that fades + slides between destinations.
/// Provides a smoother, more cinematic feel than the default Material transition.
CustomTransitionPage<T> _buildPage<T>({
  required Widget child,
  required GoRouterState state,
  Duration duration = const Duration(milliseconds: 420),
  Duration reverseDuration = const Duration(milliseconds: 320),
  Offset beginOffset = const Offset(0, 0.05),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: reverseDuration,
    transitionsBuilder: (context, animation, secondary, child) {
      final curved =
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: beginOffset, end: Offset.zero)
              .animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// The router for the entire app.
///
/// Splash decides where to go at runtime (login, onboarding or shell),
/// so we use a custom [redirect] only for protected shell routes.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.splash,
  debugLogDiagnostics: false,
  redirect: (context, state) async {
    final loggingIn = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.splash ||
        state.matchedLocation == AppRoutes.onboarding;
    if (loggingIn) return null;

    final token = await ApiService.getToken();
    if (token == null) return AppRoutes.login;
    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.splash,
      pageBuilder: (context, state) =>
          _buildPage(child: const SplashScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.login,
      pageBuilder: (context, state) =>
          _buildPage(child: const LoginScreen(), state: state),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      pageBuilder: (context, state) =>
          _buildPage(child: const OnboardingScreen(), state: state),
    ),
    // Pushed over the shell from the Studio tab; `action_route` targets
    // (e.g. /orders) live on the shell branches below.
    GoRoute(
      path: AppRoutes.notifications,
      pageBuilder: (context, state) =>
          _buildPage(child: const NotificationsScreen(), state: state),
    ),

    // Shell with bottom navigation bar.
    // Tabs: Home · Orders · Products · Payouts · More (HTML seller IA).
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        // ── Dashboard / سەرەکی ───────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.dashboard,
              pageBuilder: (context, state) =>
                  _buildPage(child: const DashboardScreen(), state: state),
            ),
          ],
        ),
        // ── Orders / داواکاری ────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.orders,
              pageBuilder: (context, state) =>
                  _buildPage(child: const OrdersScreen(), state: state),
              routes: [
                GoRoute(
                  path: ':id',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return _buildPage(
                      child: OrderDetailScreen(orderId: id),
                      state: state,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // ── Products / بەرهەم ────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.products,
              pageBuilder: (context, state) =>
                  _buildPage(child: const ProductsScreen(), state: state),
              routes: [
                GoRoute(
                  path: AppRoutes.addProduct,
                  pageBuilder: (context, state) =>
                      _buildPage(child: const AddProductScreen(), state: state),
                ),
                GoRoute(
                  path: ':id/${AppRoutes.editProduct}',
                  pageBuilder: (context, state) {
                    final id = state.pathParameters['id'] ?? '';
                    return _buildPage(
                      child: EditProductScreen(productId: id),
                      state: state,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        // ── Payouts / پارە ───────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.settlements,
              pageBuilder: (context, state) =>
                  _buildPage(child: const SettlementsScreen(), state: state),
            ),
          ],
        ),
        // ── More / زیاتر (profile hub) ───────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              pageBuilder: (context, state) =>
                  _buildPage(child: const ProfileScreen(), state: state),
              routes: [
                GoRoute(
                  path: 'settings',
                  pageBuilder: (context, state) => _buildPage(
                    child: const SettingsScreen(),
                    state: state,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Page not found: ${state.matchedLocation}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  ),
);