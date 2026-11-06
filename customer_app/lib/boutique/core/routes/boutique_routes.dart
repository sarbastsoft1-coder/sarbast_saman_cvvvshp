import '../../features/roni/membership_screen.dart';
import '../../features/roni/gives_screen.dart';
import '../../features/roni/how_roni_works_screen.dart';
import '../../providers/catalog_provider.dart';
import '../../widgets/roni_motion.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/chats/chat_screen.dart';
import '../../features/chats/chats_screen.dart';
import '../../features/notifications/notification_detail_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/onboarding/lang_screen.dart';
import '../../features/onboarding/onboard_screen.dart';
import '../../features/onboarding/otp_login_screen.dart';
import '../../features/orders/complaint_screen.dart';
import '../../features/orders/inspect_screen.dart';
import '../../features/orders/order_confirmed_screen.dart';
import '../../features/orders/order_tracking_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/orders/rate_order_screen.dart';
import '../../features/pages_map_screen.dart';
import '../../features/products/product_details_screen.dart';
import '../../features/profile/addresses_screen.dart';
import '../../features/profile/edit_profile_screen.dart';
import '../../features/profile/help_screen.dart';
import '../../features/profile/invite_screen.dart';
import '../../features/recently_viewed/recently_viewed_screen.dart';
import '../../features/reviews/write_review_screen.dart';
import '../../features/roni/auction_screen.dart';
import '../../features/roni/bid_screen.dart';
import '../../features/roni/challenges_screen.dart';
import '../../features/roni/coin_shop_screen.dart';
import '../../features/roni/coins_screen.dart';
import '../../features/roni/deals_screen.dart';
import '../../features/roni/splash_screen.dart';
import '../../features/roni/winners_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/store/seller_store_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../models/product.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/orders_provider.dart';
import '../../core/theme/boutique_colors.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/store_components.dart';

class BoutiqueRoutes {
  BoutiqueRoutes._();

  static const home = '/',
      products = '/products',
      auction = '/auction',
      cart = '/cart',
      profile = '/profile';

  static const deals = '/deals',
      orders = '/orders',
      wishlist = '/wishlist',
      productDetails = '/product-details',
      checkout = '/checkout',
      search = '/search',
      orderTracking = '/order-tracking',
      orderConfirmed = '/order-confirmed',
      inspect = '/inspect',
      rateOrder = '/rate-order',
      complaint = '/complaint',
      notifications = '/notifications',
      notificationDetail = '/notification-detail',
      recentlyViewed = '/recently-viewed',
      writeReview = '/write-review',
      settings = '/settings',
      addresses = '/addresses',
      editProfile = '/edit-profile',
      auth = '/auth',
      help = '/help',
      splash = '/splash',
      lang = '/lang',
      onboard = '/onboard',
      otpLogin = '/otp-login',
      coins = '/coins',
      coinShop = '/coin-shop',
      membership = '/membership',
      gives = '/gives',
      how = '/how',
      challenges = '/challenges',
      bid = '/bid',
      winners = '/winners',
      invite = '/invite',
      chats = '/chats',
      chat = '/chat',
      store = '/store',
      pages = '/pages';

  /// Root tabs only. Ronix (index 2) is also reachable as the pushed
  /// [coins] route; auction is a pushed screen.
  static const tabRoutes = {home, products, cart, profile};
  static const cartTab = 3, profileTab = 4;

  static void openTab(BuildContext context, int index) {
    context.read<BoutiqueNavProvider>().switchTab(index);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  static void openCart(BuildContext context) {
    openTab(context, cartTab);
  }

  static void openWishlist(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.popUntil((route) => route.isFirst);
    navigator.pushNamed(wishlist);
  }

  static BoutiqueOrder? _orderFrom(Object? args, Map map, BuildContext context) {
    if (args is BoutiqueOrder) return args;
    final orderId = args is String
        ? args
        : (map['orderId'] ?? map['id'])?.toString();
    if (orderId == null) return null;
    return context.watch<OrdersProvider>().byId(orderId);
  }

  static Route<dynamic> onGenerateRoute(RouteSettings routeSettings) {
    final uri =
        Uri.tryParse(routeSettings.name ?? '/') ?? Uri(path: '/missing');
    final args = routeSettings.arguments;
    final map = args is Map ? args : const {};
    final rawId = map['id'] ?? map['productId'] ?? uri.queryParameters['id'];
    final id = int.tryParse('$rawId');
    final argumentProduct = args is BoutiqueProduct ? args : null;
    String? entityId;
    if ([productDetails, writeReview, store].contains(uri.path) &&
        argumentProduct != null) {
      entityId = '${argumentProduct.id}';
    }
    if ({orderTracking, orderConfirmed, inspect, rateOrder, complaint}
        .contains(uri.path)) {
      entityId = args is BoutiqueOrder
          ? args.id
          : (args is String
                ? args
                : (map['orderId'] ?? uri.queryParameters['id'])?.toString());
    }
    if (uri.path == notificationDetail) {
      entityId = args is int ? '$args' : id?.toString();
    }
    if (uri.path == chat) {
      entityId = args is String ? args : map['id']?.toString();
    }
    if (uri.path == store && args is String) {
      entityId = args;
    }
    final name = entityId == null
        ? uri.toString()
        : uri
              .replace(
                queryParameters: {...uri.queryParameters, 'id': entityId},
              )
              .toString();
    return RoniPageRoute(
      settings: RouteSettings(name: name, arguments: args),
      builder: (context) {
        final product =
            argumentProduct ??
            context
                .watch<CatalogProvider>()
                .products
                .where((p) => p.id == id)
                .firstOrNull;
        Widget buildPage() {
          switch (uri.path) {
            case home:
              return const BoutiqueMainShell();
            case products:
              return const BoutiqueMainShell(initialIndex: 1);
            case cart:
              return const BoutiqueMainShell(initialIndex: cartTab);
            case profile:
              return const BoutiqueMainShell(initialIndex: profileTab);
            case auction:
              return const AuctionScreen();
            case deals:
              return const DealsScreen();
            case orders:
              return const OrdersScreen();
            case wishlist:
              return const WishlistScreen();
            case productDetails:
              return product == null
                  ? const MissingRouteScreen()
                  : ProductDetailsScreen(product: product);
            case writeReview:
              return product == null
                  ? const MissingRouteScreen()
                  : WriteReviewScreen(product: product);
            case checkout:
              return const CheckoutScreen();
            case search:
              return const SearchScreen();
            case orderTracking:
              final order = _orderFrom(args, map, context);
              return order == null
                  ? const MissingRouteScreen()
                  : OrderTrackingScreen(order: order);
            case orderConfirmed:
              final order = _orderFrom(args, map, context);
              return order == null
                  ? const MissingRouteScreen()
                  : OrderConfirmedScreen(order: order);
            case inspect:
              final order = _orderFrom(args, map, context);
              return order == null
                  ? const MissingRouteScreen()
                  : InspectScreen(order: order);
            case rateOrder:
              final order = _orderFrom(args, map, context);
              return order == null
                  ? const MissingRouteScreen()
                  : RateOrderScreen(order: order);
            case complaint:
              return ComplaintScreen(order: _orderFrom(args, map, context));
            case notifications:
              return const NotificationsScreen();
            case notificationDetail:
              final notificationId = args is int ? args : id;
              return notificationId == null
                  ? const MissingRouteScreen()
                  : NotificationDetailScreen(notificationId: notificationId);
            case recentlyViewed:
              return const RecentlyViewedScreen();
            case settings:
              return const SettingsScreen();
            case addresses:
              return const AddressesScreen();
            case editProfile:
              return const EditProfileScreen();
            case auth:
              return const AuthScreen();
            case help:
              return const HelpScreen();
            case splash:
              return const SplashScreen();
            case lang:
              return const LangScreen();
            case onboard:
              return const OnboardScreen();
            case otpLogin:
              return const OtpLoginScreen();
            case coins:
              return const CoinsScreen();
            case membership:
              return const MembershipScreen();
            case gives:
              return const GivesScreen();
            case how:
              return const HowRoniWorksScreen();
            case coinShop:
              return const CoinShopScreen();
            case challenges:
              return const ChallengesScreen();
            case bid:
              return const BidScreen();
            case winners:
              return const WinnersScreen();
            case invite:
              return const InviteScreen();
            case chats:
              return const ChatsScreen();
            case chat:
              final threadId = args is String
                  ? args
                  : map['id']?.toString() ?? uri.queryParameters['id'];
              return threadId == null
                  ? const MissingRouteScreen()
                  : ChatScreen(threadId: threadId);
            case store:
              final seller = args is String
                  ? args
                  : product?.seller ?? map['seller']?.toString() ?? '';
              return SellerStoreScreen(seller: seller);
            case pages:
              return const PagesMapScreen();
            default:
              return const MissingRouteScreen();
          }
        }

        final isTab = tabRoutes.contains(uri.path);
        final p = RoniPalette.of(context);
        return ColoredBox(
          color: p.bg,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTab ? 1280 : 760),
              child: SafeArea(top: false, child: buildPage()),
            ),
          ),
        );
      },
    );
  }
}

class MissingRouteScreen extends StatelessWidget {
  const MissingRouteScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('پەڕە نەدۆزرایەوە')),
    body: StoreEmpty(
      title: 'ئەم بەستەرە بەردەست نییە',
      message: 'بەرهەم یان داواکارییەکە نەدۆزرایەوە. بگەڕێوە بۆ بۆتیک.',
      icon: Icons.explore_off_outlined,
      action: FilledButton(
        onPressed: () {
          context.read<BoutiqueNavProvider>().switchTab(0);
          Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
        },
        child: const Text('گەڕانەوە بۆ سەرەتا'),
      ),
    ),
  );
}
