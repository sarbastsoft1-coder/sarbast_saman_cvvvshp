import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/auction_provider.dart';
import '../../widgets/store_components.dart';
import 'roni_components.dart';

class WinnersScreen extends StatelessWidget {
  const WinnersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final auction = context.watch<AuctionProvider>();

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: const Text('ئەنجامەکان')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BoutiqueTokens.gutter,
          BoutiqueTokens.md,
          BoutiqueTokens.gutter,
          BoutiqueTokens.xxxl,
        ),
        children: [
          RoniSurfaceCard(
            color: p.surfaceRaised,
            borderColor: p.line,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: BoutiqueTokens.md,
                        vertical: BoutiqueTokens.xs,
                      ),
                      decoration: BoxDecoration(
                        color: p.brand2,
                        borderRadius: BorderRadius.circular(
                          BoutiqueTokens.radiusSm,
                        ),
                      ),
                      child: Text(
                        'هەفتەی ڕابردوو · ئەنجام',
                        style: BoutiqueTokens.micro.copyWith(
                          fontFamily: BoutiqueTokens.fontFamily,
                          color: p.onGold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'پێنجشەممە ٩:٣٠',
                      style: BoutiqueTokens.caption.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BoutiqueTokens.lg),
                Text(
                  auction.selected?['prize_name']?.toString() ??
                      'یەک کیلۆ هەنگوینی شاخ',
                  style: BoutiqueTokens.title3.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.fg,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.md),
                Row(
                  children: [
                    Icon(Icons.emoji_events_outlined, color: p.gold),
                    const SizedBox(width: BoutiqueTokens.md),
                    Expanded(
                      child: Text(
                        'س***ن',
                        style: BoutiqueTokens.title4.copyWith(
                          fontFamily: BoutiqueTokens.fontFamily,
                          color: p.fg,
                        ),
                      ),
                    ),
                    Text(
                      'بردییەوە بە ${ronixAmount(140)}',
                      style: BoutiqueTokens.caption.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.muted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: BoutiqueTokens.lg),
          const StoreNotice('پێشنیارەکەت نەتبردەوە؟ هەموو باڵانسەکەت بۆت دەگەڕێتەوە.'),
          const SizedBox(height: BoutiqueTokens.lg),
          Text(
            'هەفتەکانی پێشوو',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: BoutiqueTokens.md),
          if (auction.auctions.isEmpty)
            const SizedBox(
              height: 280,
              child: StoreEmpty(
                title: 'هێشتا ئەنجامێک بەردەست نییە',
                message: 'کاتێک مەزادەکان تەواو بن، ئەنجامەکان لێرە دەردەکەون.',
                icon: Icons.emoji_events_outlined,
              ),
            )
          else
            RoniSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final item in auction.auctions.take(5))
                    ListTile(
                      leading: Icon(
                        Icons.emoji_events_outlined,
                        color: p.gold,
                      ),
                      title: Text(
                        '${item['title'] ?? 'مەزاد'}',
                        style: BoutiqueTokens.title4.copyWith(
                          fontFamily: BoutiqueTokens.fontFamily,
                        ),
                      ),
                      subtitle: Text(
                        '${roniStatusLabel('${item['status'] ?? ''}')} · ${item['winner_name'] ?? 'بێ براوە'}',
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: BoutiqueTokens.lg),
          const StoreNotice('وێنەی براوە تەنها بە ڕەزامەندی خۆی بڵاو دەکرێتەوە.'),
        ],
      ),
    );
  }
}
