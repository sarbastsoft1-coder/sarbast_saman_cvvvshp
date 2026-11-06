import '../../widgets/responsive_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/boutique_constants.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_sheet.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

/// Categories tab: category tiles on top, the filtered catalog below.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();
  bool _showAllCategories = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Curated categories plus any extra category already present in the
  /// catalog — surfaced by the "more categories" control.
  List<String> _categories(CatalogProvider catalog) {
    final categories = BoutiqueConstants.categories.toList();
    if (_showAllCategories) {
      final known = categories.toSet();
      final extra =
          catalog.products
              .map((p) => p.category)
              .where((c) => c.isNotEmpty && !known.contains(c))
              .toSet()
              .toList()
            ..sort();
      categories.addAll(extra);
    }
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final palette = RoniPalette.of(context);
    return Scaffold(
      backgroundColor: palette.bg,
      body: SafeArea(
        bottom: false,
        child: Consumer<CatalogProvider>(
          builder: (context, catalog, _) {
            final items = catalog.filter(catalog.products);
            final categories = _categories(catalog);
            // Keep the field aligned with the provider when the query is
            // cleared elsewhere (chips, filter sheet, other tabs). Done after
            // the frame so the text controller is never mutated mid-build.
            if (_search.text != catalog.query) {
              final query = catalog.query;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _search.value = TextEditingValue(
                  text: query,
                  selection: TextSelection.collapsed(offset: query.length),
                );
              });
            }
            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: catalog.loading
                              ? const LinearProgressIndicator(
                                  minHeight: 2,
                                  backgroundColor: BoutiqueColors.divider,
                                )
                              : catalog.error == null
                              ? const SizedBox.shrink()
                              : Text(
                                  catalog.error!,
                                  style: const TextStyle(
                                    fontFamily: 'Vazirmatn',
                                    fontSize: 12,
                                    color: BoutiqueColors.rose,
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        RoniIconButton(
                          icon: Icons.refresh_rounded,
                          tooltip: 'نوێکردنەوە',
                          onPressed: catalog.loading ? null : catalog.load,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'بەشەکان',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                    child: Row(
                      children: [
                        const Spacer(),
                        RoniIconButton(
                          icon: Icons.search_rounded,
                          tooltip: 'گەڕان',
                          onPressed: () => Navigator.pushNamed(
                            context,
                            BoutiqueRoutes.search,
                          ),
                        ),
                        const SizedBox(width: 8),
                        RoniIconButton(
                          icon: Icons.tune_rounded,
                          tooltip: 'فلتەر و ڕیزکردن',
                          onPressed: () => _showFilters(context),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: RoniSearchField(
                      controller: _search,
                      hint: 'بگەڕێ لە بەشەکان',
                      onChanged: catalog.setQuery,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 180,
                          mainAxisExtent: 132,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final category = categories[i];
                      final selected = catalog.category == category;
                      return RoniFadeSlide(
                        delay: Duration(milliseconds: 30 * (i % 8)),
                        child: RoniCard(
                          padding: const EdgeInsets.all(10),
                          radius: 20,
                          borderColor: selected
                              ? BoutiqueColors.gold
                              : BoutiqueColors.border,
                          onTap: () => catalog.selectCategory(category),
                          child: Column(
                            children: [
                              Expanded(
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: selected
                                        ? BoutiqueColors.goldGradient
                                        : BoutiqueColors.goldWashGradient,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      _categoryIcon(i),
                                      size: 26,
                                      color: selected
                                          ? BoutiqueColors.ink
                                          : BoutiqueColors.goldDeep,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 12,
                                  fontWeight: selected
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: selected
                                      ? BoutiqueColors.dustyPink
                                      : BoutiqueColors.charcoal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }, childCount: categories.length),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${items.length} بەرهەم',
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              color: BoutiqueColors.muted,
                            ),
                          ),
                        ),
                        if (catalog.hasFilters)
                          TextButton(
                            onPressed: catalog.clearFilters,
                            child: const Text(
                              'پاککردنەوەی فلتەرەکان',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 12.5,
                                color: BoutiqueColors.dustyPink,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: items.isEmpty && catalog.loading
                      ? SliverGrid(
                          gridDelegate: ResponsiveProductGrid(
                            textScale: MediaQuery.textScalerOf(
                              context,
                            ).scale(1),
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => const RoniProductSkeleton(),
                            childCount: 6,
                          ),
                        )
                      : items.isEmpty
                      ? const SliverToBoxAdapter(child: _EmptyState())
                      : SliverGrid(
                          gridDelegate: ResponsiveProductGrid(
                            textScale: MediaQuery.textScalerOf(
                              context,
                            ).scale(1),
                          ),
                          delegate: SliverChildBuilderDelegate((context, i) {
                            final p = items[i];
                            final wishlist = context.watch<WishlistProvider>();
                            return RoniFadeSlide(
                              delay: Duration(milliseconds: 35 * (i % 8)),
                              child: ProductCard(
                                product: p,
                                isWishlisted: wishlist.contains(p.id),
                                onTap: () => openProductDetail(context, p),
                                onToggleWishlist: () => wishlist.toggle(p),
                                onAddToBag: () {
                                  context.read<CartProvider>().add(p);
                                  showRoniToast(
                                    context,
                                    'خرایە ناو سەبەتە',
                                  );
                                },
                              ),
                            );
                          }, childCount: items.length),
                        ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
                    child: GhostButton(
                      height: 50,
                      icon: _showAllCategories
                          ? Icons.unfold_less_rounded
                          : Icons.grid_view_rounded,
                      label: _showAllCategories
                          ? 'نمایشی پۆلەکانی سەرەکی'
                          : 'پۆلەکانی زیاتر',
                      onPressed: () => setState(
                        () => _showAllCategories = !_showAllCategories,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Icon for the nth category tile, in the curated category order.
  static IconData _categoryIcon(int index) => const [
    Icons.grid_view_rounded,
    Icons.shopping_bag_outlined,
    Icons.checkroom_rounded,
    Icons.roller_skating_outlined,
    Icons.spa_outlined,
    Icons.diamond_outlined,
    Icons.dry_cleaning_outlined,
  ][index % 7];

  static void _showFilters(BuildContext context) {
    showRoniSheet(
      context: context,
      builder: (_) => const _FiltersSheet(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: BoutiqueColors.goldWash,
          ),
          child: const Icon(
            Icons.search_off_rounded,
            size: 40,
            color: BoutiqueColors.dustyPink,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'هیچ بەرهەمێک نەدۆزرایەوە',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        const Text(
          'فلتەرەکان بگۆڕە یان وشەیەکی تر بەکاربهێنە',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 13,
            color: BoutiqueColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  late RangeValues _priceRange;

  @override
  void initState() {
    super.initState();
    _priceRange = context.read<CatalogProvider>().priceRange;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final catalog = context.watch<CatalogProvider>();
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: 20 + media.viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: BoutiqueColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: BoutiqueColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'فلتەر و ڕیزکردن',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 18),
              const _FilterLabel('هاوپۆل'),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: BoutiqueConstants.categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final c = BoutiqueConstants.categories[i];
                    return CategoryChip(
                      label: c,
                      isSelected: catalog.category == c,
                      onTap: () => catalog.selectCategory(c),
                    );
                  },
                ),
              ),
              const SizedBox(height: 18),
              const _FilterLabel('نرخ'),
              RangeSlider(
                values: _priceRange,
                min: 0,
                max: 150000,
                divisions: 30,
                activeColor: BoutiqueColors.dustyPink,
                inactiveColor: BoutiqueColors.dustyPink.withValues(alpha: 0.18),
                labels: RangeLabels(
                  formatPrice(_priceRange.start),
                  formatPrice(_priceRange.end),
                ),
                onChanged: (v) {
                  setState(() => _priceRange = v);
                  context.read<CatalogProvider>().setPriceRange(v);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatPrice(_priceRange.start),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: BoutiqueColors.muted,
                    ),
                  ),
                  Text(
                    formatPrice(_priceRange.end),
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      color: BoutiqueColors.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _FilterLabel('ڕیزبەندی'),
              ...BoutiqueConstants.sortOptions.map((o) {
                final selected = catalog.sort == o['key'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: RoniCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    radius: 16,
                    shadow: false,
                    color: selected
                        ? BoutiqueColors.goldWash
                        : BoutiqueColors.cream,
                    borderColor: selected
                        ? BoutiqueColors.dustyPink
                        : BoutiqueColors.border,
                    onTap: () => catalog.setSort(o['key']!),
                    child: Row(
                      children: [
                        Icon(
                          selected
                              ? Icons.radio_button_checked_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 20,
                          color: selected
                              ? BoutiqueColors.dustyPink
                              : BoutiqueColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          o['label']!,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? BoutiqueColors.dustyPink
                                : BoutiqueColors.charcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      height: 50,
                      label: 'پاککردنەوە',
                      onPressed: () {
                        catalog.clearFilters();
                        setState(
                          () => _priceRange = const RangeValues(0, 150000),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: GoldButton(
                      height: 50,
                      label: 'پیشاندانی ئەنجامەکان',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterLabel extends StatelessWidget {
  final String text;
  const _FilterLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: BoutiqueColors.softCharcoal,
        ),
      ),
    );
  }
}
