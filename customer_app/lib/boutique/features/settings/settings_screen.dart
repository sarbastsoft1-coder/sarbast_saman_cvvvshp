import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/boutique_routes.dart';
import '../../core/theme/boutique_colors.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/store_components.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _pickTheme(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final picked = await showModalBottomSheet<BoutiqueThemeMode>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final p = RoniPalette.of(ctx);
        Widget tile(BoutiqueThemeMode mode, String label, IconData icon) {
          final on = settings.themeMode == mode;
          return ListTile(
            leading: Icon(icon, color: on ? p.brand2 : p.muted),
            title: Text(
              label,
              style: TextStyle(
                fontFamily: 'Vazirmatn',
                fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                color: p.fg,
              ),
            ),
            trailing: on
                ? Icon(Icons.check_rounded, color: p.brand2)
                : null,
            onTap: () => Navigator.pop(ctx, mode),
          );
        }

        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              tile(BoutiqueThemeMode.light, 'ڕووناک', Icons.light_mode_outlined),
              tile(BoutiqueThemeMode.dark, 'تاریک', Icons.dark_mode_outlined),
              tile(
                BoutiqueThemeMode.system,
                'سیستەم',
                Icons.brightness_auto_outlined,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null) await settings.setThemeMode(picked);
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    // Sub-toggles follow the master switch, as before.
    final sub = settings.notificationsEnabled;

    return Scaffold(
      appBar: AppBar(title: const Text('ڕێکخستنەکان')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const RoniSectionHeader(
            title: 'ئاگادارکردنەوەکانی ناو ئەپ',
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RoniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingRow(
                    icon: Icons.notifications_none_rounded,
                    label: 'پیشاندانی ئاگادارکردنەوە',
                    description: 'لە لیست و نیشانەی پەڕەی سەرەتا',
                    toggle: settings.notificationsEnabled,
                    onChanged: settings.setNotificationsEnabled,
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.local_shipping_outlined,
                    label: 'داواکارییەکان',
                    toggle: settings.orderUpdates,
                    onChanged: sub ? settings.setOrderUpdates : null,
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.local_offer_outlined,
                    label: 'کۆپۆن و داشکاندن',
                    toggle: settings.promoUpdates,
                    onChanged: sub ? settings.setPromoUpdates : null,
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.auto_awesome_outlined,
                    label: 'بەرهەمی نوێ',
                    toggle: settings.productUpdates,
                    onChanged: sub ? settings.setProductUpdates : null,
                  ),
                ],
              ),
            ),
          ),
          const RoniSectionHeader(
            title: 'زمان و ڕووکار',
            padding: EdgeInsets.fromLTRB(20, 30, 20, 12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RoniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _SettingRow(
                    icon: Icons.language_rounded,
                    label: 'کوردی (سۆرانی)',
                    description: 'زمانی بەردەستی ئەم وەشانە',
                  ),
                  const _RowDivider(),
                  const _SettingRow(
                    icon: Icons.payments_outlined,
                    label: 'دراو',
                    description: 'نرخی بەرهەم و داواکاری',
                    valueText: 'دیناری عێراقی • IQD',
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.brightness_6_outlined,
                    label: 'ڕووکار',
                    description: 'ڕووناک، تاریک، یان سیستەم',
                    valueText: switch (settings.themeMode) {
                      BoutiqueThemeMode.light => 'ڕووناک',
                      BoutiqueThemeMode.dark => 'تاریک',
                      BoutiqueThemeMode.system => 'سیستەم',
                    },
                    onTap: () => _pickTheme(context, settings),
                  ),
                ],
              ),
            ),
          ),
          const RoniSectionHeader(
            title: 'دەربارەی ئەپ',
            padding: EdgeInsets.fromLTRB(20, 30, 20, 12),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RoniCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  const _SettingRow(
                    icon: Icons.info_outline_rounded,
                    label: 'وەشانی ئەپ',
                    valueText: '1.0.0',
                  ),
                  const _RowDivider(),
                  _SettingRow(
                    icon: Icons.help_outline_rounded,
                    label: 'یارمەتی و چۆنیەتی پاشەکەوتکردنی داتا',
                    onTap: () =>
                        Navigator.pushNamed(context, BoutiqueRoutes.help),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Divider aligned with the label column, leaving the icon tile clear.
class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 72, endIndent: 16);
}

/// Soft-gold square used by every settings row.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 42,
    height: 42,
    decoration: BoxDecoration(
      color: BoutiqueColors.goldWash,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Icon(icon, size: 21, color: BoutiqueColors.dustyPink),
  );
}

/// One settings line. Renders a [Switch] when [toggle] is given, otherwise a
/// read-only value, plus a chevron when it navigates somewhere.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.label,
    this.description,
    this.valueText,
    this.onTap,
    this.toggle,
    this.onChanged,
  });

  final IconData icon;
  final String label;
  final String? description;
  final String? valueText;
  final VoidCallback? onTap;
  final bool? toggle;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A whole-row tap mirrors the switch, so the row itself is the target.
    final tap =
        onTap ??
        (toggle != null && onChanged != null
            ? () => onChanged!(!toggle!)
            : null);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconTile(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description != null) ...[
                  const SizedBox(height: 3),
                  Text(description!, style: theme.textTheme.bodySmall),
                ],
              ],
            ),
          ),
          if (valueText != null) ...[
            const SizedBox(width: 10),
            Text(valueText!, style: theme.textTheme.bodySmall),
          ],
          if (onTap != null)
            const Padding(
              padding: EdgeInsetsDirectional.only(start: 2),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 20,
                color: BoutiqueColors.muted,
              ),
            ),
          if (toggle != null)
            Switch(
              value: toggle!,
              onChanged: onChanged,
              activeThumbColor: BoutiqueColors.white,
              activeTrackColor: BoutiqueColors.dustyPink,
            ),
        ],
      ),
    );

    if (tap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tap,
        borderRadius: BorderRadius.circular(16),
        child: content,
      ),
    );
  }
}
