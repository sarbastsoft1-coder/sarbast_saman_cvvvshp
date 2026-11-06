import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/coins_provider.dart';
import '../../providers/roni_provider.dart';
import '../../widgets/roni_icons.dart';
import '../../widgets/store_components.dart';
import 'roni_components.dart';

class CoinsScreen extends StatelessWidget {
  const CoinsScreen({super.key});

  /// How a customer earns points. Amounts are token amounts, so they always
  /// render through [ronixAmount] — never with a currency sign.
  static final _earnRules = <(String, String)>[
    ('کڕینی تەواوکراو', 'دوای پارەدان و گەیاندن پشتڕاست دەکرێتەوە'),
    ('هەڵسەنگاندن بە وێنە', '${ronixAmount(20)} بۆ هەر داواکارییەک'),
    ('بانگهێشتی هاوڕێ', '${ronixAmount(75)} بۆ هەردووکتان'),
    ('چالنجەکانی هەفتە', 'ئەرکەکان تەواو بکە و پاداشت وەربگرە'),
    ('مەزادی کۆڕە', 'بە Ronix پێشنیار بکە — براوە خەڵات وەردەگرێت'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final coins = context.watch<CoinsProvider>();
    final charityBps = numberOf(coins.policy['charity_bps']);
    final charityShare = charityBps > 0
        ? '${(charityBps / 100).toStringAsFixed(0)}٪'
        : '—';

    return RoniPage(
      title: 'Ronix',
      onRefresh: coins.refresh,
      loading: coins.loading,
      error: coins.error,
      requiresAccount: true,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: RoniSurfaceCard(
                color: p.soft,
                borderColor: p.line,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'باڵانسی Ronix',
                      style: BoutiqueTokens.caption.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: BoutiqueTokens.md),
                    Row(
                      children: [
                        const RonixCoin(size: 36),
                        const SizedBox(width: BoutiqueTokens.md),
                        Flexible(
                          child: Text(
                            ronixAmount(coins.balance),
                            style: BoutiqueTokens.title1.copyWith(
                              fontFamily: BoutiqueTokens.fontFamily,
                              color: p.fg,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: BoutiqueTokens.lg),
            Expanded(
              child: RoniSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بەشی دەبەخشێت',
                      style: BoutiqueTokens.caption.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: BoutiqueTokens.md),
                    Text(
                      charityShare,
                      style: BoutiqueTokens.title1.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.fg,
                      ),
                    ),
                    Text(
                      'لە هەر کڕینێکدا بۆ پڕۆژەکان',
                      style: BoutiqueTokens.caption.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        RoniSurfaceCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat('بەدەستهاتوو', ronixAmount(coins.earned)),
              Container(width: 1, height: 36, color: p.line),
              _MiniStat('خەرجکراو', ronixAmount(coins.spent)),
            ],
          ),
        ),
        Text(
          'چۆن Ronix بەدەست بهێنیت',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: BoutiqueTokens.fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        RoniSurfaceCard(
          padding: const EdgeInsets.symmetric(vertical: BoutiqueTokens.xs),
          child: Column(
            children: [
              for (var i = 0; i < _earnRules.length; i++) ...[
                if (i > 0) Divider(height: 1, color: p.line),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: BoutiqueTokens.md,
                  ),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: p.soft,
                      borderRadius: BorderRadius.circular(
                        BoutiqueTokens.radiusSm,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: p.brand2,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    _earnRules[i].$1,
                    style: BoutiqueTokens.label.copyWith(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    _earnRules[i].$2,
                    style: BoutiqueTokens.caption.copyWith(
                      fontFamily: BoutiqueTokens.fontFamily,
                      color: p.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Row(
          children: [
            Expanded(
              child: GoldButton(
                label: 'مەزادی کۆڕە',
                icon: Icons.gavel_rounded,
                expand: false,
                onPressed: () =>
                    Navigator.pushNamed(context, BoutiqueRoutes.auction),
              ),
            ),
            const SizedBox(width: BoutiqueTokens.md),
            Expanded(
              child: GhostButton(
                label: 'ڕۆنی بەخشێت',
                icon: Icons.volunteer_activism_outlined,
                onPressed: () =>
                    Navigator.pushNamed(context, BoutiqueRoutes.gives),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: BoutiqueTokens.md,
          runSpacing: BoutiqueTokens.md,
          children: [
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, BoutiqueRoutes.coinShop),
              icon: const Icon(Icons.redeem_outlined),
              label: const Text('فرۆشگای Ronix'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, BoutiqueRoutes.challenges),
              icon: const Icon(Icons.emoji_events_outlined),
              label: const Text('چالنجەکان'),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, BoutiqueRoutes.orders),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('داواکاری و هەڵسەنگاندن'),
            ),
          ],
        ),
        const StoreNotice(
          'ڕۆنیکس خاڵی پاداشتی ڕۆنییە. پاداشتی کڕین دوای پارەدان و گەیاندن پشتڕاست دەکرێتەوە. گەڕاندنەوەی بەرهەم پاداشتە شیاوەکان هەڵدەوەشێنێتەوە.',
        ),
        Text('تۆماری Ronix', style: Theme.of(context).textTheme.titleLarge),
        if (coins.history.isEmpty)
          const SizedBox(
            height: 300,
            child: StoreEmpty(
              title: 'هیچ جوڵەیەک نییە',
              message: 'کاتێک پاداشت بگریت یان Ronix بەکاربهێنیت، لێرە دەردەکەوێت.',
              icon: Icons.history_rounded,
            ),
          ),
        for (final entry in coins.history)
          RoniSurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(entry.label),
              subtitle: Text(
                roniDateTime(entry.at),
                style: BoutiqueTokens.caption.copyWith(
                  fontFamily: BoutiqueTokens.fontFamily,
                  color: p.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                ronixAmount(entry.amount, signed: true),
                style: BoutiqueTokens.label.copyWith(
                  fontFamily: BoutiqueTokens.fontFamily,
                  fontWeight: FontWeight.w800,
                  color: entry.amount >= 0 ? p.ok : p.sale,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat(this.label, this.value);
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Column(
      children: [
        Text(
          value,
          style: BoutiqueTokens.price.copyWith(
            fontFamily: BoutiqueTokens.fontFamily,
            color: p.fg,
          ),
        ),
        const SizedBox(height: BoutiqueTokens.xxs),
        Text(
          label,
          style: BoutiqueTokens.caption.copyWith(
            fontFamily: BoutiqueTokens.fontFamily,
            color: p.muted,
          ),
        ),
      ],
    );
  }
}
