import 'challenges_screen.dart';
import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../models/models.dart';
import '../widgets/product_card.dart';
import '../widgets/article_card.dart';
import '../widgets/wallet_chip.dart';
import '../widgets/glass_container.dart';
import '../utils/animations.dart';
import '../utils/responsive.dart';
import 'main_shell.dart';
import 'cart_screen.dart';
import '../localization/string_extension.dart';
import 'dart:math' as math;

class HomeScreen extends StatefulWidget {
  final AppState appState;
  final void Function(int, {String? category}) onSwitchTab;

  const HomeScreen({
    super.key,
    required this.appState,
    required this.onSwitchTab,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _scrollCtrl;

  @override
  void initState() {
    super.initState();
    _scrollCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StaggeredItem(index: 0, child: _buildHeroBanner(context)),
              const SizedBox(height: 14),
              StaggeredItem(
                index: 1,
                child: Row(
                  children: [
                    Expanded(
                      child: WalletChip(
                        icon: '🪙',
                        label: 'Terra Tokens'.tr(context),
                        value: widget.appState.tokenBalance.toStringAsFixed(1),
                        bgColor: EarthTheme.ochreLight,
                        iconColor: EarthTheme.clayOchre,
                        valueColor: EarthTheme.clayOchre,
                        onTap: () => widget.onSwitchTab(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: WalletChip(
                        icon: '💵',
                        label: 'Fiat Balance'.tr(context),
                        value:
                            '\$${widget.appState.fiatBalance.toStringAsFixed(2)}',
                        bgColor: EarthTheme.sageLight,
                        iconColor: EarthTheme.sageGreen,
                        onTap: () => widget.onSwitchTab(2),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              StaggeredItem(
                index: 2,
                child: _buildSectionHeader(
                  'Categories'.tr(context),
                  () => widget.onSwitchTab(1),
                ),
              ),
              const SizedBox(height: 12),
              StaggeredItem(index: 3, child: _buildCategoriesScroll()),
              const SizedBox(height: 28),
              StaggeredItem(
                index: 4,
                child: _buildSectionHeader(
                  'Articashin'.tr(context),
                  () => _showArticlesSheet(),
                ),
              ),
              const SizedBox(height: 12),
              StaggeredItem(
                index: 5,
                child: SizedBox(
                  height: 205,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.appState.articles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 14),
                    itemBuilder: (context, i) {
                      return StaggeredItem(
                        index: i,
                        delay: const Duration(milliseconds: 80),
                        child: ArticleCard(
                          article: widget.appState.articles[i],
                          onTap: () => _showArticle(
                            context,
                            widget.appState.articles[i],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),
              StaggeredItem(index: 6, child: _buildMarketWidget()),
              const SizedBox(height: 28),
              StaggeredItem(
                index: 7,
                child: _buildSectionHeader(
                  'Featured Products'.tr(context),
                  () => widget.onSwitchTab(1),
                ),
              ),
              const SizedBox(height: 12),
              _buildFeaturedGrid(),
              const SizedBox(height: 28),
              StaggeredItem(
                index: 8,
                child: _buildSectionHeader(
                  'Eco Challenges'.tr(context),
                  () => widget.onSwitchTab(3),
                ),
              ),
              const SizedBox(height: 12),
              ..._buildChallengeList(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildChallengeList() {
    return [
      Card(
        child: ListTile(
          leading: const Icon(Icons.stars_outlined),
          title: const Text('Earn points'),
          subtitle: const Text(
            'Complete admin tasks, submit proof, and earn TERRA points.',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(title: const Text('Earn points')),
                body: ChallengesScreen(appState: widget.appState),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildFeaturedGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: Responsive.getGridCrossAxisCount(context),
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: widget.appState.featuredProducts.length,
      itemBuilder: (context, i) {
        final product = widget.appState.featuredProducts[i];
        return StaggeredItem(
          index: i,
          delay: const Duration(milliseconds: 60),
          child: ProductCard(
            product: product,
            isFavorite: widget.appState.favorites.contains(product.id),
            terraRate: widget.appState.terraRate,
            onToggleFav: () => widget.appState.toggleFavorite(product.id),
            onAddToCart: () {
              widget.appState.addToCart(product);
              _showAddedToCart(context, product);
            },
            onTap: () => _showProductDetail(context, product),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: EarthTheme.forestGreen,
            letterSpacing: -0.3,
          ),
        ),
        AnimatedLink(label: 'See all'.tr(context), onTap: onSeeAll),
      ],
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting = 'Good morning ☀️';
    String emoji = '🌱';
    if (hour >= 12 && hour < 17) {
      greeting = 'Good afternoon 🌤️';
      emoji = '🌿';
    }
    if (hour >= 17) {
      greeting = 'Good evening 🌙';
      emoji = '🌙';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: EarthTheme.heroGradient,
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        boxShadow: EarthTheme.forestGlow,
      ),
      child: Stack(
        children: [
          // Animated decorative orbs
          Positioned(
            top: -50,
            right: -40,
            child: FloatingElement(
              amplitude: 22,
              speed: 0.6,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EarthTheme.terracotta.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: 60,
            child: FloatingElement(
              amplitude: 18,
              speed: 0.9,
              rotate: 0.04,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      EarthTheme.sageGreen.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 16,
            right: 14,
            child: FloatingElement(
              amplitude: 8,
              speed: 1.3,
              rotate: 0.06,
              sway: false,
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    PulseDot(color: const Color(0xFF7BB892), size: 6),
                    const SizedBox(width: 6),
                    Text(
                      greeting.tr(context),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Welcome back,'.tr(context),
                style: const TextStyle(fontSize: 14, color: Color(0xCCFFFFFF)),
              ),
              const Text(
                'Elena!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Trade Terra tokens, support artisan guilds, and earn eco-rewards.'
                    .tr(context),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.78),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  PressScale(
                    onTap: () => widget.onSwitchTab(2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          EarthTheme.radiusSm,
                        ),
                        boxShadow: EarthTheme.terracottaGlow,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.currency_exchange_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Trade Terra'.tr(context),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  PressScale(
                    onTap: () => widget.onSwitchTab(1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(
                          EarthTheme.radiusSm,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.explore_outlined,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Browse'.tr(context),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesScroll() {
    return SizedBox(
      height: 92,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sampleCategories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = sampleCategories[i];
          return _CategoryChip(
            index: i,
            category: cat,
            onTap: () => widget.onSwitchTab(1, category: cat.id),
          );
        },
      ),
    );
  }

  Widget _buildMarketWidget() {
    final rng = math.Random(42);
    return PressScale(
      onTap: () => widget.onSwitchTab(2),
      scale: 0.99,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF233D34), Color(0xFF152721), Color(0xFF0F201B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
          boxShadow: EarthTheme.forestGlow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [EarthTheme.goldenGlow, EarthTheme.clayOchre],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Center(
                        child: Text('🪙', style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terra Token Market'.tr(context),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'TERRA / USD',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                PillBadge(
                  label: 'LIVE',
                  color: const Color(0xFF7BB892),
                  textColor: Colors.white,
                  dot: true,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${widget.appState.terraRate.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.arrow_upward_rounded,
                        size: 14,
                        color: Color(0xFF7BB892),
                      ),
                      const SizedBox(width: 2),
                      const Text(
                        '+4.20%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF7BB892),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '24h',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Animated chart
            AnimatedBarChart(
              values: List.generate(28, (i) {
                final base = 24 + math.sin(i * 0.45) * 14;
                final noise = rng.nextDouble() * 14;
                return base + noise;
              }),
              colorFor: (i, isUp) {
                return isUp
                    ? const Color(0xFF7BB892)
                    : EarthTheme.terracottaLight;
              },
              maxHeight: 64,
              duration: const Duration(milliseconds: 850),
            ),

            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
                      ),
                      borderRadius: BorderRadius.circular(EarthTheme.radiusSm),
                      boxShadow: EarthTheme.terracottaGlow,
                    ),
                    child: const Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_downward_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Buy Terra',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(EarthTheme.radiusSm),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.95),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Sell Terra',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ProductDetailSheet(product: product, appState: widget.appState),
    );
  }

  void _showArticle(BuildContext context, Article article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ArticleReaderSheet(article: article),
    );
  }

  void _showArticlesSheet() {
    widget.onSwitchTab(1);
  }

  void _showAddedToCart(BuildContext context, Product product) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: EarthTheme.forestGreen,
        content: Row(
          children: [
            const Text('🛒', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text('${product.name} added to cart!')),
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.of(context).push(
                  SharedAxisPageRoute(
                    builder: (_) => CartScreen(appState: widget.appState),
                  ),
                );
              },
              child: const Text(
                'VIEW',
                style: TextStyle(
                  color: EarthTheme.goldenGlow,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final Category category;
  final int index;
  final VoidCallback onTap;
  const _CategoryChip({
    required this.category,
    required this.index,
    required this.onTap,
  });

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.index == 0; // mock selected first one
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hover = true),
      onTapUp: (_) => setState(() => _hover = false),
      onTapCancel: () => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: EarthTheme.durFast,
        transform: Matrix4.translationValues(0.0, _hover ? -3.0 : 0.0, 0.0),
        width: 64,
        child: Column(
          children: [
            AnimatedContainer(
              duration: EarthTheme.dur,
              curve: EarthTheme.curveSpring,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? Colors.transparent : EarthTheme.borderLight,
                  width: 1.4,
                ),
                boxShadow: selected
                    ? EarthTheme.terracottaGlow
                    : EarthTheme.subtleShadow,
              ),
              child: Center(
                child: Text(
                  widget.category.icon,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.category.name.tr(context),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? EarthTheme.terracotta : EarthTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Product Detail Bottom Sheet ───
class _ProductDetailSheet extends StatelessWidget {
  final Product product;
  final AppState appState;
  const _ProductDetailSheet({required this.product, required this.appState});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: EarthTheme.warmSand,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EarthTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Hero image
              Container(
                width: double.infinity,
                height: 240,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      EarthTheme.categoryBg(product.category),
                      EarthTheme.categoryBg(
                        product.category,
                      ).withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
                  boxShadow: [
                    BoxShadow(
                      color: EarthTheme.categoryFg(
                        product.category,
                      ).withValues(alpha: 0.18),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Decorative orbs
                    Positioned(
                      top: -30,
                      left: -30,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EarthTheme.categoryFg(
                            product.category,
                          ).withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -20,
                      right: -20,
                      child: Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: EarthTheme.goldenGlow.withValues(alpha: 0.20),
                        ),
                      ),
                    ),
                    Center(
                      child: Hero(
                        tag: 'product-emoji-${product.id}',
                        child: FloatingElement(
                          amplitude: 6,
                          speed: 1.2,
                          rotate: 0.03,
                          child: Text(
                            product.emoji,
                            style: const TextStyle(fontSize: 100),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: EarthTheme.forestGreen,
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.storefront_rounded,
                    size: 14,
                    color: EarthTheme.mutedSoft,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    product.seller,
                    style: const TextStyle(
                      fontSize: 14,
                      color: EarthTheme.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: EarthTheme.mutedSoft,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: EarthTheme.clayOchre,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${product.rating}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.clayOchre,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${product.reviews} reviews)',
                    style: const TextStyle(
                      fontSize: 12,
                      color: EarthTheme.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Prices
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE3ECE5), Color(0xFFB8D4C2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          EarthTheme.radiusSm,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'USD PRICE',
                            style: TextStyle(
                              fontSize: 10,
                              color: EarthTheme.forestGreen,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: EarthTheme.forestGreen,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF7EBDD), Color(0xFFD29054)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(
                          EarthTheme.radiusSm,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TERRA PRICE',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(0xFF8B4F1E),
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '🪙 ${product.terraPrice(appState.terraRate).toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF8B4F1E),
                              letterSpacing: -0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              const Text(
                'About this piece',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: EarthTheme.forestGreen,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: const TextStyle(
                  fontSize: 14,
                  color: EarthTheme.slate,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 26),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                      label: const Text('Add to Cart'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        appState.addToCart(product);
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Text(
                                  '🛒',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text('${product.name} added to cart!'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    messenger.hideCurrentSnackBar();
                                    nav.push(
                                      SharedAxisPageRoute(
                                        builder: (_) =>
                                            CartScreen(appState: appState),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'VIEW',
                                    style: TextStyle(
                                      color: EarthTheme.goldenGlow,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GradientButton(
                      label: 'Buy Now',
                      icon: Icons.bolt_rounded,
                      height: 52,
                      onPressed: () {
                        appState.addToCart(product);
                        final nav = Navigator.of(context);
                        nav.pop();
                        nav.push(
                          SharedAxisPageRoute(
                            builder: (_) => CartScreen(appState: appState),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Article Reader Sheet ───
class _ArticleReaderSheet extends StatelessWidget {
  final Article article;
  const _ArticleReaderSheet({required this.article});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: EarthTheme.warmSand,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EarthTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  PillBadge(
                    label: article.tag.toUpperCase(),
                    color: EarthTheme.forestGreen,
                    textColor: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  PillBadge(
                    label: article.readTime,
                    color: EarthTheme.warmSandLight,
                    textColor: EarthTheme.muted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                article.title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: EarthTheme.forestGreen,
                  height: 1.2,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: EarthTheme.terracottaSoft,
                    child: Text(
                      article.author.isNotEmpty ? article.author[0] : 'A',
                      style: const TextStyle(
                        color: EarthTheme.terracotta,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        article.author,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: EarthTheme.charcoal,
                        ),
                      ),
                      Text(
                        'Curator • EarthShop',
                        style: TextStyle(
                          fontSize: 11,
                          color: EarthTheme.muted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Hero(
                tag: 'article-emoji-${article.id}',
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [EarthTheme.sageLight, EarthTheme.ochreLight],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
                  ),
                  child: Center(
                    child: Text(
                      article.emoji,
                      style: const TextStyle(fontSize: 88),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                article.body,
                style: const TextStyle(
                  fontSize: 15,
                  color: EarthTheme.slate,
                  height: 1.75,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_border, size: 18),
                      label: const Text('Bookmark'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Article bookmarked!')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share'),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share link copied!')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
