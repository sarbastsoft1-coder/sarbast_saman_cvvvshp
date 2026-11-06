import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../models/models.dart';
import '../utils/responsive.dart';
import '../utils/animations.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'market_screen.dart';
import 'challenges_screen.dart';
import 'profile_screen.dart';
import 'cart_screen.dart';
import '../services/api_service.dart';
import '../localization/string_extension.dart';
import '../widgets/language_selector_sheet.dart';

/// Global app state — shared across all tabs
class AppState extends ChangeNotifier {
  bool isLoading = true;
  double tokenBalance = 250.0;
  double fiatBalance = 480.00;
  double terraRate = 1.25;
  List<CartItem> cart = [];
  Set<int> favorites = {};
  List<Trade> trades = [];

  // Home Data
  List<Article> articles = [];
  List<Product> featuredProducts = [];
  List<Challenge> challenges = [];
  Map<String, dynamic> marketSummary = {};
  List<Product> exploreProducts = [];

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    try {
      final profileRes = await ApiService.get('/auth/profile');
      if (profileRes['status'] == 'success') {
        final wallet = profileRes['user']['wallet'];
        if (wallet != null) {
          tokenBalance = (wallet['token_balance'] as num).toDouble();
          fiatBalance = (wallet['fiat_balance'] as num).toDouble();
        }
      }

      final favRes = await ApiService.get('/customer/favorites');
      if (favRes['status'] == 'success') {
        final List favList = favRes['data'];
        favorites = favList.map((p) => p['id'] as int).toSet();
      }

      final homeRes = await ApiService.get('/customer/home');
      if (homeRes['status'] == 'success') {
        final data = homeRes['data'];

        articles = (data['articles'] as List)
            .map(
              (a) => Article(
                id: a['id'],
                title: a['title'],
                tag: a['tag'] ?? 'NEWS',
                readTime: a['read_time'] ?? '3 min',
                author: a['author'] ?? 'Admin',
                emoji: a['emoji'] ?? '📰',
                body: a['content'] ?? '',
              ),
            )
            .toList();

        featuredProducts = (data['featured_products'] as List)
            .map(
              (p) => Product(
                id: p['id'],
                name: p['name'],
                seller: p['store']?['name'] ?? 'Store',
                price: ((p['sale_price_fiat'] ?? p['price_fiat']) as num).toDouble(),
                emoji: p['emoji'] ?? '📦',
                category: p['category'] ?? 'other',
                description: p['description'] ?? '',
                rating: (p['rating'] as num?)?.toDouble() ?? 4.5,
                reviews: (p['reviews_count'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList();

        challenges = (data['challenges'] as List)
            .map(
              (c) => Challenge(
                id: c['id'] is int ? c['id'] : (c['id'] as num).toInt(),
                title: c['title'],
                reward: (c['reward_tokens'] as num?)?.toInt() ?? 10,
                description: c['description'] ?? '',
                icon: c['icon'] ?? '🌱',
                progress: ((c['progress'] as num?)?.toDouble() ?? 0).clamp(
                  0,
                  1,
                ),
                target: 1,
              ),
            )
            .toList();

        marketSummary = data['market_summary'] ?? {};
        if (marketSummary['rate'] != null) {
          terraRate = (marketSummary['rate'] as num).toDouble();
        }
      }

      final exploreRes = await ApiService.get('/customer/products');
      if (exploreRes['status'] == 'success') {
        exploreProducts = (exploreRes['data'] as List)
            .map(
              (p) => Product(
                id: p['id'],
                name: p['name'],
                seller: p['store']?['name'] ?? 'Store',
                price: ((p['sale_price_fiat'] ?? p['price_fiat']) as num).toDouble(),
                emoji: p['emoji'] ?? '📦',
                category: p['category'] ?? 'other',
                description: p['description'] ?? '',
                rating: (p['rating'] as num?)?.toDouble() ?? 4.5,
                reviews: (p['reviews_count'] as num?)?.toInt() ?? 0,
              ),
            )
            .toList();
      }
    } catch (e) {
      debugPrint('Error initializing app state: $e');
    }

    if (articles.isEmpty) articles = sampleArticles.toList();
    if (featuredProducts.isEmpty) {
      featuredProducts = sampleProducts.take(4).toList();
    }
    if (challenges.isEmpty) challenges = sampleChallenges.toList();
    if (exploreProducts.isEmpty) exploreProducts = sampleProducts.toList();
    if (trades.isEmpty) trades = sampleTrades.toList();

    isLoading = false;
    notifyListeners();
  }

  String selectedCategory = 'all';

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  int get cartCount => cart.fold(0, (sum, c) => sum + c.qty);

  double get cartSubtotal => cart.fold(0.0, (sum, c) => sum + c.totalPrice);

  void addToCart(Product product) {
    final existing = cart.where((c) => c.product.id == product.id);
    if (existing.isNotEmpty) {
      existing.first.qty++;
    } else {
      cart.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    cart.removeWhere((c) => c.product.id == productId);
    notifyListeners();
  }

  void changeQty(int productId, int delta) {
    final item = cart.where((c) => c.product.id == productId);
    if (item.isEmpty) return;
    item.first.qty += delta;
    if (item.first.qty <= 0) {
      removeFromCart(productId);
    } else {
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(int productId) async {
    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }
    notifyListeners();
    try {
      await ApiService.post('/favorites/toggle', {'product_id': productId});
    } catch (e) {
      debugPrint('Failed to sync favorite: $e');
    }
  }

  bool executeTradeSimple(String type, double amount) {
    final usd = amount * terraRate;
    if (type == 'buy') {
      if (usd > fiatBalance) return false;
      fiatBalance -= usd;
      tokenBalance += amount;
    } else {
      if (amount > tokenBalance) return false;
      tokenBalance -= amount;
      fiatBalance += usd;
    }
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    trades.add(Trade(type: type, amount: amount, usd: usd, time: timeStr));
    notifyListeners();
    return true;
  }

  Future<bool> checkout({
    bool withTokens = false,
    String address = 'My Address',
  }) async {
    final total = cartSubtotal + 4.99;

    if (withTokens) {
      final needed = total / terraRate;
      if (tokenBalance < needed) return false;
      tokenBalance -= needed;
    } else {
      if (fiatBalance < total) return false;
      fiatBalance -= total;
    }

    final items = cart
        .map((c) => {'product_id': c.product.id, 'quantity': c.qty})
        .toList();

    try {
      final response = await ApiService.post('/checkout', {
        'items': items,
        'payment_method': withTokens ? 'token' : 'fiat',
        'shipping_address': address,
      });

      if (response['status'] == 'success') {
        cart.clear();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Checkout error: $e');
    }
    return false;
  }

  void updateRewardBalance(num value) {
    tokenBalance = value.toDouble();
    notifyListeners();
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  final AppState appState = AppState();

  @override
  void initState() {
    super.initState();
    appState.init();
  }

  void switchTab(int index, {String? category}) {
    if (category != null) {
      appState.setCategory(category);
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final isMobile = Responsive.isMobile(context);

        final screens = [
          HomeScreen(appState: appState, onSwitchTab: switchTab),
          ExploreScreen(appState: appState),
          MarketScreen(appState: appState),
          ChallengesScreen(appState: appState),
          ProfileScreen(appState: appState, onSwitchTab: switchTab),
        ];

        return Scaffold(
          backgroundColor: EarthTheme.warmSand,
          appBar: _buildAppBar(),
          body: appState.isLoading
              ? const _LoadingShell()
              : isMobile
              ? AnimatedSwitcher(
                  duration: EarthTheme.dur,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: EarthTheme.curveOut,
                            ),
                          ),
                      child: child,
                    ),
                  ),
                  child: KeyedSubtree(
                    key: ValueKey(_currentIndex),
                    child: screens[_currentIndex],
                  ),
                )
              : Row(
                  children: [
                    _AnimatedNavRail(
                      currentIndex: _currentIndex,
                      onChanged: (i) => setState(() => _currentIndex = i),
                      cartCount: appState.cartCount,
                    ),
                    const VerticalDivider(
                      thickness: 1,
                      width: 1,
                      color: EarthTheme.borderLight,
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: EarthTheme.dur,
                        transitionBuilder: (child, anim) =>
                            FadeTransition(opacity: anim, child: child),
                        child: KeyedSubtree(
                          key: ValueKey(_currentIndex),
                          child: screens[_currentIndex],
                        ),
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: isMobile
              ? _AnimatedBottomNav(
                  currentIndex: _currentIndex,
                  onChanged: (i) => setState(() => _currentIndex = i),
                  cartCount: appState.cartCount,
                )
              : null,
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: EarthTheme.warmSand,
      surfaceTintColor: Colors.transparent,
      titleSpacing: 4,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: EarthTheme.heroGradient,
              borderRadius: BorderRadius.circular(13),
              boxShadow: EarthTheme.forestGlow,
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'EarthShop',
            style: TextStyle(
              color: EarthTheme.forestGreen,
              fontSize: 21,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: SoftIconButton(
            icon: Icons.language_rounded,
            onTap: () => showLanguageSheet(context),
            tooltip: 'Language'.tr(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: SoftIconButton(
            icon: Icons.search_rounded,
            onTap: () => switchTab(1),
            tooltip: 'Explore'.tr(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: SoftIconButton(
            icon: Icons.notifications_outlined,
            badgeCount: 2,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No new notifications'.tr(context))),
              );
            },
            tooltip: 'Notifications'.tr(context),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: SoftIconButton(
            icon: Icons.shopping_bag_outlined,
            badgeCount: appState.cartCount,
            onTap: () {
              Navigator.of(context).push(
                SharedAxisPageRoute(
                  builder: (_) => CartScreen(appState: appState),
                ),
              );
            },
            tooltip: 'Cart',
          ),
        ),
      ],
    );
  }
}

class _LoadingShell extends StatelessWidget {
  const _LoadingShell();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [EarthTheme.forestGreen, EarthTheme.sageGreen],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: EarthTheme.forestGlow,
            ),
            child: const Center(
              child: Text('🌿', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 18),
          const SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              color: EarthTheme.terracotta,
              strokeWidth: 2.6,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Cultivating your shop...',
            style: TextStyle(
              fontSize: 13,
              color: EarthTheme.muted,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────────────────────────────────────────
//  Animated Bottom Nav — morphing icon capsule
// ───────────────────────────────────────────────────────────
class _AnimatedBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final int cartCount;

  const _AnimatedBottomNav({
    required this.currentIndex,
    required this.onChanged,
    required this.cartCount,
  });

  static const List<_NavItem> _items = [
    _NavItem('Home', Icons.home_rounded, Icons.home_outlined),
    _NavItem('Explore', Icons.explore_rounded, Icons.explore_outlined),
    _NavItem('Market', Icons.show_chart_rounded, Icons.show_chart_outlined),
    _NavItem('Quests', Icons.emoji_events_rounded, Icons.emoji_events_outlined),
    _NavItem('Profile', Icons.person_rounded, Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: EarthTheme.borderLight),
        boxShadow: [
          BoxShadow(
            color: EarthTheme.forestGreen.withValues(alpha: 0.10),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
          BoxShadow(
            color: EarthTheme.forestGreen.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_items.length, (i) {
            final selected = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: EarthTheme.dur,
                  curve: EarthTheme.curveSpring,
                  padding: EdgeInsets.symmetric(
                    horizontal: selected ? 10 : 6,
                    vertical: 8,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: selected
                        ? const LinearGradient(
                            colors: [
                              EarthTheme.terracotta,
                              EarthTheme.clayOchre,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: selected ? EarthTheme.terracottaGlow : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: EarthTheme.durFast,
                        transitionBuilder: (c, a) =>
                            ScaleTransition(scale: a, child: c),
                        child: Icon(
                          selected ? _items[i].active : _items[i].inactive,
                          key: ValueKey('$selected-${_items[i].label}'),
                          size: 22,
                          color: selected ? Colors.white : EarthTheme.muted,
                        ),
                      ),
                      AnimatedSize(
                        duration: EarthTheme.dur,
                        curve: EarthTheme.curveSpring,
                        child: selected
                            ? Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Text(
                                  _items[i].label.tr(context),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData active;
  final IconData inactive;
  const _NavItem(this.label, this.active, this.inactive);
}

// ───────────────────────────────────────────────────────────
//  Animated Nav Rail (desktop / tablet)
// ───────────────────────────────────────────────────────────
class _AnimatedNavRail extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final int cartCount;

  const _AnimatedNavRail({
    required this.currentIndex,
    required this.onChanged,
    required this.cartCount,
  });

  @override
  State<_AnimatedNavRail> createState() => _AnimatedNavRailState();
}

class _AnimatedNavRailState extends State<_AnimatedNavRail> {
  static const List<_NavItem> _items = [
    _NavItem('Home', Icons.home_rounded, Icons.home_outlined),
    _NavItem('Explore', Icons.explore_rounded, Icons.explore_outlined),
    _NavItem('Market', Icons.show_chart_rounded, Icons.show_chart_outlined),
    _NavItem('Quests', Icons.emoji_events_rounded, Icons.emoji_events_outlined),
    _NavItem('Profile', Icons.person_rounded, Icons.person_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: EarthTheme.heroGradient,
                borderRadius: BorderRadius.circular(14),
                boxShadow: EarthTheme.forestGlow,
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 24),
            ...List.generate(_items.length, (i) {
              final selected = i == widget.currentIndex;
              return _RailItem(
                label: _items[i].label.tr(context),
                activeIcon: _items[i].active,
                inactiveIcon: _items[i].inactive,
                selected: selected,
                onTap: () => widget.onChanged(i),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _RailItem extends StatefulWidget {
  final String label;
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool selected;
  final VoidCallback onTap;

  const _RailItem({
    required this.label,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_RailItem> createState() => _RailItemState();
}

class _RailItemState extends State<_RailItem> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: EarthTheme.dur,
        curve: EarthTheme.curveSpring,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: widget.selected
              ? const LinearGradient(
                  colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.selected ? EarthTheme.terracottaGlow : null,
        ),
        child: Column(
          children: [
            AnimatedSwitcher(
              duration: EarthTheme.durFast,
              transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
              child: Icon(
                widget.selected ? widget.activeIcon : widget.inactiveIcon,
                key: ValueKey('${widget.selected}-${widget.label}'),
                color: widget.selected ? Colors.white : EarthTheme.muted,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: widget.selected ? Colors.white : EarthTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
