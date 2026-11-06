import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_transitions.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _emailDigest = false;
  bool _darkMode = false;
  bool _biometrics = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          FadeSlideIn(
            child: _Section(
              title: 'Notifications',
              children: [
                _SwitchTile(
                  icon: Icons.notifications_active_rounded,
                  title: 'Push notifications',
                  subtitle: 'New orders and milestones',
                  value: _pushNotifications,
                  onChanged: (v) => setState(() => _pushNotifications = v),
                ),
                const Divider(height: 1),
                _SwitchTile(
                  icon: Icons.mail_outline_rounded,
                  title: 'Weekly digest',
                  subtitle: 'A summary every Monday',
                  value: _emailDigest,
                  onChanged: (v) => setState(() => _emailDigest = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: _Section(
              title: 'Appearance',
              children: [
                _SwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Dark mode',
                  subtitle: 'Easier on the eyes at night',
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: _Section(
              title: 'Security',
              children: [
                _SwitchTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric login',
                  subtitle: 'Use fingerprint or Face ID',
                  value: _biometrics,
                  onChanged: (v) => setState(() => _biometrics = v),
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.lock_outline_rounded,
                  title: 'Change password',
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FadeSlideIn(
            delay: const Duration(milliseconds: 320),
            child: _Section(
              title: 'About',
              children: [
                _NavTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  trailing: const Text(
                    '1.0.0',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {},
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Privacy policy',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _NavTile(
                  icon: Icons.description_outlined,
                  title: 'Terms of service',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        GlassCard(padding: EdgeInsets.zero, child: Column(children: children)),
      ],
    );
  }
}

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      secondary: Icon(icon, color: AppColors.terracotta),
      title: Text(title,
          style: const TextStyle(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          )),
      subtitle: Text(subtitle,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          )),
      value: value,
      activeThumbColor: AppColors.terracotta,
      onChanged: onChanged,
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: AppColors.terracotta),
      title: Text(title,
          style: const TextStyle(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          )),
      trailing: trailing ??
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted),
      onTap: onTap,
    );
  }
}