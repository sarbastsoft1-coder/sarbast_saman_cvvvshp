import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/auth_provider.dart';
import '../../providers/roni_provider.dart';
import '../../widgets/store_components.dart';
import 'roni_components.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({super.key});
  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  String _interval = 'monthly';

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final roni = context.watch<RoniProvider>();
    final member = objectOf(roni.memberships['membership']);
    final loyalty = objectOf(roni.memberships['loyalty']);
    final plans = rowsOf(roni.memberships['plans']);
    final requests = rowsOf(roni.memberships['requests']);

    return RoniPage(
      title: 'RONI Plus · ئەندامێتی',
      onRefresh: roni.refresh,
      loading: roni.loading,
      error: roni.error,
      children: [
        RoniMetric(
          'ئاستی دڵسۆزی',
          roniLevelLabel('${loyalty['level'] ?? ''}'),
          icon: Icons.workspace_premium_outlined,
        ),
        const StoreNotice(
          'ئاستی دڵسۆزی بە چالاکی بەدەست دێت. ئەندامێتی RONI Plus خزمەتگوزارییەکی پارەدانە و جیاوازە لە ئاستی دڵسۆزی.',
        ),
        if (member.isNotEmpty)
          RoniSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${objectOf(member['plan'])['name'] ?? member['plan_name'] ?? 'RONI Plus'} · ${roniStatusLabel('${member['status'] ?? ''}')}',
                  style: BoutiqueTokens.title4.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.fg,
                  ),
                ),
                Text(
                  'کۆتایی: ${member['ends_at'] ?? member['expires_at'] ?? '—'}',
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                  ),
                ),
                if (member['status'] == 'active')
                  TextButton(
                    onPressed: roni.busy
                        ? null
                        : () async {
                            if (!await confirmRoni(
                              context,
                              'کۆتایی ئەندامێتی',
                              'داواکاریی کۆتایی ئەندامێتی بنێردرێت؟',
                            )) {
                              return;
                            }
                            final ok = await roni.cancelMembership();
                            if (context.mounted) {
                              roniMessage(
                                context,
                                ok
                                    ? 'دۆخی ئەندامێتی نوێکرایەوە'
                                    : roni.error ?? 'هەڵە',
                              );
                            }
                          },
                    child: const Text('کۆتایی ئەندامێتی'),
                  ),
              ],
            ),
          ),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'monthly', label: Text('مانگانە')),
            ButtonSegment(value: 'yearly', label: Text('ساڵانە')),
          ],
          selected: {_interval},
          onSelectionChanged: (value) =>
              setState(() => _interval = value.first),
        ),
        if (plans.isEmpty)
          const SizedBox(
            height: 300,
            child: StoreEmpty(
              title: 'هیچ پلانێک بەردەست نییە',
              message: 'پلانەکان کاتێک چالاک بکرێن لێرە دەردەکەون.',
              icon: Icons.workspace_premium_outlined,
            ),
          ),
        for (final plan in plans)
          RoniSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${plan['name']}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${fiatMinor(plan['${_interval}_price_minor'])} / ${_interval == 'monthly' ? 'مانگ' : 'ساڵ'}',
                  style: BoutiqueTokens.price.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.fg,
                  ),
                ),
                Text(
                  'پاداشتی شیاوی کڕین: +${_bonusPercent(plan['bonus_bps'])}% Ronix',
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                  ),
                ),
                for (final benefit in (plan['benefits'] is List
                    ? plan['benefits'] as List
                    : []))
                  Padding(
                    padding: const EdgeInsets.only(top: BoutiqueTokens.sm),
                    child: Text(
                      '✓ $benefit',
                      style: BoutiqueTokens.bodySmall.copyWith(
                        fontFamily: BoutiqueTokens.fontFamily,
                        color: p.fg,
                      ),
                    ),
                  ),
                const SizedBox(height: BoutiqueTokens.lg),
                FilledButton(
                  onPressed: roni.busy
                      ? null
                      : () async {
                          if (!context.read<AuthProvider>().isSignedIn) {
                            Navigator.pushNamed(context, BoutiqueRoutes.auth);
                            return;
                          }
                          if (!await confirmRoni(
                            context,
                            '${plan['name']} · RONI Plus',
                            '${fiatMinor(plan['${_interval}_price_minor'])}. داواکاری تۆمار دەکرێت؛ ئەندامێتی تەنها دوای پشتڕاستکردنەوەی پارەدان چالاک دەبێت.',
                          )) {
                            return;
                          }
                          final ok = await roni.requestMembership(
                            numberOf(plan['id']).toInt(),
                            _interval,
                          );
                          if (context.mounted) {
                            roniMessage(
                              context,
                              ok
                                  ? 'داواکاری تۆمارکرا؛ چاوەڕێی پشتڕاستکردنەوەی پارەدانە.'
                                  : roni.error ?? 'هەڵە',
                            );
                          }
                        },
                  child: const Text('داواکاری ئەندامێتی'),
                ),
              ],
            ),
          ),
        const StoreNotice(
          'داواکارییەکە پارە لە کارت کەم ناکاتەوە. چالاککردن پێویستی بە پشتڕاستکردنەوەی پارەدان هەیە.',
        ),
        Text(
          'داواکارییەکانم',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (requests.isEmpty)
          const SizedBox(
            height: 260,
            child: StoreEmpty(
              title: 'هیچ داواکارییەکت نییە',
              message: 'داواکاریی ئەندامێتیەکانت لێرە دەردەکەون.',
              icon: Icons.receipt_long_rounded,
            ),
          ),
        for (final request in requests)
          RoniSurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                '${objectOf(request['plan'])['name'] ?? 'RONI Plus'} · ${roniStatusLabel('${request['interval'] ?? ''}')}',
              ),
              subtitle: Text(roniStatusLabel('${request['status'] ?? ''}')),
            ),
          ),
      ],
    );
  }

  /// Bonus basis points (100 = 1%) rendered without a trailing ".0".
  String _bonusPercent(dynamic bps) {
    final value = numberOf(bps) / 100;
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}
