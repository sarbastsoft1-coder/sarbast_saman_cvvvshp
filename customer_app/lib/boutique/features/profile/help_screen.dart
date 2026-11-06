import 'package:flutter/material.dart';

import '../../core/theme/boutique_colors.dart';
import '../../widgets/store_components.dart';

/// One help category: a title card that expands into its answers.
class _HelpCategory {
  const _HelpCategory({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.keywords,
    required this.answers,
  });

  final String id;
  final IconData icon;
  final String title;
  final String description;

  /// Extra words the client-side search also matches on.
  final String keywords;
  final List<String> answers;

  /// Title, description and keywords are all searchable.
  String get haystack => '$title $description $keywords ${answers.join(' ')}';
}

const _categories = <_HelpCategory>[
  _HelpCategory(
    id: 'basket',
    icon: Icons.shopping_basket_outlined,
    title: 'داواکاری و سەبەتە',
    description: 'زیادکردنی بەرهەم، کۆپۆن و دووبارە کڕینەوە',
    keywords: 'کڕین سەبەتە کۆپۆن زیادکردن بەرهەم دووبارە کڕینەوە دەڵخ',
    answers: [
      'بەرهەمەکە بکەرەوە، قەبارە و ڕەنگ هەڵبژێرە و دوگمەی زیادکردن بۆ سەبەتە دابگرە. لە سەبەتەدا دەتوانیت ژمارەی بەرهەمەکان بگۆڕیت.',
      'لە سەبەتەدا بەشی کۆپۆن بکەرەوە. WELCOME20 بۆ کڕینی ٤٠,٠٠٠ دینار یان زیاتر و FREESHIP بۆ ٣٠,٠٠٠ دینار یان زیاترە. تەنها یەک کۆپۆن لە هەر داواکارییەکدا بەکاردێت.',
    ],
  ),
  _HelpCategory(
    id: 'delivery',
    icon: Icons.payments_outlined,
    title: 'پارەدان و گەیاندن',
    description: 'شێوازی پارەدان و دۆخی گەیاندنی داواکاری',
    keywords: 'پارەدان کارت بانکی گەیاندن شۆفێر کرێ خۆراک',
    answers: [
      'لە وەشانی پیشانداندا تەنها تۆمارکردنی داواکاریی تاقیکردنەوە بەردەستە. پارەدانی کارتی بانکی، شوێنپێهەڵگرتنی ڕاستەوخۆ و پەیوەندی بە شۆفێر چالاک نین.',
    ],
  ),
  _HelpCategory(
    id: 'data',
    icon: Icons.lock_outline_rounded,
    title: 'پاراستنی داتا',
    description: 'شوێنی پاشەکەوتکردنی زانیارییەکان',
    keywords: 'داتا پاراستن پاشەکەوت وشەی نهێنی کارتی بانکی سڕینەوە',
    answers: [
      'ناو، ناونیشان، سەبەتە، دڵخواز، هەڵسەنگاندن و داواکاری لەسەر ئەم وێبگەڕە یان ئامێرە پاشەکەوت دەکرێن. پاککردنەوەی داتای ئەپ ئەم زانیارییانە دەسڕێتەوە. زانیاری کارتی بانکی یان وشەی نهێنی لێرە داخڵ مەکە.',
    ],
  ),
];

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _query = TextEditingController();
  final Set<String> _expanded = <String>{};

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Categories matching the query; all of them while the field is empty.
  List<_HelpCategory> get _visible {
    final query = _query.text.trim();
    if (query.isEmpty) return _categories;
    return _categories.where((c) => c.haystack.contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visible;
    // While searching every hit is shown open, so answers are not hidden
    // behind a second tap.
    final searching = _query.text.trim().isNotEmpty;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              const _HelpHeader(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RoniSearchField(
                  hint: 'بەدوای وەڵام بگەڕێ',
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: StoreNotice(
                  'ئەم وەشانە پیشاندانی بۆتیکە. کڕین و هەڵسەنگاندنەکان لەسەر ئەم ئامێرە پاشەکەوت دەکرێن؛ هیچ پارەیەک وەرناگیرێت و هیچ داواکارییەک بۆ فرۆشیار نانێردرێت.',
                ),
              ),
              const SizedBox(height: 20),
              if (visible.isEmpty)
                const SizedBox(
                  height: 280,
                  child: StoreEmpty(
                    title: 'هیچ وەڵامێک نەدۆزرایەوە',
                    message: ' وشەیەکی تر بنووسە یان بەشێکی تر هەڵبژێرە.',
                    icon: Icons.search_off_rounded,
                  ),
                )
              else
                for (final category in visible)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _CategoryCard(
                      category: category,
                      expanded: searching || _expanded.contains(category.id),
                      onToggle: () => setState(() {
                        if (!_expanded.remove(category.id)) {
                          _expanded.add(category.id);
                        }
                      }),
                    ),
                  ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: const _SupportCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// In-page header standing in for the AppBar.
class _HelpHeader extends StatelessWidget {
  const _HelpHeader();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
    child: Row(
      children: [
        RoniIconButton(
          icon: Icons.arrow_back_rounded,
          tooltip: 'گەڕانەوە',
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'پشتگیری و یارمەتی',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'بەشێک هەڵبژێرە یان بەدوای وەڵام بگەڕێ',
                style: const TextStyle(
                  fontSize: 12,
                  color: BoutiqueColors.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Soft-gold square used by every help row.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
    decoration: BoxDecoration(
      color: BoutiqueColors.goldWash,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: 22, color: BoutiqueColors.dustyPink),
  );
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.expanded,
    required this.onToggle,
  });

  final _HelpCategory category;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RoniCard(
      onTap: onToggle,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _IconTile(icon: category.icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(category.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      category.description,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.chevron_left_rounded,
                color: BoutiqueColors.muted,
              ),
            ],
          ),
          if (expanded) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            for (final answer in category.answers)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  answer,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.75),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Support block. It carries no action because the demo build has no live
/// support channel — it only points back at the guidance above.
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return RoniCard(
      color: BoutiqueColors.goldWash,
      borderColor: BoutiqueColors.softPink,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: BoutiqueColors.goldGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              size: 24,
              color: BoutiqueColors.white,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('پشتگیری بۆتیک', style: theme.textTheme.titleMedium),
                const SizedBox(height: 5),
                Text(
                  'پەیوەندیی ڕاستەوخۆ بە فرۆشیاران لەم وەشانەدا چالاک نییە؛ ڕێنمایییەکانی سەرەوە بەردەستن.',
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
