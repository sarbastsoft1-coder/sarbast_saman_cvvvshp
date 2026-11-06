import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/coins_provider.dart';
import '../../providers/roni_provider.dart';
import '../../widgets/store_components.dart';
import 'roni_components.dart';

class CoinShopScreen extends StatelessWidget {
  const CoinShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final coins = context.watch<CoinsProvider>();

    return RoniPage(
      title: 'فرۆشگای Ronix',
      onRefresh: coins.refresh,
      loading: coins.loading,
      error: coins.error,
      requiresAccount: true,
      children: [
        RoniMetric(
          'باڵانسی بەردەست',
          ronixAmount(coins.balance),
          icon: Icons.redeem_rounded,
        ),
        if (coins.rewards.isEmpty)
          const SizedBox(
            height: 320,
            child: StoreEmpty(
              title: 'ئێستا هیچ پاداشتێک بەردەست نییە',
              message: 'کاتێک کەمپاینێکی نوێ چالاک بێت، پاداشتەکان لێرە دەردەکەون.',
              icon: Icons.card_giftcard_rounded,
            ),
          ),
        for (final reward in coins.rewards)
          RoniSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${reward['title']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if ('${reward['description'] ?? ''}'.isNotEmpty)
                  Text(
                    '${reward['description']}',
                    style: BoutiqueTokens.bodySmall.copyWith(
                      fontFamily: BoutiqueTokens.fontFamily,
                      color: p.muted,
                    ),
                  ),
                const SizedBox(height: BoutiqueTokens.md),
                Text(
                  '${ronixAmount(numberOf(reward['ronix_price']))} · کۆگا: ${reward['stock']}',
                  style: BoutiqueTokens.title4.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.fg,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.md),
                FilledButton(
                  onPressed:
                      coins.busy ||
                          numberOf(reward['stock']) <= 0 ||
                          coins.balance < numberOf(reward['ronix_price'])
                      ? null
                      : () async {
                          if (!await confirmRoni(
                            context,
                            '${reward['title']}',
                            '${ronixAmount(numberOf(reward['ronix_price']))} خەرج دەکرێت.',
                          )) {
                            return;
                          }
                          if (!context.mounted) return;
                          final ok = await coins.redeemReward(
                            numberOf(reward['id']).toInt(),
                          );
                          if (context.mounted) {
                            roniMessage(
                              context,
                              ok
                                  ? 'داواکاری پاداشت تۆمارکرا'
                                  : coins.error ?? 'تکایە دووبارە هەوڵ بدەوە.',
                            );
                          }
                        },
                  child: Text(coins.busy ? 'چاوەڕێ بکە…' : 'وەرگرتنی پاداشت'),
                ),
                if (numberOf(reward['stock']) <= 0)
                  Padding(
                    padding: const EdgeInsets.only(top: BoutiqueTokens.sm),
                    child: Text(
                      'کۆگای ئەم پاداشتە تەواوبووە.',
                      style: BoutiqueTokens.caption.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.sale,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Text(
          'تۆماری پاداشتەکان',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (coins.redemptions.isEmpty)
          const SizedBox(
            height: 280,
            child: StoreEmpty(
              title: 'هیچ پاداشتێک وەرنەگراوە',
              message: 'دوای وەرگرتن، دۆخی هەر داواکارییەک لێرە دەردەکەوێت.',
              icon: Icons.history_rounded,
            ),
          ),
        for (final row in coins.redemptions)
          RoniSurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${objectOf(row['reward'])['title'] ?? row['title'] ?? 'پاداشت #${row['id']}'}',
              ),
              subtitle: Text(
                roniStatusLabel('${row['status'] ?? ''}'),
                style: BoutiqueTokens.caption.copyWith(
                  fontFamily: BoutiqueTokens.fontFamily,
                  color: p.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                ronixAmount(
                  numberOf(row['ronix_spent'] ?? row['ronix_amount']),
                ),
                style: BoutiqueTokens.title4.copyWith(
                  fontFamily: BoutiqueTokens.fontFamily,
                  color: p.fg,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
