import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/boutique_constants.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  final _catalog = CatalogProvider();

  @override
  void dispose() {
    _query.dispose();
    _catalog.dispose();
    super.dispose();
  }

  void _clearQuery() {
    _query.clear();
    _catalog.setQuery('');
  }

  void _addToBag(BoutiqueProduct product) {
    context.read<CartProvider>().add(product);
    showRoniToast(context, 'خرایە ناو سەبەتە');
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: BoutiqueColors.white,
    appBar: AppBar(
      title: const Text('گەڕان'),
      backgroundColor: BoutiqueColors.white,
    ),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: RoniSearchField(
            key: const Key('product-search'),
            controller: _query,
            autofocus: true,
            hint: 'ناو یان هاوپۆلی بەرهەم...',
            onChanged: _catalog.setQuery,
            trailing: IconButton(
              tooltip: 'پاککردنەوەی گەڕان',
              onPressed: _clearQuery,
              iconSize: 18,
              icon: const Icon(
                Icons.close_rounded,
                color: BoutiqueColors.muted,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListenableBuilder(
            listenable: _catalog,
            builder: (context, _) {
              final products = _catalog.filter(
                context.watch<CatalogProvider>().products,
              );
              final wishlist = context.watch<WishlistProvider>();
              final showSuggestions =
                  _query.text.isEmpty &&
                  _catalog.category == BoutiqueConstants.categories.first;
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _chips.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final category = _chips[i];
                        final selected = _catalog.category == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: selected,
                          showCheckmark: false,
                          backgroundColor: BoutiqueColors.white,
                          selectedColor: BoutiqueColors.goldWash,
                          side: BorderSide(
                            color: selected
                                ? BoutiqueColors.gold
                                : BoutiqueColors.border,
                          ),
                          labelStyle: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? BoutiqueColors.goldDeep
                                : BoutiqueColors.softCharcoal,
                          ),
                          onSelected: (_) => _catalog.selectCategory(category),
                        );
                      },
                    ),
                  ),
                  if (showSuggestions) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'پێشنیاری گەڕان',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: BoutiqueColors.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final term in BoutiqueConstants.recentSearches)
                          _SuggestionChip(
                            label: term,
                            onTap: () {
                              _query.text = term;
                              _catalog.setQuery(term);
                            },
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${products.length} بەرهەم',
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            color: BoutiqueColors.muted,
                          ),
                        ),
                      ),
                      if (_catalog.hasFilters)
                        TextButton(
                          onPressed: () {
                            _query.clear();
                            _catalog.clearFilters();
                          },
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
                  const SizedBox(height: 10),
                  if (products.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 24),
                      child: StoreEmpty(
                        title: 'هیچ بەرهەمێک نەدۆزرایەوە',
                        message: 'وشەیەکی تر یان هاوپۆلێکی تر تاقی بکەرەوە.',
                        icon: Icons.search_off_rounded,
                      ),
                    )
                  else
                    for (var i = 0; i < products.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: RoniFadeSlide(
                          delay: Duration(milliseconds: 35 * (i % 10)),
                          child: SearchResultRow(
                            key: Key('search-result-${products[i].id}'),
                            product: products[i],
                            isWishlisted: wishlist.contains(products[i].id),
                            onTap: () => Navigator.pushNamed(
                              context,
                              BoutiqueRoutes.productDetails,
                              arguments: products[i],
                            ),
                            onToggleWishlist: () =>
                                wishlist.toggle(products[i]),
                            onAddToBag: () => _addToBag(products[i]),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      ],
    ),
  );

  /// "All" plus a few categories, kept short so the row stays scrollable.
  static final List<String> _chips = BoutiqueConstants.categories
      .take(5)
      .toList();
}

/// Full-width search result: artwork, name, rating, price and quick actions.
///
/// Public so widget tests can assert on the rendered products.
class SearchResultRow extends StatelessWidget {
  const SearchResultRow({
    super.key,
    required this.product,
    required this.isWishlisted,
    required this.onTap,
    required this.onToggleWishlist,
    required this.onAddToBag,
  });

  final BoutiqueProduct product;
  final bool isWishlisted;
  final VoidCallback onTap, onToggleWishlist, onAddToBag;

  @override
  Widget build(BuildContext context) => RoniCard(
    padding: const EdgeInsets.all(12),
    onTap: onTap,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 92,
            height: 112,
            child: ProductArtwork(product: product),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.category,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 11,
                  color: BoutiqueColors.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (product.rating > 0) ...[
                const SizedBox(height: 6),
                _RatingRow(rating: product.rating, reviews: product.reviews),
              ],
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  product.formatAmount(product.price),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: BoutiqueColors.charcoal,
                  ),
                ),
              ),
              if (product.hasDiscount)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          product.formatAmount(product.oldPrice!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: BoutiqueColors.muted,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SaleBadge(percent: product.discountPercent),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Column(
          children: [
            IconButton(
              tooltip: isWishlisted ? 'لابردن لە دڵخواز' : 'زیادکردن بۆ دڵخواز',
              onPressed: onToggleWishlist,
              iconSize: 20,
              style: IconButton.styleFrom(
                backgroundColor: BoutiqueColors.goldWash,
                shape: const CircleBorder(),
              ),
              icon: Icon(
                isWishlisted
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: isWishlisted
                    ? BoutiqueColors.rose
                    : BoutiqueColors.charcoal,
              ),
            ),
            const SizedBox(height: 8),
            _AddButton(onPressed: onAddToBag),
          ],
        ),
      ],
    ),
  );
}

class _RatingRow extends StatelessWidget {
  const _RatingRow({required this.rating, required this.reviews});

  final double rating;
  final int reviews;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.star_rounded, size: 16, color: BoutiqueColors.gold),
      const SizedBox(width: 4),
      Text(
        rating.toStringAsFixed(1),
        style: const TextStyle(
          fontFamily: 'Vazirmatn',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: BoutiqueColors.charcoal,
        ),
      ),
      if (reviews > 0) ...[
        const SizedBox(width: 4),
        Text(
          '($reviews)',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 11,
            color: BoutiqueColors.muted,
          ),
        ),
      ],
    ],
  );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'زیادکردن بۆ سەبەتە',
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: BoutiqueColors.goldGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: BoutiqueColors.softShadow,
          ),
          child: const SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: BoutiqueColors.white,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Soft gold suggestion pill used by the recent-search shortcuts.
class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BoutiqueColors.goldWash,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: BoutiqueColors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: BoutiqueColors.goldDeep,
            ),
          ),
        ),
      ),
    ),
  );
}
