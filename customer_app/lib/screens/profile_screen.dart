import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../services/language_service.dart';
import '../widgets/language_selector_sheet.dart';
import '../localization/string_extension.dart';
import 'main_shell.dart';
import 'orders_screen.dart';
import 'favorites_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AppState appState;
  final void Function(int) onSwitchTab;

  const ProfileScreen({
    super.key,
    required this.appState,
    required this.onSwitchTab,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              StaggeredItem(
                index: 0,
                child: _buildProfileHeader(),
              ),
              const SizedBox(height: 18),
              StaggeredItem(
                index: 1,
                child: _buildStatsCard(),
              ),
              const SizedBox(height: 24),
              StaggeredItem(
                index: 2,
                child: _buildMenu(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Animated avatar with rotating halo
        SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rotating aura
              _RotatingAura(
                size: 140,
                colors: const [
                  EarthTheme.terracotta,
                  EarthTheme.goldenGlow,
                  EarthTheme.sageGreen,
                ],
              ),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [EarthTheme.terracotta, EarthTheme.clayOchre],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: EarthTheme.terracottaGlow,
                ),
                child: const Center(
                  child: Text('👩', style: TextStyle(fontSize: 48)),
                ),
              ),
              Positioned(
                bottom: 4,
                right: 14,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: EarthTheme.forestGreen,
                      width: 2.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_rounded,
                      color: EarthTheme.forestGreen,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Elena Vance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: EarthTheme.forestGreen,
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'elena@earthshop.test',
          style: TextStyle(
            fontSize: 13,
            color: EarthTheme.muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [EarthTheme.goldenGlow, EarthTheme.clayOchre],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: EarthTheme.ochreGlow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  size: 14, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'ECO PIONEER'.tr(context),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [EarthTheme.forestGreen, Color(0xFF152721)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        boxShadow: EarthTheme.forestGlow,
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              value: '3',
              label: 'Orders'.tr(context),
              icon: Icons.inventory_2_outlined,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: Column(
              children: [
                AnimatedCounter(
                  value: widget.appState.tokenBalance,
                  decimals: 0,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Terra Tokens'.tr(context),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          Expanded(
            child: _statItem(
              value: '2',
              label: 'Badges'.tr(context),
              icon: Icons.workspace_premium_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem({
    required String value,
    required String label,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
        border: Border.all(color: EarthTheme.borderLight),
      ),
      child: Column(
        children: [
          _menuRow(
            icon: Icons.inventory_2_outlined,
            label: 'My Orders'.tr(context),
            subtitle: 'Track shipments'.tr(context),
            bgColor: EarthTheme.sageLight,
            iconColor: EarthTheme.sageGreen,
            onTap: () => Navigator.of(context).push(
              SharedAxisPageRoute(
                builder: (_) => const OrdersScreen(),
              ),
            ),
          ),
          _divider(),
          _menuRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Wallet & Tokens'.tr(context),
            subtitle: 'Trade Terra tokens'.tr(context),
            bgColor: EarthTheme.ochreLight,
            iconColor: EarthTheme.clayOchre,
            onTap: () => widget.onSwitchTab(2),
          ),
          _divider(),
          _menuRow(
            icon: Icons.emoji_events_outlined,
            label: 'My Challenges'.tr(context),
            subtitle: 'Earn eco rewards'.tr(context),
            bgColor: EarthTheme.terracottaSoft,
            iconColor: EarthTheme.terracotta,
            onTap: () => widget.onSwitchTab(3),
          ),
          _divider(),
          _menuRow(
            icon: Icons.favorite_border_rounded,
            label: 'Favorites'.tr(context),
            subtitle: 'Saved items'.tr(context),
            bgColor: EarthTheme.dangerBg,
            iconColor: EarthTheme.danger,
            onTap: () => Navigator.of(context).push(
              SharedAxisPageRoute(
                builder: (_) => FavoritesScreen(appState: widget.appState),
              ),
            ),
          ),
          _divider(),
          _menuRow(
            icon: Icons.location_on_outlined,
            label: 'Shipping Addresses'.tr(context),
            subtitle: 'Manage locations'.tr(context),
            bgColor: EarthTheme.mintFaint,
            iconColor: EarthTheme.forestGreen,
            onTap: () => _showComingSoon(context, 'Shipping Addresses'.tr(context)),
          ),
          _divider(),
          _menuRow(
            icon: Icons.language_rounded,
            label: 'Language'.tr(context),
            subtitle: LanguageService.instance.currentLanguageName,
            bgColor: EarthTheme.ochreLight,
            iconColor: EarthTheme.clayOchre,
            onTap: () => showLanguageSheet(context),
          ),
          _divider(),
          _menuRow(
            icon: Icons.settings_outlined,
            label: 'Settings'.tr(context),
            subtitle: 'App preferences'.tr(context),
            bgColor: EarthTheme.linenLight,
            iconColor: EarthTheme.muted,
            onTap: () => Navigator.of(context).push(
              SharedAxisPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuRow({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return PressScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(child: Icon(icon, size: 20, color: iconColor)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.charcoal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: EarthTheme.muted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: EarthTheme.warmSandLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: EarthTheme.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.only(left: 70),
      color: EarthTheme.borderLight,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature coming soon!')),
    );
  }
}

class _RotatingAura extends StatefulWidget {
  final double size;
  final List<Color> colors;
  const _RotatingAura({
    required this.size,
    required this.colors,
  });

  @override
  State<_RotatingAura> createState() => _RotatingAuraState();
}

class _RotatingAuraState extends State<_RotatingAura>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: List.generate(8, (i) {
              final angle = (_ctrl.value * 2 * 3.14159) + (i * 3.14159 / 4);
              return Transform.rotate(
                angle: angle,
                child: Container(
                  width: widget.size * 0.95,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.colors[i % widget.colors.length]
                            .withValues(alpha: 0.0),
                        widget.colors[i % widget.colors.length],
                        widget.colors[i % widget.colors.length]
                            .withValues(alpha: 0.0),
                      ],
                  stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
