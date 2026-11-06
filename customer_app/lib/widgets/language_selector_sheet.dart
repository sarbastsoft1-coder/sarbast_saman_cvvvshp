import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../services/language_service.dart';
import '../localization/string_extension.dart';

void showLanguageSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final currentCode = LanguageService.instance.languageCode;
      return Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 30,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: EarthTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: EarthTheme.sageLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: EarthTheme.sageGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Language'.tr(context),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: EarthTheme.forestGreen,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Kurdish Sorani (highlighted first!)
              _LanguageTile(
                code: 'ckb',
                title: 'کوردی (سۆرانی)',
                subtitle: 'Kurdish Sorani (RTL)',
                flagEmoji: '☀️',
                isSelected: currentCode == 'ckb',
                onTap: () {
                  LanguageService.instance.setLanguage('ckb');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),

              // English
              _LanguageTile(
                code: 'en',
                title: 'English',
                subtitle: 'English (LTR)',
                flagEmoji: '🌍',
                isSelected: currentCode == 'en',
                onTap: () {
                  LanguageService.instance.setLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 10),

              // Arabic
              _LanguageTile(
                code: 'ar',
                title: 'العربية',
                subtitle: 'Arabic (RTL)',
                flagEmoji: '🌙',
                isSelected: currentCode == 'ar',
                onTap: () {
                  LanguageService.instance.setLanguage('ar');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _LanguageTile extends StatelessWidget {
  final String code;
  final String title;
  final String subtitle;
  final String flagEmoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.flagEmoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(EarthTheme.radiusMd),
      child: AnimatedContainer(
        duration: EarthTheme.durFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? EarthTheme.mintFaint : Colors.white,
          borderRadius: BorderRadius.circular(EarthTheme.radiusMd),
          border: Border.all(
            color: isSelected ? EarthTheme.forestGreen : EarthTheme.borderLight,
            width: isSelected ? 1.6 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Text(flagEmoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? EarthTheme.forestGreen
                          : EarthTheme.charcoal,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: EarthTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: EarthTheme.forestGreen,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 14,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
