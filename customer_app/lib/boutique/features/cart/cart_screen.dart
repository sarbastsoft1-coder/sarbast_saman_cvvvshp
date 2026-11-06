import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/cart_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/coupons_sheet.dart';
import '../../widgets/product_card.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final p = RoniPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: cart.isEmpty
            ? StoreEmpty(
                title: 'سەبەتەکەت بەتاڵە',
                message: 'کاتێک شتێکت زیاد کرد، لێرە دەردەکەوێت.',
                icon: Icons.shopping_bag_outlined,
                action: GoldButton(
                  label: 'دەست بە کڕین بکە',
                  icon: Icons.explore_outlined,
                  expand: false,
                  onPressed: () => BoutiqueRoutes.openTab(context, 0),
                ),
              )
            : Column(
                children: [
                  RoniFadeSlide(child: _CartHeader(count: cart.itemCount)),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      children: [
                        for (var i = 0; i < cart.lines.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: RoniFadeSlide(
                              delay: Duration(milliseconds: 40 * i),
                              child: _CartLineCard(line: cart.lines[i]),
                            ),
                          ),
                        const SizedBox(height: 4),
                        RoniFadeSlide(
                          delay: Duration(
                            milliseconds: 40 * cart.lines.length,
                          ),
                          child: _CouponCard(cart: cart),
                        ),
                        const SizedBox(height: 14),
                        RoniFadeSlide(
                          delay: Duration(
                            milliseconds: 40 * (cart.lines.length + 1),
                          ),
                          child: _TotalsCard(cart: cart),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Title, item count, a way back, and "empty bag" with undo.
class _CartHeader extends StatelessWidget {
  const _CartHeader({required this.count});
  final int count;
  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          if (canPop) ...[
            RoniIconButton(
              icon: Icons.arrow_forward_rounded,
              tooltip: 'گەڕانەوە',
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: canPop
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Text(
                  'سەبەتە',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '$count بەرهەم',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              final previous = List.of(cart.lines);
              cart.clear();
              showRoniToast(
                context,
                'سەبەتەکە پاککرایەوە',
                actionLabel: 'گەڕاندنەوە',
                onAction: () {
                  for (final line in previous) {
                    cart.add(
                      line.product,
                      qty: line.quantity,
                      size: line.size,
                      color: line.color,
                    );
                  }
                },
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: BoutiqueColors.rose,
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'پاککردنەوە',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: BoutiqueColors.rose,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One line of the bag: artwork, variant, stepper, line total, wishlist heart.
class _CartLineCard extends StatelessWidget {
  const _CartLineCard({required this.line});
  final CartLine line;
  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final saved = wishlist.contains(line.product.id);
    void openProduct() => Navigator.pushNamed(
      context,
      BoutiqueRoutes.productDetails,
      arguments: line.product,
    );
    return RoniCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: openProduct,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 72,
              height: 90,
              decoration: BoxDecoration(
                color: BoutiqueColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child: ProductArtwork(product: line.product),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: openProduct,
                        child: Text(
                          line.product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: BoutiqueColors.charcoal,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: saved
                          ? 'لابردن لە دڵخواز'
                          : 'زیادکردن بۆ دڵخواز',
                      onPressed: () => wishlist.toggle(line.product),
                      icon: Icon(
                        saved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 19,
                        color: saved
                            ? BoutiqueColors.rose
                            : BoutiqueColors.muted,
                      ),
                    ),
                  ],
                ),
                if (line.variantLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (line.color != null) ...[
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: line.color,
                            shape: BoxShape.circle,
                            border: Border.all(color: BoutiqueColors.border),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          line.variantLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 10.5,
                            color: BoutiqueColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    _LineActions(line: line, cart: cart),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        line.product.formatAmount(line.subtotal),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: BoutiqueColors.charcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quantity stepper plus remove, in one compact pill.
class _LineActions extends StatelessWidget {
  const _LineActions({required this.line, required this.cart});
  final CartLine line;
  final CartProvider cart;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: BoutiqueColors.goldWash,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: BoutiqueColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          tooltip: 'کەمکردنەوەی ژمارە',
          onPressed: () => cart.decrement(line.key),
        ),
        SizedBox(
          width: 26,
          child: Text(
            '${line.quantity}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: BoutiqueColors.charcoal,
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          tooltip: 'زیادکردنی ژمارە',
          onPressed: line.quantity >= 99
              ? null
              : () => cart.increment(line.key),
        ),
        _StepButton(
          icon: Icons.delete_outline_rounded,
          tooltip: 'لابردنی بەرهەم',
          onPressed: () {
            cart.remove(line.key);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('بەرهەم لابرا'),
                action: SnackBarAction(
                  label: 'گەڕاندنەوە',
                  onPressed: () => cart.add(
                    line.product,
                    qty: line.quantity,
                    size: line.size,
                    color: line.color,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    ),
  );
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    iconSize: 17,
    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
    padding: EdgeInsets.zero,
    icon: Icon(icon, color: BoutiqueColors.charcoal),
  );
}

/// Coupon entry point backed by the existing coupon sheet.
class _CouponCard extends StatelessWidget {
  const _CouponCard({required this.cart});
  final CartProvider cart;
  @override
  Widget build(BuildContext context) {
    final coupon = cart.appliedCoupon;
    return RoniCard(
      onTap: () => showCouponsBottomSheet(context),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: BoutiqueColors.goldWash,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              size: 19,
              color: BoutiqueColors.goldDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coupon?.code ?? 'کۆپۆنی داشکاندنت هەیە؟',
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: BoutiqueColors.charcoal,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coupon?.discountBadge ?? 'کۆپۆنە بەردەستەکان ببینە',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontSize: 11,
                    color: BoutiqueColors.muted,
                  ),
                ),
              ],
            ),
          ),
          if (coupon != null)
            IconButton(
              tooltip: 'لابردنی کۆپۆن',
              onPressed: cart.removeCoupon,
              icon: const Icon(
                Icons.close,
                size: 19,
                color: BoutiqueColors.rose,
              ),
            )
          else
            const Icon(Icons.chevron_left_rounded, color: BoutiqueColors.muted),
        ],
      ),
    );
  }
}

/// Subtotal, discount, delivery and total. The arithmetic is the cart's own —
/// only the presentation changed.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.cart});
  final CartProvider cart;
  @override
  Widget build(BuildContext context) => RoniCard(
    child: Column(
      children: [
        _row('کۆی بەرهەمەکان', cart.formatAmount(cart.subtotal)),
        if (cart.discountAmount > 0)
          _row(
            'داشکاندن',
            '−${cart.formatAmount(cart.discountAmount)}',
            valueColor: BoutiqueColors.rose,
          ),
        _row(
          'گەیاندن',
          cart.effectiveDeliveryFee == 0
              ? 'بێبەرامبەر'
              : cart.formatAmount(cart.effectiveDeliveryFee),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1),
        ),
        _row('کۆی گشتی', cart.formatAmount(cart.total), bold: true),
        const SizedBox(height: 18),
        GoldButton(
          key: const Key('checkout-button'),
          label: 'تەواوکردنی داواکاری',
          icon: Icons.arrow_back_rounded,
          subtitle: cart.formatAmount(cart.total),
          onPressed: () =>
              Navigator.pushNamed(context, BoutiqueRoutes.checkout),
        ),
      ],
    ),
  );

  Widget _row(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 13,
              color: bold ? BoutiqueColors.charcoal : BoutiqueColors.muted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Vazirmatn',
            fontSize: bold ? 19 : 14,
            fontWeight: FontWeight.w800,
            color: valueColor ?? BoutiqueColors.charcoal,
          ),
        ),
      ],
    ),
  );
}
