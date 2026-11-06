import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/invite_provider.dart';
import '../../widgets/store_components.dart';

class InviteScreen extends StatelessWidget {
  const InviteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final invite = context.watch<InviteProvider>();
    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(title: const Text('بانگهێشتی هاوڕێ')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          RoniCard(
            color: BoutiqueColors.ink,
            borderColor: Colors.transparent,
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: BoutiqueColors.dustyPink, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 30),
                ),
                const SizedBox(height: 12),
                const Text(
                  '٧٥ ڕۆنیکس بۆ هەردووکتان',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  'کاتێک هاوڕێکەت بە کۆدەکەت یەکەم داواکاری وەردەگرێت، هەردووکتان ٧٥ ڕۆنیکس وەردەگرن.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.85,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          RoniCard(
            child: Column(
              children: [
                const Text('کۆدەکەت', style: TextStyle(color: BoutiqueColors.muted, fontSize: 13)),
                const SizedBox(height: 6),
                Text(
                  invite.code,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 4),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GoldButton(
                        label: 'ناردن بە واتساپ',
                        icon: Icons.share_rounded,
                        height: 44,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: 'کۆدی Roni من: ${invite.code}'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('کۆد کۆپی کرا · لە واتساپدا بنێرە')),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GhostButton(
                        label: 'کۆپی',
                        icon: Icons.copy_rounded,
                        height: 44,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: invite.code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('کۆپی کرا ✓')),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('بانگهێشتەکانت', style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text(
                '${invite.usedThisMonth} لە ${invite.monthlyLimit} ی ئەم مانگە',
                style: const TextStyle(color: BoutiqueColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          RoniCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final row in invite.invites)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: row.status == 'done' ? BoutiqueColors.successGreen : BoutiqueColors.statusShipped,
                      child: Text(row.name.characters.first, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ),
                    title: Text(row.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(
                      row.status == 'done' ? 'یەکەم گەیاندنی تەواو بوو' : 'چاوەڕێی یەکەم گەیاندن',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: Text(
                      row.reward != null ? '+${row.reward}' : 'چاوەڕوان',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: row.reward != null ? BoutiqueColors.successGreen : BoutiqueColors.muted,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'زۆرترین ٣ بانگهێشت لە مانگێکدا. بانگهێشت لە هەمان ناونیشان یان هەمان مۆبایل ناژمێردرێت.',
            style: TextStyle(color: BoutiqueColors.muted, fontSize: 12, height: 1.7),
          ),
        ],
      ),
    );
  }
}
