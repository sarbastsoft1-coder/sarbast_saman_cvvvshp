import 'package:flutter/material.dart';

import '../../core/theme/boutique_colors.dart';
import '../../widgets/store_components.dart';

/// Explainer matching HTML `PAGES.how` — opened from the home trust row.
class HowRoniWorksScreen extends StatelessWidget {
  const HowRoniWorksScreen({super.key});

  static const _items = <(IconData, String, String)>[
    (
      Icons.verified_user_outlined,
      'ئەمانەتی Roni',
      'کاڵاکە دەبینیت، پاشان پارە دەدەیت. Roni پارەکە ٣ ڕۆژ ڕادەگرێت پێش ئەوەی بیدات بە فرۆشیار.',
    ),
    (
      Icons.photo_camera_outlined,
      'وێنەی ڕاستەقینەی کاڵاکەت',
      'پێش ناردن، فرۆشیار وێنەی هەمان ئەو پارچەیە دەگرێت کە بۆ تۆیە.',
    ),
    (
      Icons.storefront_outlined,
      'فرۆشیاری پشتڕاستکراو',
      'نیشانەی شین واتە Roni ناسنامە و شوێن و کوالیتییەکەی پشکنیوە.',
    ),
    (
      Icons.local_shipping_outlined,
      'گەیاندن یان وەرگرتن',
      'بۆ ماڵەوە، یان لە خاڵێکی Roni ی نزیک خۆت بێبەرامبەر.',
    ),
    (
      Icons.monetization_on_outlined,
      'Ronix',
      'بە کڕین و ئاستەنگ دەیبەیتەوە و لە مەزادی هەفتانەدا بەکاری دەهێنیت.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final p = RoniPalette.of(context);
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: const Text('Roni چۆن کار دەکات')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (final (icon, title, body) in _items) ...[
            RoniCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.soft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: p.brand2, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: p.fg,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            fontFamily: 'Vazirmatn',
                            fontSize: 14,
                            height: 1.55,
                            color: p.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 8),
          GoldButton(
            label: 'دەست بە کڕین بکە',
            onPressed: () {
              Navigator.of(context).popUntil((r) => r.isFirst);
            },
          ),
        ],
      ),
    );
  }
}
