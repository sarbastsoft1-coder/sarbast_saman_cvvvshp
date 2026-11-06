import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../models/models.dart';
import '../widgets/product_card.dart';
import '../widgets/glass_container.dart';
import '../utils/animations.dart';
import '../utils/responsive.dart';
import 'main_shell.dart';
import 'cart_screen.dart';
import '../localization/string_extension.dart';

class ExploreScreen extends StatefulWidget {
  final AppState appState;
  const ExploreScreen({super.key, required this.appState});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late String _selectedCategory;
  String _searchQuery = '';
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.appState.selectedCategory;
  }

  @override
  void didUpdateWidget(covariant ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.appState.selectedCategory != widget.appState.selectedCategory) {
      setState(() {
        _selectedCategory = widget.appState.selectedCategory;
      });
    }
  }

  List<Product> get _filteredProducts {
    var products = widget.appState.exploreProducts.isEmpty
        ? sampleProducts.toList()
        : widget.appState.exploreProducts.toList();
    if (_selectedCategory != 'all') {
      products =
          products.where((p) => p.category == _selectedCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      products = products
          .where((p) =>
              p.name.toLowerCase().contains(q) ||
              p.seller.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q))
          .toList();
    }
    return products;
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
              StaggeredItem(
                index: 0,
                child: Text(
                  'Explore Products'.tr(context),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: EarthTheme.forestGreen,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              StaggeredItem(
                index: 1,
                child: Text(
                  'Discover handcrafted goods from artisan guilds'.tr(context),
                  style: TextStyle(
                    fontSize: 14,
                    color: EarthTheme.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              StaggeredItem(
                index: 2,
                child: Focus(
                  onFocusChange: (v) => setState(() => _searchFocused = v),
                  child: AnimatedContainer(
                    duration: EarthTheme.durFast,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(EarthTheme.radiusMd),
                      border: Border.all(
                        color: _searchFocused
                            ? EarthTheme.terracotta
                            : EarthTheme.borderLight,
                        width: _searchFocused ? 1.6 : 1,
                      ),
                      boxShadow: _searchFocused
                          ? [
                              BoxShadow(
                                color: EarthTheme.terracotta
                                    .withValues(alpha: 0.18),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ]
                          : EarthTheme.subtleShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          size: 20,
                          color: _searchFocused
                              ? EarthTheme.terracotta
                              : EarthTheme.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search artisan goods, stores, materials...'.tr(context),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              fillColor: Colors.transparent,
                              filled: true,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 14),
                            ),
                            onChanged: (v) =>
                                setState(() => _searchQuery = v),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () =>
                                setState(() => _searchQuery = ''),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: EarthTheme.linenLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: EarthTheme.muted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Category pills (bouncy)
              StaggeredItem(
                index: 3,
                child: SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: sampleCategories.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final cat = sampleCategories[i];
                      return _PillCategory(
                        index: i,
                        category: cat,
                        isActive: _selectedCategory == cat.id,
                        onTap: () {
                          setState(() => _selectedCategory = cat.id);
                          widget.appState.setCategory(cat.id);
                        },
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 18),

              StaggeredItem(
                index: 4,
                child: Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        '${_filteredProducts.length} products',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: EarthTheme.muted,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const Spacer(),
                      PillBadge(
                        label: _selectedCategory == 'all'
                            ? 'ALL'
                            : _selectedCategory.toUpperCase(),
                        color: EarthTheme.terracottaSoft,
                        textColor: EarthTheme.terracotta,
                        icon: Icons.filter_list_rounded,
                      ),
                    ],
                  ),
                ),
              ),

              if (_filteredProducts.isEmpty)
                _buildEmpty()
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: Responsive.getGridCrossAxisCount(context),
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (context, i) {
                    final p = _filteredProducts[i];
                    return StaggeredItem(
                      index: i,
                      delay: const Duration(milliseconds: 50),
                      child: ProductCard(
                        product: p,
                        isFavorite:
                            widget.appState.favorites.contains(p.id),
                        terraRate: widget.appState.terraRate,
                        onToggleFav: () =>
                            widget.appState.toggleFavorite(p.id),
                        onAddToCart: () {
                          widget.appState.addToCart(p);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Text('🛒',
                                      style: TextStyle(fontSize: 18)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text('${p.name} added to cart!'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .hideCurrentSnackBar();
                                      Navigator.of(context).push(
                                        SharedAxisPageRoute(
                                          builder: (_) => CartScreen(
                                              appState: widget.appState),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      'VIEW'.tr(context),
                                      style: const TextStyle(
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
                        onTap: () => _showProductDetail(context, p),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [EarthTheme.sageLight, EarthTheme.ochreLight],
              ),
            ),
            child: const Center(
              child: Text('🔍', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No products found'.tr(context),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: EarthTheme.forestGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Try adjusting your search or category filter'.tr(context),
            style: TextStyle(
              fontSize: 13,
              color: EarthTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetailSheet(product: product, appState: widget.appState),
    );
  }
}

class _PillCategory extends StatefulWidget {
  final Category category;
  final int index;
  final bool isActive;
  final VoidCallback onTap;
  const _PillCategory({
    required this.category,
    required this.index,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_PillCategory> createState() => _PillCategoryState();
}

class _PillCategoryState extends State<_PillCategory> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _hover = true),
      onTapUp: (_) => setState(() => _hover = false),
      onTapCancel: () => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: EarthTheme.dur,
        curve: EarthTheme.curveSpring,
        transform: Matrix4.translationValues(
          0.0,
          widget.isActive || _hover ? -2.0 : 0.0,
          0.0,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: widget.isActive ? 12 : 8,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          gradient: widget.isActive
              ? const LinearGradient(
                  colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: widget.isActive ? null : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: widget.isActive
                ? Colors.transparent
                : EarthTheme.borderLight,
            width: 1.4,
          ),
          boxShadow: widget.isActive
              ? EarthTheme.terracottaGlow
              : EarthTheme.subtleShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: widget.isActive
                    ? Colors.white.withValues(alpha: 0.25)
                    : EarthTheme.categoryBg(widget.category.id),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  widget.category.icon,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              widget.category.name.tr(context),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: widget.isActive
                    ? Colors.white
                    : EarthTheme.charcoal,
                letterSpacing: 0.2,
              ),
            ),
            if (widget.isActive) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.check_rounded,
                size: 14,
                color: Colors.white,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  final Product product;
  final AppState appState;
  const _DetailSheet({required this.product, required this.appState});

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
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: EarthTheme.categoryBg(product.category),
                  borderRadius:
                      BorderRadius.circular(EarthTheme.radiusLg),
                ),
                child: Center(
                  child: Hero(
                    tag: 'product-emoji-${product.id}',
                    child: Text(product.emoji,
                        style: const TextStyle(fontSize: 92)),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: EarthTheme.forestGreen,
                  letterSpacing: -0.4,
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
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.shopping_bag_outlined,
                          size: 18),
                      label: Text('Add to Cart'.tr(context)),
                      onPressed: () {
                        appState.addToCart(product);
                        final nav = Navigator.of(context);
                        final messenger = ScaffoldMessenger.of(context);
                        nav.pop();
                        messenger.showSnackBar(
                          SnackBar(
                              content: Text('Added to cart! 🛒'.tr(context))),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GradientButton(
                      label: 'Buy Now'.tr(context),
                      icon: Icons.bolt_rounded,
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
