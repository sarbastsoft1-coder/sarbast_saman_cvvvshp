/// String constants for all routes used by [go_router].
///
/// Keeping every route name in one place prevents typos and makes it
/// trivial to find / refactor any navigation path in the app.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';

  // Shell + nested
  static const String shell = '/shell';
  static const String dashboard = '/dashboard';
  static const String orders = '/orders';
  static const String orderDetail = 'detail'; // relative under /orders/:id
  static const String products = '/products';
  static const String addProduct = 'add';
  static const String editProduct = 'edit';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String notifications = '/notifications';
  /// Payouts tab (HTML `#payouts`) — settlements / weekly money.
  static const String settlements = '/settlements';
  static const String payouts = '/settlements';
}