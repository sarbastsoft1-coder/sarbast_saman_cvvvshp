import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/challenges_provider.dart';
import '../../widgets/store_components.dart';
import 'roni_components.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  /// End of the current challenge window. Anchored to the provider's day
  /// count when the screen opens, then counted down live.
  late final DateTime _endsAt;

  @override
  void initState() {
    super.initState();
    final days = context.read<ChallengesProvider>().daysLeft;
    _endsAt = DateTime.now().add(Duration(days: days < 0 ? 0 : days));
  }

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final challenges = context.watch<ChallengesProvider>();
    final done = challenges.completedCount;
    final total = challenges.items.length;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('چالنجەکانی هەفتە'),
        actions: [
          IconButton(
            tooltip: 'جزدانی Ronix',
            onPressed: () =>
                Navigator.pushNamed(context, BoutiqueRoutes.coins),
            icon: const Icon(Icons.monetization_on_outlined),
            constraints: const BoxConstraints(
              minWidth: BoutiqueTokens.tapTarget,
              minHeight: BoutiqueTokens.tapTarget,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          BoutiqueTokens.gutter,
          BoutiqueTokens.md,
          BoutiqueTokens.gutter,
          BoutiqueTokens.xxxl,
        ),
        children: [
          RoniSurfaceCard(
            color: p.soft,
            borderColor: p.gold.withValues(alpha: .35),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$done لە $total تەواوە',
                        style: BoutiqueTokens.title4.copyWith(
                          fontFamily: BoutiqueTokens.fontFamily,
                          color: p.fg,
                        ),
                      ),
                    ),
                    RoniCountdown(
                      endsAt: _endsAt,
                      expiredLabel: 'تەواو بوو',
                      style: BoutiqueTokens.label.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.gold,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: BoutiqueTokens.md),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : done / total,
                    minHeight: 9,
                    backgroundColor: p.line,
                    color: p.brand2,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.md),
                Text(
                  'هەموویان تەواو بکە و ${ronixAmount(30)} ی زیاد وەربگرە.',
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: BoutiqueTokens.lg),
          if (challenges.items.isEmpty)
            const SizedBox(
              height: 320,
              child: StoreEmpty(
                title: 'هیچ چالنجێک نییە',
                message: 'چالنجەکان هەفتانە نوێ دەبنەوە.',
                icon: Icons.emoji_events_outlined,
              ),
            ),
          for (final c in challenges.items)
            Padding(
              padding: const EdgeInsets.only(bottom: BoutiqueTokens.md),
              child: Opacity(
                opacity: c.done ? 0.7 : 1,
                child: RoniSurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: c.done ? p.ok : p.soft,
                              borderRadius: BorderRadius.circular(
                                c.done
                                    ? BoutiqueTokens.radiusPill
                                    : BoutiqueTokens.radiusSm,
                              ),
                            ),
                            child: Icon(
                              c.done
                                  ? Icons.check_rounded
                                  : Icons.emoji_events_outlined,
                              color: c.done ? p.bg : p.brand2,
                            ),
                          ),
                          const SizedBox(width: BoutiqueTokens.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.title,
                                  style: BoutiqueTokens.label.copyWith(
                                    fontFamily: BoutiqueTokens.fontFamily,
                                    fontWeight: FontWeight.w700,
                                    decoration: c.done
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                Text(
                                  c.done
                                      ? 'تەواو بوو'
                                      : '${c.progress} لە ${c.goal}',
                                  style: BoutiqueTokens.caption.copyWith(
                                    fontFamily: BoutiqueTokens.fontFamily,
                                    color: p.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: BoutiqueTokens.md,
                              vertical: BoutiqueTokens.xs,
                            ),
                            decoration: BoxDecoration(
                              color: c.done
                                  ? p.statusDeliveredWash
                                  : p.soft,
                              borderRadius: BorderRadius.circular(
                                BoutiqueTokens.radiusSm,
                              ),
                            ),
                            child: Text(
                              '+${ronixAmount(c.reward)}',
                              style: BoutiqueTokens.micro.copyWith(
                                fontFamily: BoutiqueTokens.fontFamily,
                                color: c.done ? p.ok : p.gold,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!c.done) ...[
                        const SizedBox(height: BoutiqueTokens.md),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: LinearProgressIndicator(
                            value: c.ratio,
                            minHeight: 8,
                            backgroundColor: p.line,
                            color: p.brand2,
                          ),
                        ),
                      ],
                      if (c.id == 'invite' && !c.done) ...[
                        const SizedBox(height: BoutiqueTokens.md),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              BoutiqueRoutes.invite,
                            ),
                            child: const Text('بانگهێشت بکە'),
                          ),
                        ),
                      ],
                      if (c.sponsored)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: BoutiqueTokens.md,
                          ),
                          child: Text(
                            'سپۆنسەر',
                            style: BoutiqueTokens.micro.copyWith(
                              fontFamily: BoutiqueTokens.fontFamily,
                              color: p.gold,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          Text(
            'چالنجەکان هەموو شەممەیەک کاتژمێر ١٠ی بەیانی نوێ دەبنەوە.',
            textAlign: TextAlign.center,
            style: BoutiqueTokens.caption.copyWith(
              fontFamily: BoutiqueTokens.fontFamily,
              color: p.muted,
            ),
          ),
        ],
      ),
    );
  }
}
