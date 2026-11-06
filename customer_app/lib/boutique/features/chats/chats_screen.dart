import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/chats_provider.dart';
import '../../widgets/store_components.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chats = context.watch<ChatsProvider>();
    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(title: const Text('نامەکان')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          RoniCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final t in chats.threads)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: BoutiqueColors.ink,
                      child: Text(
                        t.seller.characters.first,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                      ),
                    ),
                    title: Text(t.seller, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text(t.preview, maxLines: 1, overflow: TextOverflow.ellipsis),
                    trailing: t.unread > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(color: BoutiqueColors.dustyPink, borderRadius: BorderRadius.circular(10)),
                            child: Text('${t.unread}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                          )
                        : null,
                    onTap: () {
                      chats.open(t.id);
                      Navigator.pushNamed(context, BoutiqueRoutes.chat, arguments: t.id);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
