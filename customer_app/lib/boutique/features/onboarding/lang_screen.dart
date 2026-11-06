import 'package:flutter/material.dart';
import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../widgets/roni_icons.dart';
import '../../widgets/store_components.dart';

/// Language picker matching the HTML login langs row.
class LangScreen extends StatefulWidget {
  const LangScreen({super.key});

  @override
  State<LangScreen> createState() => _LangScreenState();
}

class _LangScreenState extends State<LangScreen> {
  String _lang = 'ckb';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BoutiqueColors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
          child: Column(
            children: [
              const Spacer(),
              const RonixLogo(size: 96),
              const SizedBox(height: 18),
              Text(
                'زمان هەڵبژێرە',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text(
                'دەتوانیت دواتر لە هەژمار بیگۆڕیت.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Vazirmatn',
                  fontSize: 14,
                  color: BoutiqueColors.muted,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final item in const [
                    ('ckb', 'کوردی'),
                    ('ar', 'عربي'),
                    ('en', 'English'),
                  ])
                    _LangChip(
                      label: item.$2,
                      selected: _lang == item.$1,
                      ltr: item.$1 == 'en',
                      onTap: () => setState(() => _lang = item.$1),
                    ),
                ],
              ),
              const Spacer(flex: 2),
              GoldButton(
                label: 'بەردەوامبە',
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(BoutiqueRoutes.onboard),
              ),
              TextButton(
                onPressed: () => Navigator.of(
                  context,
                ).pushReplacementNamed(BoutiqueRoutes.otpLogin),
                child: const Text(
                  'تێپەڕین',
                  style: TextStyle(
                    fontFamily: 'Vazirmatn',
                    fontWeight: FontWeight.w600,
                    color: BoutiqueColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  const _LangChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.ltr = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool ltr;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? BoutiqueColors.softPink : BoutiqueColors.white,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? BoutiqueColors.dustyPink : BoutiqueColors.line2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            label,
            textDirection: ltr ? TextDirection.ltr : TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Vazirmatn',
              fontSize: 14,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? BoutiqueColors.primaryInk
                  : BoutiqueColors.charcoal,
            ),
          ),
        ),
      ),
    );
  }
}
