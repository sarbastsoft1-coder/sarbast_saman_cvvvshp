import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/boutique_colors.dart';
import '../../core/theme/boutique_tokens.dart';
import '../../providers/roni_provider.dart';
import '../../widgets/store_components.dart';
import 'roni_components.dart';

class GivesScreen extends StatefulWidget {
  const GivesScreen({super.key});

  @override
  State<GivesScreen> createState() => _GivesScreenState();
}

class _GivesScreenState extends State<GivesScreen> {
  final Map<String, String> _votes = {};

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    final roni = context.watch<RoniProvider>();
    final projects = rowsOf(roni.gives['projects']);
    final contributions = rowsOf(roni.gives['contributions']);
    final hasSeasonTotal = roni.gives['total_minor'] != null;

    return RoniPage(
      title: 'ڕۆنی بەخشێت',
      onRefresh: roni.refresh,
      loading: roni.loading,
      error: roni.error,
      children: [
        RoniSurfaceCard(
          color: p.soft,
          borderColor: p.brand2.withValues(alpha: .25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'کۆی بەشداریی ئەم وەرزە',
                style: BoutiqueTokens.caption.copyWith(
                  fontFamily: BoutiqueTokens.fontFamily,
                  color: p.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: BoutiqueTokens.md),
              Text(
                hasSeasonTotal
                    ? fiatMinor(roni.gives['total_minor'])
                    : '— د.ع',
                style: BoutiqueTokens.title1.copyWith(
                  fontFamily: BoutiqueTokens.fontFamily,
                  color: p.fg,
                ),
              ),
              const SizedBox(height: BoutiqueTokens.sm),
              Text(
                '٢٥٠ دینار بۆ هەر داواکارییەکی تەواوکراو',
                style: BoutiqueTokens.bodySmall.copyWith(
                  fontFamily: BoutiqueTokens.fontFamily,
                  color: p.muted,
                ),
              ),
            ],
          ),
        ),
        const StoreNotice(
          'ڕۆنی بەشێک لە قازانجی شیاوی داواکارییە تەواوکراوەکان بۆ پڕۆژە پشکنراوەکان تەرخان دەکات. بڕەکان بەپێی سیاسەت و سنووری پڕۆژەی مانگانە پشتڕاست دەکرێنەوە.',
        ),
        Text(
          'پڕۆژەکان',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: BoutiqueTokens.fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (projects.isEmpty)
          const SizedBox(
            height: 320,
            child: StoreEmpty(
              title: 'هێشتا پڕۆژەیەک بڵاونەکراوەتەوە',
              message: 'کاتێک پڕۆژەیەکی نوێ بڵاو بکرێتەوە، لێرە دەردەکەوێت.',
              icon: Icons.volunteer_activism_outlined,
            ),
          ),
        for (final project in projects)
          RoniSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${project['title']}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if ('${project['description'] ?? ''}'.isNotEmpty) ...[
                  const SizedBox(height: BoutiqueTokens.sm),
                  Text(
                    '${project['description']}',
                    style: BoutiqueTokens.bodySmall.copyWith(
                      fontFamily: BoutiqueTokens.fontFamily,
                      color: p.muted,
                    ),
                  ),
                ],
                const SizedBox(height: BoutiqueTokens.lg),
                _SpendRow(
                  label: 'خەرجکراو',
                  value: fiatMinor(project['current_minor']),
                ),
                _SpendRow(
                  label: 'ئامانج',
                  value: fiatMinor(project['target_minor']),
                ),
                _SpendRow(
                  label: 'ڕێکخراو',
                  value:
                      '${project['organization'] ?? '—'} · ${roniStatusLabel('${project['status'] ?? ''}')}',
                ),
                const SizedBox(height: BoutiqueTokens.lg),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: numberOf(project['target_minor']) <= 0
                        ? 0
                        : (numberOf(project['current_minor']) /
                                  numberOf(project['target_minor']))
                              .clamp(0, 1)
                              .toDouble(),
                    minHeight: 8,
                    backgroundColor: p.line,
                    color: p.brand2,
                  ),
                ),
                const SizedBox(height: BoutiqueTokens.lg),
                Text(
                  'دڵخوازت بۆ ئەم مانگە',
                  style: BoutiqueTokens.caption.copyWith(
                    fontFamily: BoutiqueTokens.fontFamily,
                    color: p.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                RadioListTile<String>(
                  value: 'support',
                  groupValue: _votes['${project['id']}'] ?? 'support',
                  onChanged: (v) => setState(
                    () => _votes['${project['id']}'] = v ?? 'support',
                  ),
                  activeColor: p.brand2,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'پشتگیری ئەم پڕۆژەیە',
                    style: TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                RadioListTile<String>(
                  value: 'split',
                  groupValue: _votes['${project['id']}'] ?? 'support',
                  onChanged: (v) => setState(
                    () => _votes['${project['id']}'] = v ?? 'split',
                  ),
                  activeColor: p.brand2,
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'دابەشکردن لەنێوان هەموو پڕۆژەکان',
                    style: TextStyle(
                      fontFamily: BoutiqueTokens.fontFamily,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'بەشدارییەکانت',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (contributions.isEmpty)
          const SizedBox(
            height: 280,
            child: StoreEmpty(
              title: 'هێشتا بەشدارییەکت نییە',
              message: 'بەشدارییە پشتڕاستکراوەکانت لێرە دەردەکەون.',
              icon: Icons.favorite_border_rounded,
            ),
          ),
        for (final entry in contributions)
          RoniSurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('داواکاری #${entry['order_id']}'),
              subtitle: Text(
                '${roniStatusLabel('${entry['status'] ?? ''}')} · ${roniDateTime(DateTime.tryParse('${entry['created_at'] ?? ''}'))}',
                style: BoutiqueTokens.caption.copyWith(
                  fontFamily: BoutiqueTokens.fontFamily,
                  color: p.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                fiatMinor(entry['amount_minor']),
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

class _SpendRow extends StatelessWidget {
  const _SpendRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: BoutiqueTokens.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: BoutiqueTokens.caption.copyWith(
                fontFamily: BoutiqueTokens.fontFamily,
                color: p.muted,
              ),
            ),
          ),
          Text(
            value,
            style: BoutiqueTokens.label.copyWith(
              fontFamily: BoutiqueTokens.fontFamily,
              fontWeight: FontWeight.w700,
              color: p.fg,
            ),
          ),
        ],
      ),
    );
  }
}
