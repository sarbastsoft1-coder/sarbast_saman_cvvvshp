import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/auction_provider.dart';
import '../../providers/coins_provider.dart';
import '../../providers/roni_provider.dart';
import '../../widgets/store_components.dart';
import 'roni_components.dart';

class AuctionScreen extends StatefulWidget {
  const AuctionScreen({super.key});

  @override
  State<AuctionScreen> createState() => _AuctionScreenState();
}

class _AuctionScreenState extends State<AuctionScreen> {
  int? _bidAmount;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final auction = context.watch<AuctionProvider>();
    final coins = context.watch<CoinsProvider>();
    final lot = auction.selected;
    final minBid = auction.minimumNextBid > 0 ? auction.minimumNextBid : 40;
    final amount = (_bidAmount ?? minBid).clamp(minBid, 99999);
    final endsAt = DateTime.tryParse('${lot?['ends_at']}');
    final expired = endsAt != null && !endsAt.isAfter(DateTime.now());

    return RoniPage(
      title: 'مەزاد',
      onRefresh: auction.refresh,
      loading: auction.loading,
      error: auction.error,
      children: [
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'پێشنیاردان',
                expand: false,
                onPressed: () =>
                    Navigator.pushNamed(context, BoutiqueRoutes.bid),
              ),
            ),
            const SizedBox(width: BoutiqueTokens.md),
            Expanded(
              child: GhostButton(
                label: 'ئەنجامەکان',
                expand: false,
                onPressed: () =>
                    Navigator.pushNamed(context, BoutiqueRoutes.winners),
              ),
            ),
            const SizedBox(width: BoutiqueTokens.md),
            Expanded(
              child: GhostButton(
                label: 'چالنج',
                expand: false,
                onPressed: () =>
                    Navigator.pushNamed(context, BoutiqueRoutes.challenges),
              ),
            ),
          ],
        ),
        if (lot == null)
          const SizedBox(
            height: 320,
            child: StoreEmpty(
              title: 'ئێستا مەزەندانەیەک بەردەست نییە',
              message: 'کاتێک مەزادی نوێ دەست پێبکات، لێرە دەردەکەوێت.',
              icon: Icons.gavel_rounded,
            ),
          ),
        if (lot != null) ...[
          RoniSurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if ('${lot['image_url'] ?? ''}'.isNotEmpty)
                  Image.network(
                    '${lot['image_url']}',
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      height: 200,
                      color: p.soft,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.emoji_events_outlined,
                        size: 72,
                        color: p.brand2,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 160,
                    color: p.soft,
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.emoji_events_outlined,
                      size: 72,
                      color: p.brand2,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(BoutiqueTokens.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${lot['prize_name'] ?? lot['title']}',
                        style: BoutiqueTokens.title2.copyWith(
                          fontFamily: BoutiqueTokens.fontFamily,
                          color: p.fg,
                        ),
                      ),
                      if ('${lot['description'] ?? ''}'.isNotEmpty) ...[
                        const SizedBox(height: BoutiqueTokens.md),
                        Text(
                          '${lot['description']}',
                          style: BoutiqueTokens.bodySmall.copyWith(
                            fontFamily: BoutiqueTokens.fontFamily,
                            color: p.muted,
                          ),
                        ),
                      ],
                      const SizedBox(height: BoutiqueTokens.md),
                      Text(
                        'بەهای خەڵات: ${fiatMinor(lot['prize_value_minor'])}',
                        style: BoutiqueTokens.title4.copyWith(
                          fontFamily: BoutiqueTokens.fontFamily,
                          color: p.fg,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _FactsGrid(
            endsAt: endsAt,
            minBid: ronixAmount(minBid),
            participants: '${lot['participant_count'] ?? 0}',
            freeRonix: ronixAmount(coins.balance),
            highest: ronixAmount(numberOf(lot['highest_bid'])),
          ),
          RoniSurfaceCard(
            child: Column(
              children: [
                Text(
                  'پێشنیارەکەت',
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.outlined(
                      onPressed: amount > minBid
                          ? () => setState(() => _bidAmount = amount - 10)
                          : null,
                      icon: const Icon(Icons.remove_rounded),
                      tooltip: 'کەمکردنەوە',
                      constraints: const BoxConstraints(
                        minWidth: BoutiqueTokens.tapTarget,
                        minHeight: BoutiqueTokens.tapTarget,
                      ),
                    ),
                    const SizedBox(width: BoutiqueTokens.lg),
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
                    const SizedBox(width: BoutiqueTokens.lg),
                    IconButton.outlined(
                      onPressed: () => setState(() => _bidAmount = amount + 10),
                      icon: const Icon(Icons.add_rounded),
                      tooltip: 'زیادکردن',
                      constraints: const BoxConstraints(
                        minWidth: BoutiqueTokens.tapTarget,
                        minHeight: BoutiqueTokens.tapTarget,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BoutiqueTokens.sm),
                Text(
                  'بە ١٠ زیاد و کەم دەبێت',
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.xl),
                GoldButton(
                  label: auction.busy
                      ? 'چاوەڕێ بکە…'
                      : 'پێشنیار: ${ronixAmount(amount)}',
                  onPressed: !auction.isLive || auction.busy
                      ? null
                      : () => _placeBid(context, amount),
                ),
                if (!auction.isLive && endsAt != null) ...[
                  const SizedBox(height: BoutiqueTokens.md),
                  Text(
                    expired ? 'مەزادەکە بەسەرچووە' : 'مەزادەکە دەست نەپێکراوە',
                    textAlign: TextAlign.center,
                    style: BoutiqueTokens.caption.copyWith(
                      fontFamily: BoutiqueTokens.fontFamily,
                      color: p.sale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: BoutiqueTokens.md),
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, BoutiqueRoutes.bid),
                  child: const Text(
                    'پەڕەی تەواوی پێشنیار',
                    style: TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (lot['winner_name'] != null)
            StoreNotice('براوە: ${lot['winner_name']}'),
          const StoreNotice(
            'یاساکان: بەرزترین پێشنیاری دروست دەباتەوە. هەڵبژاردن بە هەڕەمەکی نییە. کات و باڵانس لە سێرڤەر پشتڕاست دەکرێنەوە.',
          ),
          Text(
            'پێشنیارەکانم: ${auction.myBids.length}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (auction.myBids.isEmpty)
            const SizedBox(
              height: 240,
              child: StoreEmpty(
                title: 'هیچ پێشنیارێکت نییە',
                message: 'لە خوارەوە پێشنیار بکە و خۆت بەشدار بکە.',
                icon: Icons.gavel_rounded,
              ),
            ),
          for (final bid in auction.myBids)
            RoniSurfaceCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(ronixAmount(numberOf(bid['amount']))),
                subtitle: Text(
                  roniDateTime(DateTime.tryParse('${bid['created_at']}')),
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          Text(
            'تۆماری پێشنیارەکان',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (auction.bids.isEmpty)
            const SizedBox(
              height: 240,
              child: StoreEmpty(
                title: 'هێشتا هیچ پێشنیارێک نییە',
                message: 'یەکەم پێشنیار لێرە دەردەکەوێت.',
                icon: Icons.how_to_vote_rounded,
              ),
            ),
          for (final bid in auction.bids)
            RoniSurfaceCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${bid['bidder_name'] ?? objectOf(bid['user'])['name'] ?? 'بەشداربوو'}',
                ),
                trailing: Text(ronixAmount(numberOf(bid['amount']))),
              ),
            ),
        ],
        Text(
          'مەزەندانەکان و براوەکان',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (auction.auctions.isEmpty)
          const SizedBox(
            height: 280,
            child: StoreEmpty(
              title: 'هیچ مەزەندانەیەک بەردەست نییە',
              message: 'مەزادەکان کاتێک دەست پێدەکەن لێرە دەردەکەون.',
              icon: Icons.emoji_events_outlined,
            ),
          ),
        for (final item in auction.auctions)
          RoniSurfaceCard(
            child: ListTile(
              title: Text('${item['title']}'),
              subtitle: Text(
                '${roniStatusLabel('${item['status']}')} · ${item['winner_name'] ?? ''}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => auction.refresh(id: numberOf(item['id']).toInt()),
            ),
          ),
      ],
    );
  }

  Future<void> _placeBid(BuildContext context, int amount) async {
    if (!context.read<AuthProvider>().isSignedIn) {
      Navigator.pushNamed(context, BoutiqueRoutes.auth);
      return;
    }
    if (!await confirmRoni(
      context,
      'پێشنیار: ${ronixAmount(amount)}',
      'ڕۆنیکسەکانت دەگیرێن تا پێشنیارێکی بەرزتر بکرێت. بەرزترین پێشنیاری دروست لە کاتی کۆتایی دەباتەوە.',
    )) {
      return;
    }
    if (!context.mounted) return;
    final auction = context.read<AuctionProvider>();
    final coins = context.read<CoinsProvider>();
    final ok = await auction.bid(amount);
    await coins.refresh();
    if (context.mounted) {
      roniMessage(
        context,
        ok
            ? 'پێشنیارەکەت تۆمارکرا'
            : auction.error ?? 'پێشنیارەکە قبووڵ نەکرا.',
      );
    }
  }
}

class _FactsGrid extends StatelessWidget {
  const _FactsGrid({
    required this.endsAt,
    required this.minBid,
    required this.participants,
    required this.freeRonix,
    required this.highest,
  });

  final DateTime? endsAt;
  final String minBid, participants, freeRonix, highest;

  @override
  Widget build(BuildContext context) => RoniSurfaceCard(
    child: Column(
      children: [
        Row(
          children: [
            Expanded(child: _FactCell('کۆتایی', endsAt: endsAt)),
            Expanded(child: _FactCell('کەمترین', value: minBid)),
          ],
        ),
        const SizedBox(height: BoutiqueTokens.md),
        Row(
          children: [
            Expanded(child: _FactCell('بەشداربووان', value: participants)),
            Expanded(child: _FactCell('Ronix بەردەست', value: freeRonix)),
          ],
        ),
        const SizedBox(height: BoutiqueTokens.md),
        _FactCell('بەرزترین پێشنیار', value: highest, fullWidth: true),
      ],
    ),
  );
}

class _FactCell extends StatelessWidget {
  const _FactCell(this.label, {this.value, this.endsAt, this.fullWidth = false});

  final String label;
  final String? value;
  final DateTime? endsAt;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(
        horizontal: BoutiqueTokens.lg,
        vertical: BoutiqueTokens.md,
      ),
      decoration: BoxDecoration(
        color: p.soft,
        borderRadius: BorderRadius.circular(BoutiqueTokens.radiusSm),
        border: Border.all(color: p.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: BoutiqueTokens.caption.copyWith(
              fontFamily: BoutiqueTokens.fontFamily,
              color: p.muted,
            ),
          ),
          const SizedBox(height: BoutiqueTokens.xs),
          if (endsAt != null)
            RoniCountdown(
              endsAt: endsAt,
              style: BoutiqueTokens.title4.copyWith(
                fontFamily: BoutiqueTokens.fontFamily,
                color: p.fg,
              ),
            )
          else
            Text(
              value ?? '—',
              textDirection: TextDirection.ltr,
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
