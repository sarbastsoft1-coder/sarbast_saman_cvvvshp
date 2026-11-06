import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/auction_provider.dart';
import '../../providers/coins_provider.dart';
import '../../widgets/store_components.dart';
import 'roni_components.dart';

class BidScreen extends StatefulWidget {
  const BidScreen({super.key});
  @override
  State<BidScreen> createState() => _BidScreenState();
}

class _BidScreenState extends State<BidScreen> {
  /// `null` means "not touched yet" — the screen then starts at the minimum.
  int? _amount;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final coins = context.watch<CoinsProvider>();
    final auction = context.watch<AuctionProvider>();
    final minBid = auction.minimumNextBid > 0 ? auction.minimumNextBid : 40;
    final available = coins.balance;
    final maxBid = available > minBid ? available : minBid;
    final amount = (_amount ?? minBid).clamp(minBid, maxBid);
    final after = (available - amount).clamp(0, available);
    final endsAt = DateTime.tryParse('${auction.selected?['ends_at']}');

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: const Text('پێشنیاردان')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BoutiqueTokens.gutter,
          BoutiqueTokens.md,
          BoutiqueTokens.gutter,
          BoutiqueTokens.xxxl,
        ),
        children: [
          RoniSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auction.selected?['title']?.toString() ?? 'مەزادی هەفتە',
                  style: BoutiqueTokens.title3.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.fg,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.xs),
                Row(
                  children: [
                    Text(
                      'کاتی داخستن: ',
                      style: BoutiqueTokens.caption.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.muted,
                      ),
                    ),
                    RoniCountdown(
                      endsAt: endsAt,
                      unknownLabel: 'نیزاندراوە',
                      style: BoutiqueTokens.label.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.fg,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: BoutiqueTokens.lg),
          RoniSurfaceCard(
            child: Column(
              children: [
                Text(
                  'پێشنیارەکەت',
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      onPressed: amount > minBid
                          ? () => setState(
                              () => _amount = (amount - 10).clamp(minBid, maxBid),
                            )
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                      tooltip: 'کەمکردنەوە',
                      constraints: const BoxConstraints(
                        minWidth: BoutiqueTokens.tapTarget,
                        minHeight: BoutiqueTokens.tapTarget,
                      ),
                    ),
                    const SizedBox(width: BoutiqueTokens.xl),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on_rounded,
                            color: p.gold,
                            size: 28,
                          ),
                          const SizedBox(width: BoutiqueTokens.sm),
                          Flexible(
                            child: Text(
                              ronixAmount(amount),
                              style: BoutiqueTokens.priceLarge.copyWith(
                                fontFamily: BoutiqueTokens.fontFamily,
                                color: p.fg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: BoutiqueTokens.xl),
                    IconButton.outlined(
                      onPressed: amount < maxBid
                          ? () => setState(
                              () => _amount = (amount + 10).clamp(minBid, maxBid),
                            )
                          : null,
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'زیادکردن',
                      constraints: const BoxConstraints(
                        minWidth: BoutiqueTokens.tapTarget,
                        minHeight: BoutiqueTokens.tapTarget,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BoutiqueTokens.md),
                Text(
                  'بە ١٠ زیاد و کەم دەبێت · کەمترین: ${ronixAmount(minBid)}',
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                  ),
                ),
                const Divider(height: BoutiqueTokens.xxxl),
                _kv(context, 'بەردەست ئێستا', ronixAmount(available)),
                _kv(context, 'قفڵ دەبێت تا داخستن', ronixAmount(amount)),
                _kv(context, 'دوای پێشنیار بەردەست', ronixAmount(after)),
              ],
            ),
          ),
          if (available < minBid) ...[
            const SizedBox(height: BoutiqueTokens.lg),
            const StoreNotice(
              'باڵانسەکەت بۆ ئەم مەزادە کەمە. Ronix بە کڕین و ئاستەنگ دەگەیەنەوە.',
              icon: Icons.error_outline_rounded,
            ),
          ],
          const SizedBox(height: BoutiqueTokens.lg),
          RoniSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'چۆن کار دەکات',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: BoutiqueTokens.md),
                Text(
                  '١ · هیچ کەس پێشنیارەکەت نابینێت تا داخستن.',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    height: 1.7,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  '٢ · ئەگەر بردتەوە، تەنها پێشنیاری دووەم + ١٠ دەدەیت.',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    height: 1.7,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  '٣ · ئەگەر نەتبردەوە، هەموو باڵانسەکەت دەگەڕێتەوە.',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    height: 1.7,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  '٤ · تا داخستن دەتوانیت بیگۆڕیت یان هەڵیبوەشێنیتەوە.',
                  style: TextStyle(
                    fontFamily: BoutiqueTokens.fontFamily,
                    height: 1.7,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BoutiqueTokens.xl),
          GoldButton(
            label: 'پێشنیار بنێرە · ${ronixAmount(amount)}',
            onPressed: available < amount
                ? null
                : () async {
                    final ok = await auction.bid(amount);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'پێشنیار تۆمارکرا ✓'
                              : auction.error ?? 'سەرکەوتوو نەبوو',
                        ),
                      ),
                    );
                    if (ok) Navigator.pop(context);
                  },
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'پێشنیارەکەم هەڵبوەشێنەوە',
              style: TextStyle(
                fontFamily: BoutiqueTokens.fontFamily,
                color: p.brand2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    final p = RoniPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BoutiqueTokens.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: BoutiqueTokens.caption.copyWith(
                fontFamily: BoutiqueTokens.fontFamily,
                color: p.muted,
              ),
            ),
          ),
          Text(
            v,
            style: BoutiqueTokens.title4.copyWith(
              fontFamily: BoutiqueTokens.fontFamily,
              color: p.fg,
            ),
          ),
        ],
      ),
    );
  }
}
