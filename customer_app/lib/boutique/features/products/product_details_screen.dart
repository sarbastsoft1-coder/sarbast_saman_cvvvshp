import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/recently_viewed_provider.dart';
import '../../providers/reviews_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/product_card.dart';
import '../../widgets/product_media_gallery.dart';
import '../../widgets/store_components.dart';

class ProductDetailsScreen extends StatefulWidget {
  const ProductDetailsScreen({super.key, required this.product});
  final BoutiqueProduct product;
  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  String? _selectedSize;
  Color? _selectedColor;
  @override
  void initState() {
    super.initState();
    _selectedSize = widget.product.availableSizes.firstOrNull;
    _selectedColor = widget.product.availableColors.firstOrNull;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RecentlyViewedProvider>().track(widget.product);
    });
  }

  void _addToCart({required bool checkout}) {
    context.read<CartProvider>().add(
      widget.product,
      size: _selectedSize,
      color: _selectedColor,
    );
    if (checkout) {
      Navigator.of(context).pushNamed(BoutiqueRoutes.checkout);
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('بەرهەمەکە بۆ سەبەتە زیادکرا ✓'),
        action: SnackBarAction(
          label: 'بینینی سەبەتە',
          onPressed: () => BoutiqueRoutes.openCart(context),
        ),
      ),
    );
  }

  /// The app ships no share sheet, so sharing copies the product's name and
  /// price rather than leaving a button that does nothing.
  Future<void> _share() async {
    final product = widget.product;
    await Clipboard.setData(
      ClipboardData(
        text: '${product.name} — ${product.formatAmount(product.price)}',
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('ناوی بەرهەمەکە کۆپی کرا')));
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final wishlist = context.watch<WishlistProvider>();
    final saved = wishlist.contains(product.id);
    final cartCount = context.watch<CartProvider>().itemCount;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: BoutiqueColors.white,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              ProductMediaGallery(product: product),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      RoniIconButton(
                        icon: Icons.arrow_forward_rounded,
                        tooltip: 'گەڕانەوە',
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const Spacer(),
                      RoniIconButton(
                        icon: saved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: saved
                            ? BoutiqueColors.rose
                            : BoutiqueColors.charcoal,
                        tooltip: saved
                            ? 'لابردن لە دڵخواز'
                            : 'زیادکردن بۆ دڵخواز',
                        onPressed: () => wishlist.toggle(product),
                      ),
                      const SizedBox(width: 8),
                      RoniIconButton(
                        icon: Icons.ios_share_rounded,
                        tooltip: 'هاوبەشکردن',
                        onPressed: _share,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
          Text(product.name, style: text.headlineMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star_rounded, size: 16, color: Color(0xFFC98A00)),
              const SizedBox(width: 4),
              Text(
                product.rating.toStringAsFixed(1),
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: BoutiqueColors.charcoal,
                ),
              ),
              const SizedBox(width: 4),
              Text('(${product.reviews} هەڵسەنگاندن)', style: text.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            product.formatAmount(product.price),
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: BoutiqueColors.charcoal,
            ),
          ),
          if (product.hasDiscount) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  product.formatAmount(product.oldPrice!),
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 14,
                    color: BoutiqueColors.muted,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 8),
                SaleBadge(percent: product.discountPercent),
              ],
            ),
          ],
          const SizedBox(height: 18),
          const _TrustRow(),
          if (product.availableColors.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _SectionLabel('ڕەنگەکان'),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (var i = 0; i < product.availableColors.length; i++)
                  _ColorSwatch(
                    key: Key('color-$i'),
                    color: product.availableColors[i],
                    selected: _selectedColor == product.availableColors[i],
                    label: 'ڕەنگی ${i + 1}',
                    onTap: () => setState(
                      () => _selectedColor = product.availableColors[i],
                    ),
                  ),
              ],
            ),
          ],
          if (product.availableSizes.isNotEmpty) ...[
            const SizedBox(height: 22),
            const _SectionLabel('قەبارە'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final size in product.availableSizes)
                  _SelectChip(
                    key: Key('size-$size'),
                    label: size,
                    selected: _selectedSize == size,
                    onTap: () => setState(() => _selectedSize = size),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          RoniCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('وەسفی بەرهەم', bottom: 8),
                Text(
                  product.description,
                  style: text.bodyMedium?.copyWith(height: 1.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SpecificationsGrid(product: product),
          const SizedBox(height: 24),
          _ReviewsSection(product: product),
          const SizedBox(height: 12),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          color: BoutiqueColors.card,
          border: const Border(top: BorderSide(color: BoutiqueColors.border)),
          boxShadow: BoutiqueColors.barShadow,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  RoniIconButton(
                    icon: Icons.shopping_bag_outlined,
                    tooltip: 'سەبەتەکەم',
                    badgeCount: cartCount,
                    onPressed: () => BoutiqueRoutes.openCart(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GoldButton(
                      key: const Key('add-selected-product'),
                      label: 'زیادکردن بۆ سەبەتە',
                      icon: Icons.shopping_bag_outlined,
                      onPressed: () => _addToCart(checkout: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              GhostButton(
                label: 'ئەستێرە بکڕە',
                icon: Icons.bolt_rounded,
                height: 46,
                onPressed: () => _addToCart(checkout: true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Free delivery / official warranty / easy returns" reassurance strip.
class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) => RoniCard(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
    child: const Row(
      children: [
        _TrustItem(
          icon: Icons.local_shipping_outlined,
          label: 'گەیاندنی بەرایگان',
        ),
        _TrustDivider(),
        _TrustItem(icon: Icons.verified_outlined, label: 'گەرەنتی فەرمی'),
        _TrustDivider(),
        _TrustItem(icon: Icons.replay_rounded, label: 'گەڕاندنەوەی ئاسان'),
      ],
    ),
  );
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, size: 20, color: BoutiqueColors.goldDeep),
        const SizedBox(height: 6),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 10.5,
            height: 1.35,
            fontWeight: FontWeight.w600,
            color: BoutiqueColors.muted,
          ),
        ),
      ],
    ),
  );
}

class _TrustDivider extends StatelessWidget {
  const _TrustDivider();
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 34, color: BoutiqueColors.divider);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, {this.bottom = 10});
  final String text;
  final double bottom;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: bottom),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Vazirmatn',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: BoutiqueColors.charcoal,
      ),
    ),
  );
}

/// Round colour swatch with a gold ring when chosen.
class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    super.key,
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    child: Tooltip(
      message: label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? BoutiqueColors.gold : BoutiqueColors.border,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected
              ? Icon(
                  Icons.check,
                  size: 20,
                  color: color.computeLuminance() > .45
                      ? BoutiqueColors.charcoal
                      : BoutiqueColors.white,
                )
              : null,
        ),
      ),
    ),
  );
}

/// Size chip matching HTML `.chip` — soft green wash when selected.
class _SelectChip extends StatelessWidget {
  const _SelectChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        constraints: const BoxConstraints(minWidth: 76, minHeight: 44),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? BoutiqueColors.softPink : BoutiqueColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? BoutiqueColors.dustyPink : BoutiqueColors.line2,
            width: selected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? BoutiqueColors.primaryInk
                : BoutiqueColors.charcoal,
          ),
        ),
      ),
    ),
  );
}

class _SpecificationsGrid extends StatelessWidget {
  const _SpecificationsGrid({required this.product});
  final BoutiqueProduct product;
  @override
  Widget build(BuildContext context) {
    final items = [
      ['هاوپۆل', product.category],
      [
        'قەبارەکان',
        product.availableSizes.isEmpty
            ? 'یەک قەبارە'
            : product.availableSizes.join(' / '),
      ],
    ];
    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 64,
      ),
      itemBuilder: (_, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: BoutiqueColors.goldWash.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BoutiqueColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                items[i][1],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: BoutiqueColors.charcoal,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              items[i][0],
              style: const TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12,
                color: BoutiqueColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({required this.product});
  final BoutiqueProduct product;
  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<ReviewsProvider>().forProduct(product.id);
    final avg = context.watch<ReviewsProvider>().averageFor(product.id);
    return RoniCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: _SectionLabel('هەڵسەنگاندنەکان', bottom: 0),
              ),
              if (reviews.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      size: 16,
                      color: BoutiqueColors.gold,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      avg.toStringAsFixed(1),
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: BoutiqueColors.charcoal,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${reviews.length})',
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: BoutiqueColors.muted,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (reviews.isEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: BoutiqueColors.goldWash.withValues(alpha: .55),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: BoutiqueColors.goldDeep,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'هیچ هەڵسەنگاندنێک نییە. یەکەم کەس بە!',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 12,
                        color: BoutiqueColors.softCharcoal,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            for (final review in reviews) _ReviewTile(review: review),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.of(
                  context,
                ).pushNamed(BoutiqueRoutes.writeReview, arguments: product);
              },
              icon: const Icon(
                Icons.edit_rounded,
                color: BoutiqueColors.goldDeep,
                size: 18,
              ),
              label: const Text(
                'نووسینی هەڵسەنگاندنی تۆ',
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: BoutiqueColors.goldDeep,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: BoutiqueColors.gold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});
  final BoutiqueReview review;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: BoutiqueColors.beige.withValues(alpha: .4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: review.isUserSubmitted
              ? BoutiqueColors.gold.withValues(alpha: .5)
              : BoutiqueColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: BoutiqueColors.goldWash,
                ),
                child: Text(
                  review.name.characters.first,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: BoutiqueColors.goldDeep,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            review.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: BoutiqueColors.charcoal,
                            ),
                          ),
                        ),
                        if (review.isUserSubmitted) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BoutiqueColors.goldWash,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'تۆ',
                              style: TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: BoutiqueColors.goldDeep,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Text(
                      review.date,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 11,
                        color: BoutiqueColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(
                  review.rating.round(),
                  (_) => const Icon(
                    Icons.star_rounded,
                    size: 14,
                    color: BoutiqueColors.gold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              color: BoutiqueColors.softCharcoal,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
