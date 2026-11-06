import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auction_provider.dart';
import '../../providers/coins_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/orders_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../widgets/coupons_sheet.dart';
import '../../widgets/roni_motion.dart';
import '../../widgets/store_components.dart';

/// Account tab (index 3) of the Roni shell.
///
/// The shell already insets the body from the system status bar and hosts the
/// bottom bar, so this page renders its own header and never a back arrow.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = context.watch<CustomerProvider>();
    final auth = context.watch<AuthProvider>();
    final coins = context.watch<CoinsProvider>();
    final auction = context.watch<AuctionProvider>();
    final orders = context.watch<OrdersProvider>();
    final wishlist = context.watch<WishlistProvider>();

    final accountName = auth.name ?? '';
    final displayName = customer.name.isNotEmpty
        ? customer.name
        : accountName.isNotEmpty
        ? accountName
        : 'میوانی ڕۆنی';
    final email = auth.email ?? '';
    final phone = customer.displayPhone;
    final contact = email.isNotEmpty
        ? email
        : phone.isNotEmpty
        ? phone
        : 'حسابی میوانی ڕۆنی';

    final p = RoniPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
        children: [
          RoniFadeSlide(
            child: Text(
              'هەژمار',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 4),
          RoniFadeSlide(
            delay: const Duration(milliseconds: 40),
            child: Text(
              'پڕۆفایل، داواکاری و دڵخوازەکانت لێرەن.',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12.5,
                color: p.muted,
              ),
            ),
          ),
          const SizedBox(height: 14),
          RoniFadeSlide(
            delay: const Duration(milliseconds: 70),
            child: _ProfileHeader(
              displayName: displayName,
              contact: contact,
              avatarColor: Color(customer.avatarColor),
              completion: customer.profileCompletionPercent,
              completionHint: customer.profileCompletionHint,
            ),
          ),
          const SizedBox(height: 14),
          RoniFadeSlide(
            delay: const Duration(milliseconds: 110),
            child: SizedBox(
              height: 128 + MediaQuery.textScalerOf(context).scale(60) - 60,
              child: Row(
                children: [
                  Expanded(flex: 3, child: _CoinsTile(balance: coins.balance)),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _AuctionTile(isLive: auction.isLive),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          RoniFadeSlide(
            delay: const Duration(milliseconds: 150),
            child: _MenuGroup(
              rows: [
                _MenuRow(
                  icon: Icons.receipt_long_outlined,
                  label: 'داواکارییەکانم',
                  value: '${orders.orders.length}',
                  onTap: () =>
                      Navigator.of(context).pushNamed(BoutiqueRoutes.orders),
                ),
                _MenuRow(
                  icon: Icons.favorite_border_rounded,
                  label: 'دڵخوازەکانم',
                  value: '${wishlist.count}',
                  onTap: () => BoutiqueRoutes.openWishlist(context),
                ),
                _MenuRow(
                  icon: Icons.location_on_outlined,
                  label: 'ناونیشانەکانم',
                  value: '${customer.addresses.length}',
                  onTap: () => Navigator.of(
                    context,
                  ).pushNamed(BoutiqueRoutes.addresses),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          RoniFadeSlide(
            delay: const Duration(milliseconds: 190),
            child: _MenuGroup(
            rows: [
              _MenuRow(
                icon: Icons.monetization_on_outlined,
                label: 'جزدانی ڕۆنیکس',
                value: '${coins.balance}',
                onTap: () =>
                    Navigator.of(context).pushNamed(BoutiqueRoutes.coins),
              ),
              _MenuRow(
                icon: Icons.emoji_events_outlined,
                label: 'چالنجەکانی هەفتە',
                onTap: () =>
                    Navigator.of(context).pushNamed(BoutiqueRoutes.challenges),
              ),
              _MenuRow(
                icon: Icons.card_giftcard_outlined,
                label: 'بانگهێشتی هاوڕێ',
                value: '+٧٥',
                onTap: () =>
                    Navigator.of(context).pushNamed(BoutiqueRoutes.invite),
              ),
              _MenuRow(
                icon: Icons.workspace_premium_outlined,
                label: 'RONI Plus · ئەندامێتی',
                onTap: () =>
                    Navigator.pushNamed(context, BoutiqueRoutes.membership),
              ),
              _MenuRow(
                icon: Icons.volunteer_activism_outlined,
                label: 'Roni Gives · ڕۆنی دەبەخشێت',
                onTap: () => Navigator.pushNamed(context, BoutiqueRoutes.gives),
              ),
              _MenuRow(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'نامەکان',
                onTap: () =>
                    Navigator.of(context).pushNamed(BoutiqueRoutes.chats),
              ),
              _MenuRow(
                icon: Icons.map_outlined,
                label: 'نەخشەی پەڕەکان',
                onTap: () => Navigator.pushNamed(context, BoutiqueRoutes.pages),
              ),
              _MenuRow(
                icon: Icons.local_offer_outlined,
                label: 'کۆپۆن و داشکاندن',
                onTap: () => showCouponsBottomSheet(context),
              ),
              _MenuRow(
                icon: Icons.history_rounded,
                label: 'بینیوەی دوایی',
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(BoutiqueRoutes.recentlyViewed),
              ),
            ],
            ),
          ),
          const SizedBox(height: 14),
          RoniFadeSlide(
            delay: const Duration(milliseconds: 230),
            child: _MenuGroup(
            rows: [
              _MenuRow(
                icon: Icons.notifications_none_rounded,
                label: 'ئاگادارکردنەوەکان',
                onTap: () => Navigator.of(
                  context,
                ).pushNamed(BoutiqueRoutes.notifications),
              ),
              _MenuRow(
                icon: Icons.language_rounded,
                label: 'زمان',
                value: 'کوردی',
                onTap: () =>
                    Navigator.of(context).pushNamed(BoutiqueRoutes.settings),
              ),
              _MenuRow(
                icon: Icons.verified_user_outlined,
                label: 'Roni چۆن کار دەکات',
                onTap: () =>
                    Navigator.of(context).pushNamed(BoutiqueRoutes.how),
              ),
              _MenuRow(
                icon: Icons.help_outline_rounded,
                label: 'یارمەتی و زانیاری',
                onTap: () =>
                    Navigator.of(context).pushNamed(BoutiqueRoutes.help),
              ),
              _MenuRow(
                icon: auth.isSignedIn
                    ? Icons.logout_rounded
                    : Icons.login_rounded,
                label: auth.isSignedIn ? 'چوونە دەرەوە' : 'چوونەژوورەوە',
                destructive: auth.isSignedIn,
                onTap: () {
                  if (auth.isSignedIn) {
                    context.read<AuthProvider>().signOut();
                  } else {
                    Navigator.of(context).pushNamed(BoutiqueRoutes.auth);
                  }
                },
              ),
            ],
            ),
          ),
          const SizedBox(height: 18),
          const RoniFadeSlide(
            delay: Duration(milliseconds: 270),
            child: StoreNotice(
              'زانیارییەکانت لەسەر ئەم ئەپە پاشەکەوت دەکرێن. ئەم وەشانە هەژماری ئۆنلاین و پارەدانی ڕاستەقینەی نییە.',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.contact,
    required this.avatarColor,
    required this.completion,
    required this.completionHint,
  });
  final String displayName, contact;
  final Color avatarColor;
  final int completion;
  final String? completionHint;

  void _openEdit(BuildContext context) {
    Navigator.of(context).pushNamed(BoutiqueRoutes.editProfile);
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Column(
      children: [
        RoniCard(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 12, 16),
          child: Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openEdit(context),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: avatarColor,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      displayName.isEmpty ? 'ب' : displayName.characters.first,
                      style: const TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: InkWell(
                  onTap: () => _openEdit(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: p.muted,
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              RoniIconButton(
                icon: Icons.settings_outlined,
                tooltip: 'ڕێکخستنەکان',
                onPressed: () =>
                    Navigator.of(context).pushNamed(BoutiqueRoutes.settings),
              ),
            ],
          ),
        ),
        if (completionHint != null) ...[
          const SizedBox(height: 10),
          Material(
            color: BoutiqueColors.goldWash,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: () => _openEdit(context),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 18, color: p.brand2),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        completionHint!,
                        style: TextStyle(
                          fontFamily: 'Vazirmatn',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: p.fg,
                        ),
                      ),
                    ),
                    Text(
                      '$completion٪',
                      style: TextStyle(
                        fontFamily: 'Vazirmatn',
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                        color: p.brand2,
                      ),
                    ),
                    Icon(Icons.chevron_left_rounded, color: p.muted, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Gold-gradient wallet tile — the mockup's signature coins summary.
class _CoinsTile extends StatelessWidget {
  const _CoinsTile({required this.balance});
  final int balance;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: () => Navigator.of(context).pushNamed(BoutiqueRoutes.coins),
      borderRadius: BorderRadius.circular(20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: BoutiqueColors.ink,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.borderStrong),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monetization_on_rounded,
                    size: 20,
                    color: p.gold,
                  ),
                  const Spacer(),
                  // "Open the wallet" is a forward affordance: in this RTL app
                  // it must point left, which `chevron_right` produces once
                  // Flutter mirrors it for the ambient text direction.
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: p.muted,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$balance',
                    style: const TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      color: BoutiqueColors.white,
                    ),
                  ),
                  Text(
                    'ڕۆنیکس',
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: p.muted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

/// Companion tile for the weekend auction, kept small next to the wallet.
class _AuctionTile extends StatelessWidget {
  const _AuctionTile({required this.isLive});
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return RoniCard(
    onTap: () => Navigator.of(context).pushNamed(BoutiqueRoutes.auction),
    padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.gavel_rounded,
              size: 18,
              color: p.brand2,
            ),
            const Spacer(),
            // Forward affordance — points left once mirrored for RTL.
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: p.muted,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'مەزەندانەی کۆڕە',
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: p.fg,
              ),
            ),
            const SizedBox(height: 6),
            StatusPill(
              label: isLive ? 'بەردەوامە' : 'تەواوبووە',
              tone: isLive ? StatusTone.processing : StatusTone.cancelled,
            ),
          ],
        ),
      ],
    ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.rows});
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return RoniCard(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Column(
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 68, end: 14),
              child: Divider(color: p.line, height: 1),
            ),
          rows[i],
        ],
      ],
    ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? value;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final accent = destructive ? p.sale : p.brand2;
    return RoniPressable(
      scale: .97,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: destructive
                        ? p.sale.withValues(alpha: 0.10)
                        : p.soft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: destructive ? accent : p.fg,
                    ),
                  ),
                ),
                if (value != null)
                  Text(
                    value!,
                    style: TextStyle(
                      fontFamily: 'Vazirmatn',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: p.muted,
                    ),
                  ),
                const SizedBox(width: 6),
                // "Open this row" is a forward affordance: in this RTL app it
                // must point left, which `chevron_right` produces once Flutter
                // mirrors it for the ambient text direction.
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: p.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

