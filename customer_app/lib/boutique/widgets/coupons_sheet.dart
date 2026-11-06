import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/constants/boutique_constants.dart';
import '../core/theme/boutique_colors.dart';
import '../models/coupon.dart';
import '../providers/cart_provider.dart';
import 'roni_motion.dart';

/// Shows the luxury Ticket-style Promo & Voucher Bottom Sheet.
void showCouponsBottomSheet(BuildContext context) {
  showRoniSheet(
    context: context,
    builder: (_) => const CouponsBottomSheet(),
  );
}

class CouponsBottomSheet extends StatefulWidget {
  const CouponsBottomSheet({super.key});

  @override
  State<CouponsBottomSheet> createState() => _CouponsBottomSheetState();
}

class _CouponsBottomSheetState extends State<CouponsBottomSheet> {
  final TextEditingController _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final applied = cart.appliedCoupon;
    final coupons = sampleCoupons.where((c) => c.isValid).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: BoutiqueColors.cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              // Drag Handle
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: BoutiqueColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),

              // Title Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: BoutiqueColors.dustyPink.withValues(alpha: 0.18),
                      ),
                      child: const Center(
                        child: Text('🎟️', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'کۆپۆنەکانی داشکاندن',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: BoutiqueColors.charcoal,
                            ),
                          ),
                          Text(
                            'کۆدی دڵخوازت هەڵبژێرە و لە کڕینەکەتدا داشکاندن بەدەستبهێنە',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              color: BoutiqueColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: BoutiqueColors.charcoal,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Promo Input Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: BoutiqueColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: BoutiqueColors.border),
                    boxShadow: BoutiqueColors.softShadow,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 10),
                      const Icon(
                        Icons.local_offer_outlined,
                        color: BoutiqueColors.muted,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _codeCtrl,
                          textCapitalization: TextCapitalization.characters,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: BoutiqueColors.charcoal,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'کۆدی داشکاندن بنووسە...',
                            hintStyle: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 13,
                              fontWeight: FontWeight.normal,
                              color: BoutiqueColors.muted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _applyManualCode(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BoutiqueColors.dustyPink,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                        ),
                        child: const Text(
                          'کاراکردن',
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Active applied badge if any
              if (applied != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: BoutiqueColors.successGreen.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: BoutiqueColors.successGreen.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: BoutiqueColors.successGreen,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'کۆپۆنی ${applied.code} چالاکە (-${formatPrice(cart.discountAmount)})',
                            style: const TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BoutiqueColors.successGreen,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            cart.removeCoupon();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: BoutiqueColors.charcoal,
                                content: const Text(
                                  'کۆپۆنەکە لادرا',
                                  style: TextStyle(fontFamily: 'Vazirmatn'),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'لابردن',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: BoutiqueColors.rose,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Scrollable List of Voucher Tickets
              Flexible(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  shrinkWrap: true,
                  itemCount: coupons.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    final isApplied = applied?.code == coupon.code;
                    final qualifies = cart.subtotal >= coupon.minSpend;

                    return _VoucherTicketCard(
                      coupon: coupon,
                      isApplied: isApplied,
                      qualifies: qualifies,
                      cartSubtotal: cart.subtotal,
                      onApply: () {
                        final (success, msg) = cart.applyCoupon(coupon);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: success
                                ? BoutiqueColors.successGreen
                                : BoutiqueColors.rose,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            content: Text(
                              msg,
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                        if (success) {
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyManualCode(BuildContext context) {
    final text = _codeCtrl.text.trim();
    if (text.isEmpty) return;

    final cart = context.read<CartProvider>();
    final (success, msg) = cart.applyCouponCode(text);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: success
            ? BoutiqueColors.successGreen
            : BoutiqueColors.rose,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        content: Text(
          msg,
          style: const TextStyle(fontFamily: 'Vazirmatn', color: Colors.white),
        ),
      ),
    );

    if (success) {
      _codeCtrl.clear();
      Navigator.pop(context);
    }
  }
}

// -----------------------------------------------------------------------------
// STYLIZED TICKET VOUCHER CARD
// -----------------------------------------------------------------------------

class _VoucherTicketCard extends StatelessWidget {
  final BoutiqueCoupon coupon;
  final bool isApplied;
  final bool qualifies;
  final double cartSubtotal;
  final VoidCallback onApply;

  const _VoucherTicketCard({
    required this.coupon,
    required this.isApplied,
    required this.qualifies,
    required this.cartSubtotal,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: BoutiqueColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isApplied
              ? BoutiqueColors.successGreen
              : BoutiqueColors.border,
          width: isApplied ? 1.8 : 1.0,
        ),
        boxShadow: BoutiqueColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Left Emoji Badge
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: coupon.accentColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        coupon.emoji,
                        style: const TextStyle(fontSize: 26),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Center Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: coupon.accentColor.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                coupon.discountBadge,
                                style: TextStyle(
                                  fontFamily: 'Vazirmatn',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: coupon.accentColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(
                                  ClipboardData(text: coupon.code),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: BoutiqueColors.charcoal,
                                    content: Text(
                                      'کۆدی ${coupon.code} کۆپیکرا ✓',
                                      style: const TextStyle(
                                        fontFamily: 'Vazirmatn',
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  Text(
                                    coupon.code,
                                    style: const TextStyle(
                                      fontFamily: 'Vazirmatn',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      color: BoutiqueColors.charcoal,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(
                                    Icons.copy_rounded,
                                    size: 12,
                                    color: BoutiqueColors.muted,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          coupon.title,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: BoutiqueColors.charcoal,
                          ),
                        ),
                        Text(
                          coupon.description,
                          style: const TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 11,
                            color: BoutiqueColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 12,
                              color: BoutiqueColors.muted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'بەسەردەچێت: ${coupon.expiryDate}',
                              style: const TextStyle(
                                fontFamily: 'Vazirmatn',
                                fontSize: 10,
                                color: BoutiqueColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Apply / Applied Button
                  if (isApplied)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: BoutiqueColors.successGreen.withValues(
                          alpha: 0.14,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_rounded,
                            size: 14,
                            color: BoutiqueColors.successGreen,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'چالاکە',
                            style: TextStyle(
                              fontFamily: 'Vazirmatn',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: BoutiqueColors.successGreen,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: onApply,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: qualifies
                            ? BoutiqueColors.dustyPink
                            : BoutiqueColors.cream,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                          side: BorderSide(
                            color: qualifies
                                ? BoutiqueColors.dustyPink
                                : BoutiqueColors.border,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        'بەکاربهێنە',
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: qualifies
                              ? Colors.white
                              : BoutiqueColors.softCharcoal,
                        ),
                      ),
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
