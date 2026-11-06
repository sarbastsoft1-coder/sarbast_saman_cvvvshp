import 'dart:async';

import '../../widgets/responsive_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/boutique_constants.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/recently_viewed_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_art.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_sheet.dart';
import '../../widgets/roni_icons.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';
import '../../providers/orders_provider.dart';

/// Storefront home aligned to the ink & gold HTML prototype: dark header band
/// with search and category tabs, promo carousel, Roni Gives, trust row,
/// flash deals and an endless "for you" feed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _pageSize = 8;
  static const _chips = <({String label, String sort})>[
    (label: 'پێشنیارکراو', sort: 'newest'),
    (label: 'زۆرترین فرۆش', sort: 'best_selling'),
    (label: 'هەرزانترین', sort: 'price_low'),
    (label: 'نوێ', sort: 'new'),
  ];

  int _shown = _pageSize;

  void _browse(BuildContext context) {
    context.read<CatalogProvider>().clearFilters();
    context.read<BoutiqueNavProvider>().switchTab(1);
  }

  void _openProduct(BuildContext context, BoutiqueProduct product) =>
      openProductDetail(context, product);

  void _addToCart(BuildContext context, BoutiqueProduct product) {
    context.read<CartProvider>().add(product);
    showRoniToast(
      context,
      'خرایە ناو سەبەتە',
      actionLabel: 'سەبەتە',
      onAction: () => context.read<BoutiqueNavProvider>().switchTab(
        BoutiqueRoutes.cartTab,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final notifications = context.watch<NotificationsProvider>();
    final settings = context.watch<SettingsProvider>();
    final unread = notifications
        .visibleItems(settings)
        .where((n) => !n.isRead)
        .length;
    final recent = context.watch<RecentlyViewedProvider>().items;
    final feed = catalog.visibleProducts;
    final flash = catalog.products.where((p) => p.hasDiscount).toList()
      ..sort((a, b) => b.discountPercent.compareTo(a.discountPercent));
    final activeOrder = context
        .watch<OrdersProvider>()
        .activeOrders
        .firstOrNull;
    final p = RoniPalette.of(context);

    return Scaffold(
      backgroundColor: p.bg,
      body: RefreshIndicator(
        onRefresh: catalog.load,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _HeaderDelegate(
                topInset: MediaQuery.paddingOf(context).top,
                unread: unread,
                category: catalog.category,
                onCategory: (c) {
                  setState(() => _shown = _pageSize);
                  catalog.selectCategory(c);
                },
              ),
            ),
            const SliverToBoxAdapter(
              child: RoniFadeSlide(child: _PromoCarousel()),
            ),
            if (activeOrder != null)
              SliverToBoxAdapter(
                child: RoniFadeSlide(
                  delay: const Duration(milliseconds: 20),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: _LiveOrderStrip(order: activeOrder),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: RoniFadeSlide(
                delay: const Duration(milliseconds: 40),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: _GivesPill(
                    onTap: () =>
                        Navigator.pushNamed(context, BoutiqueRoutes.gives),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: RoniFadeSlide(
                delay: const Duration(milliseconds: 70),
                child: _TrustRow(
                  onTap: () =>
                      Navigator.pushNamed(context, BoutiqueRoutes.how),
                ),
              ),
            ),
            if (flash.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: RoniFadeSlide(
                  delay: const Duration(milliseconds: 90),
                  child: _SectionHead(
                    title: 'داشکاندنی خێرا',
                    leading: const RoniPulse(
                      minScale: .8,
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 22,
                        color: BoutiqueColors.rose,
                      ),
                    ),
                    trailing: const _MidnightTimer(),
                    actionLabel: 'هەمووی',
                    onAction: () =>
                        Navigator.pushNamed(context, BoutiqueRoutes.deals),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: RoniFadeSlide(
                  delay: const Duration(milliseconds: 120),
                  child: SizedBox(
                    height: 186,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: flash.length.clamp(0, 10),
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _FlashCard(
                        product: flash[i],
                        onTap: () => _openProduct(context, flash[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(
              child: RoniFadeSlide(
                delay: Duration(milliseconds: 140),
                child: _SectionHead(title: 'بۆ تۆ'),
              ),
            ),
            SliverToBoxAdapter(
              child: RoniFadeSlide(
                delay: const Duration(milliseconds: 160),
                child: SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _Chip(
                        label: 'فلتەر',
                        roniIcon: RoniIconKind.filter,
                        selected: false,
                        onTap: () =>
                            context.read<BoutiqueNavProvider>().switchTab(1),
                      ),
                      for (final chip in _chips)
                        _Chip(
                          label: chip.label,
                          selected: catalog.sort == chip.sort,
                          onTap: () {
                            setState(() => _shown = _pageSize);
                            catalog.setSort(chip.sort);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (feed.isEmpty && catalog.loading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: ResponsiveProductGrid(
                    textScale: MediaQuery.textScalerOf(context).scale(1),
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => const RoniProductSkeleton(),
                    childCount: 6,
                  ),
                ),
              )
            else if (feed.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'هیچ کاڵایەک لەم بەشەدا نییە',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      color: p.muted,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: ResponsiveProductGrid(
                    textScale: MediaQuery.textScalerOf(context).scale(1),
                  ),
                  delegate: SliverChildBuilderDelegate((context, i) {
                    final product = feed[i];
                    final wishlist = context.watch<WishlistProvider>();
                    return RoniFadeSlide(
                      delay: Duration(milliseconds: 30 * (i % 6)),
                      child: ProductCard(
                        product: product,
                        isWishlisted: wishlist.contains(product.id),
                        onTap: () => _openProduct(context, product),
                        onToggleWishlist: () => wishlist.toggle(product),
                        onAddToBag: () => _addToCart(context, product),
                      ),
                    );
                  }, childCount: feed.length.clamp(0, _shown)),
                ),
              ),
            if (feed.length > _shown)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: OutlinedButton(
                      onPressed: () => setState(() => _shown += _pageSize),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        side: BorderSide(color: p.line),
                        foregroundColor: p.fg,
                        backgroundColor: p.surface,
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('کاڵای زیاتر'),
                    ),
                  ),
                ),
              )
            else if (feed.isNotEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: TextButton(
                    onPressed: () => _browse(context),
                    child: const Text('هەموو کاڵاکان ببینە'),
                  ),
                ),
              ),
            if (recent.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: RoniCard(
                    onTap: () => Navigator.pushNamed(
                      context,
                      BoutiqueRoutes.recentlyViewed,
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.history_rounded,
                          color: BoutiqueColors.dustyPink,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'بینیوەی دوایی',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${recent.length} بەرهەم',
                                style: const TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  color: BoutiqueColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_left_rounded,
                          size: 20,
                          color: BoutiqueColors.dustyPink,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ Header

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.topInset,
    required this.unread,
    required this.category,
    required this.onCategory,
  });

  final double topInset;
  final int unread;
  final String category;
  final ValueChanged<String> onCategory;

  static const _height = 116.0;

  @override
  double get minExtent => _height + topInset;
  @override
  double get maxExtent => _height + topInset;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlaps,
  ) => DecoratedBox(
    decoration: const BoxDecoration(gradient: BoutiqueColors.headerGradient),
    child: Column(
      children: [
        SizedBox(height: topInset),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              const _Wordmark(),
              const SizedBox(width: 10),
              Expanded(
                child: Material(
                  color: BoutiqueColors.white,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        Navigator.pushNamed(context, BoutiqueRoutes.search),
                    child: const SizedBox(
                      height: 40,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            RoniIcon(
                              RoniIconKind.search,
                              size: 18,
                              color: BoutiqueColors.muted,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'عەبا، کەتڵی، گوێگر...',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 14,
                                  color: BoutiqueColors.muted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _BellButton(
                unread: unread,
                onPressed: () =>
                    Navigator.pushNamed(context, BoutiqueRoutes.notifications),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in BoutiqueConstants.categories)
                _HeaderTab(
                  label: c,
                  selected: c == category,
                  onTap: () => onCategory(c),
                ),
            ],
          ),
        ),
      ],
    ),
  );

  @override
  bool shouldRebuild(_HeaderDelegate old) =>
      old.unread != unread ||
      old.category != category ||
      old.topInset != topInset;
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onPressed});
  final int unread;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        onPressed: onPressed,
        tooltip: 'ئاگادارکردنەوەکان',
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: .16),
          shape: const CircleBorder(),
        ),
        icon: const RoniIcon(
          RoniIconKind.bell,
          size: 21,
          color: Colors.white,
        ),
      ),
      if (unread > 0)
        const PositionedDirectional(
          top: 6,
          end: 8,
          child: RoniPulse(
            child: SizedBox.square(
              dimension: 8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BoutiqueColors.logoMark,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _HeaderTab extends StatelessWidget {
  const _HeaderTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    button: true,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected
                    ? Colors.white
                    : Colors.white.withValues(alpha: .78),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: selected ? 18 : 0,
              decoration: BoxDecoration(
                color: BoutiqueColors.logoMark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) => const RonixLogo(size: 36);
}


// ---------------------------------------------------------------- Carousel

class _PromoCarousel extends StatefulWidget {
  const _PromoCarousel();

  @override
  State<_PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<_PromoCarousel> {
  static const _slideCount = 4;
  final _controller = PageController();
  Timer? _auto;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _restartAuto();
  }

  /// Advances every 4s; any swipe restarts the countdown so the user is
  /// never fought for control.
  void _restartAuto() {
    _auto?.cancel();
      // HTML auto-advances the banner every 4.5s.
      _auto = Timer.periodic(const Duration(milliseconds: 4500), (_) {
      if (!mounted || !_controller.hasClients) return;
      _controller.animateToPage(
        (_page + 1) % _slideCount,
        duration: const Duration(milliseconds: 550),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _auto?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _Slide(
        colors: const [Color(0xFFE8334A), Color(0xFFFF7A45)],
        title: 'ڕۆژی Roni',
        body: 'بۆ هەموو شارەکانی کوردستان',
        cta: 'بیبینە',
        big: '-70%',
        onTap: () => Navigator.pushNamed(context, BoutiqueRoutes.deals),
      ),
      _Slide(
        colors: const [Color(0xFF17130D), Color(0xFF5A4520)],
        title: 'داشکاندنی خێرا',
        body: 'تا کۆتایی ڕۆژ، تەنها لە فرۆشیارە پشتڕاستکراوەکان',
        cta: 'بیبینە',
        big: '-20%',
        onTap: () => Navigator.pushNamed(context, BoutiqueRoutes.deals),
      ),
      _Slide(
        colors: const [Color(0xFF17130D), Color(0xFF5A4520)],
        title: 'یەکەم گەیاندنت بێبەرامبەرە',
        body: 'پارە تەنها کاتێک دەدەیت کە کاڵاکەت وەرگرت',
        cta: 'دەست پێبکە',
        onTap: () => context.read<BoutiqueNavProvider>().switchTab(1),
      ),
      _Slide(
        colors: const [
          Color(0xFF1A140A),
          Color(0xFF5A4018),
          Color(0xFF8A6416),
        ],
        title: 'Ronix کۆبکەرەوە',
        body: 'مەزادی ئەم هەفتەیە: تەلەفزیۆنی ٥٥ ئینچ',
        cta: 'بەشداری بکە',
        coin: true,
        onTap: () => context.read<BoutiqueNavProvider>().switchTab(2),
      ),
    ];
    return Column(
      children: [
        SizedBox(
          height:
              182 +
              40 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 1),
          child: NotificationListener<UserScrollNotification>(
            onNotification: (_) {
              _restartAuto();
              return false;
            },
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                for (final (i, s) in slides.indexed)
                  AnimatedScale(
                    scale: i == _page ? 1 : .94,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutCubic,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                      child: RoniPressable(scale: .98, child: s),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < slides.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _page ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _page
                      ? RoniPalette.of(context).fg
                      : RoniPalette.of(context).line,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.colors,
    required this.title,
    required this.body,
    required this.cta,
    required this.onTap,
    this.big,
    this.coin = false,
  });
  final List<Color> colors;
  final String title, body, cta;
  final String? big;
  final bool coin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ),
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Flexible: on tiny screens / large text the title gives up
              // its second line instead of overflowing the slide.
              Flexible(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 20,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: .92),
                ),
              ),
              const SizedBox(height: 10),
              Material(
                color: Colors.white,
                shape: const StadiumBorder(),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const StadiumBorder(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Text(
                      cta,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: BoutiqueColors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (big != null)
          Text(
            big!,
            textDirection: TextDirection.ltr,
            style: const TextStyle(
              fontSize: 42,
              height: 1,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        if (coin)
          const RonixCoin(size: 96),
      ],
    ),
  );
}

// ------------------------------------------------------- Gives + trust row

class _GivesPill extends StatelessWidget {
  const _GivesPill({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Material(
      color: p.surface,
      shape: StadiumBorder(side: BorderSide(color: p.line)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 12, 6),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: p.saleSoft,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: RoniIcon(
                    RoniIconKind.heartFill,
                    size: 14,
                    color: p.sale,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Roni Gives',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.fg,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: 0.62,
                    minHeight: 5,
                    backgroundColor: p.saleSoft,
                    color: p.sale,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '٦٢٪',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.sale,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.onTap});
  final VoidCallback onTap;

  static const _items = <(RoniIconKind, String)>[
    (RoniIconKind.shieldCheck, 'فرۆشیاری پشتڕاستکراو'),
    (RoniIconKind.cash, 'پارەدان لە کاتی گەیاندن'),
    (RoniIconKind.camera, 'وێنەی ڕاستەقینەی کاڵاکەت'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                for (final (icon, label) in _items)
                  Expanded(
                    child: Row(
                      children: [
                        RoniIcon(icon, size: 17, color: p.ok),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: p.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveOrderStrip extends StatelessWidget {
  const _LiveOrderStrip({required this.order});
  final BoutiqueOrder order;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.pushNamed(
          context,
          BoutiqueRoutes.orderTracking,
          arguments: order,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: p.sale,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: p.saleSoft,
                      blurRadius: 0,
                      spreadRadius: 4,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${order.statusLabel} · ${order.id}',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: p.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.estimatedTime.isNotEmpty
                          ? order.estimatedTime
                          : 'داواکارییەکەت لە ڕێگادایە',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left_rounded, color: p.muted),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------ Flash deals

class _SectionHead extends StatelessWidget {
  const _SectionHead({
    required this.title,
    this.leading,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
    child: Row(
      children: [
        // Title group takes all free width so it only ellipsizes when the
        // row is truly full (a Spacer would claim half of it).
        Expanded(
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 4)],
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: BoutiqueColors.charcoal,
                  ),
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: BoutiqueColors.dustyPink,
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              actionLabel!,
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    ),
  );
}

/// Counts down to local midnight, when the day's flash deals roll over.
class _MidnightTimer extends StatefulWidget {
  const _MidnightTimer();

  @override
  State<_MidnightTimer> createState() => _MidnightTimerState();
}

class _MidnightTimerState extends State<_MidnightTimer> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final left = DateTime(now.year, now.month, now.day + 1).difference(now);
    String two(int n) => n.toString().padLeft(2, '0');
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.ltr,
      children: [
        for (final (i, part) in [
          left.inHours,
          left.inMinutes % 60,
          left.inSeconds % 60,
        ].indexed)
          RoniBump(
            trigger: i == 2 ? part : null,
            peak: 1.12,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: BoutiqueColors.rose,
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                two(part),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FlashCard extends StatelessWidget {
  const _FlashCard({required this.product, required this.onTap});
  final BoutiqueProduct product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return RoniPressable(
      child: SizedBox(
        width: 120,
        child: Material(
          color: p.surface,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: ColoredBox(
                            color: Color.alphaBlend(
                              product.accent.withValues(alpha: .16),
                              p.soft,
                            ),
                            child: product.imageUrl?.isNotEmpty == true
                                ? ProductArtwork(product: product)
                                : Center(
                                    child: ProductArt(
                                      kind: ProductArt.fromKey(product.art),
                                      size: 70,
                                    ),
                                  ),
                          ),
                        ),
                        PositionedDirectional(
                          start: 4,
                          top: 4,
                          child: SaleBadge(percent: product.discountPercent),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product.formatAmount(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: p.sale,
                    ),
                  ),
                  Text(
                    product.formatAmount(product.oldPrice!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 11.5,
                      color: p.muted,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.roniIcon,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final RoniIconKind? roniIcon;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final fg = selected ? p.bg : p.fg;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: RoniPressable(
        scale: .94,
        child: Material(
          animationDuration: const Duration(milliseconds: 220),
          color: selected ? p.fg : p.surface,
          shape: StadiumBorder(
            side: BorderSide(color: selected ? p.fg : p.line),
          ),
          child: InkWell(
            onTap: onTap,
            customBorder: const StadiumBorder(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (roniIcon != null) ...[
                    RoniIcon(roniIcon!, size: 15, color: fg),
                    const SizedBox(width: 5),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
