import 'package:flutter/material.dart';
import '../core/routes/boutique_routes.dart';
import '../core/theme/boutique_colors.dart';
import '../widgets/store_components.dart';

class PagesMapScreen extends StatelessWidget {
  const PagesMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<(String, String)>>{
      'دەستپێک': [
        (BoutiqueRoutes.splash, 'دەستپێک'),
        (BoutiqueRoutes.lang, 'هەڵبژاردنی زمان'),
        (BoutiqueRoutes.onboard, 'ناساندن'),
        (BoutiqueRoutes.otpLogin, 'چوونەژوورەوە / OTP'),
        (BoutiqueRoutes.auth, 'چوونەژوورەوە بە ئیمەیڵ'),
      ],
      'کڕین': [
        (BoutiqueRoutes.home, 'سەرەکی'),
        (BoutiqueRoutes.products, 'پۆلەکان'),
        (BoutiqueRoutes.search, 'گەڕان'),
        (BoutiqueRoutes.deals, 'ئۆفەرەکان'),
        (BoutiqueRoutes.wishlist, 'دڵخوازەکان'),
      ],
      'داواکاری': [
        (BoutiqueRoutes.cart, 'سەبەتە'),
        (BoutiqueRoutes.checkout, 'تەواوکردنی داواکاری'),
        (BoutiqueRoutes.orders, 'داواکارییەکانم'),
        (BoutiqueRoutes.complaint, 'سکاڵا'),
      ],
      'ڕۆنیکس': [
        (BoutiqueRoutes.coins, 'جزدانی ڕۆنیکس'),
        (BoutiqueRoutes.challenges, 'چالنجەکان'),
        (BoutiqueRoutes.auction, 'مەزاد'),
        (BoutiqueRoutes.bid, 'پێشنیاردان'),
        (BoutiqueRoutes.winners, 'ئەنجامەکان'),
        (BoutiqueRoutes.gives, 'Roni Gives'),
      ],
      'هەژمار': [
        (BoutiqueRoutes.profile, 'هەژمار'),
        (BoutiqueRoutes.editProfile, 'دەستکاری پڕۆفایل'),
        (BoutiqueRoutes.addresses, 'ناونیشانەکان'),
        (BoutiqueRoutes.invite, 'بانگهێشت'),
        (BoutiqueRoutes.chats, 'نامەکان'),
        (BoutiqueRoutes.notifications, 'ئاگادارکردنەوەکان'),
        (BoutiqueRoutes.settings, 'ڕێکخستنەکان'),
        (BoutiqueRoutes.help, 'یارمەتی'),
      ],
    };

    return Scaffold(
      backgroundColor: BoutiqueColors.cream,
      appBar: AppBar(title: const Text('نەخشەی پەڕەکان')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          for (final entry in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 6),
              child: Text(entry.key, style: const TextStyle(color: BoutiqueColors.muted2, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
            RoniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (final row in entry.value)
                    ListTile(
                      title: Text(row.$2, style: const TextStyle(fontWeight: FontWeight.w700)),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () {
                        if (BoutiqueRoutes.tabRoutes.contains(row.$1)) {
                          BoutiqueRoutes.openTab(
                            context,
                            {
                              BoutiqueRoutes.home: 0,
                              BoutiqueRoutes.products: 1,
                              BoutiqueRoutes.cart: BoutiqueRoutes.cartTab,
                              BoutiqueRoutes.profile: BoutiqueRoutes.profileTab,
                            }[row.$1]!,
                          );
                        } else {
                          Navigator.pushNamed(context, row.$1);
                        }
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
