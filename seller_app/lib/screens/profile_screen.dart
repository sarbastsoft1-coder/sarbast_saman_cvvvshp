import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/notification_bell.dart';
import '../widgets/page_transitions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic> _store = {};
  Map<String, dynamic> _kpis = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await ApiService.get('/seller/dashboard');
      if (res['status'] == 'success') {
        _store = res['data']?['store'] ?? {};
        _kpis = res['data']?['kpis'] ?? {};
      }
    } catch (e) {
      debugPrint('Profile: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _logout() async {
    // Drop the feed before the token goes, so the next seller to sign in on this
    // device never sees this account's notifications.
    NotificationProvider.instance.reset();
    await ApiService.logout();
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final name = _store['name'] ?? 'Your studio';
    final craft = _store['craft_category'] ?? 'Crafts';
    final tagline = (_store['tagline'] ?? 'Earth-fired craft, made by hand.')
        .toString();
    final initial = name.isNotEmpty ? String.fromCharCode(name.runes.first) : 'ڕ';
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('زیاتر'),
        actions: [
          NotificationBellButton(
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            onPressed: () => context.push('/profile/settings'),
            icon: const Icon(Icons.settings_rounded,
                color: AppColors.terracotta),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                FadeSlideIn(
                  child: GlassCard(
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.terracotta,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '$craft · $tagline',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.verified_rounded,
                                        size: 14, color: AppColors.success),
                                    SizedBox(width: 4),
                                    Text(
                                      'پشکنراو',
                                      style: TextStyle(
                                        color: AppColors.success,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.push('/profile/settings'),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.field,
                            side: const BorderSide(color: Color(0xF2FFFFFF)),
                          ),
                          icon: const Icon(Icons.edit_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: Row(
                    children: [
                      Expanded(
                        child: _KpiMini(
                          label: 'فرۆشتن',
                          value: '${_kpis['gross_sales'] ?? '\$0'}',
                          color: AppColors.terracotta,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiMini(
                          label: 'داواکاری',
                          value: '${_kpis['orders_count'] ?? '0'}',
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 220),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _LinkRow(
                          icon: Icons.bar_chart_rounded,
                          label: 'ئامار',
                          onTap: () => context.go(AppRoutes.dashboard),
                        ),
                        const Divider(height: 1),
                        _LinkRow(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'پارەی هەفتانە',
                          onTap: () => context.go(AppRoutes.settlements),
                        ),
                        const Divider(height: 1),
                        _LinkRow(
                          icon: Icons.settings_rounded,
                          label: 'ڕێکخستنی دووکان',
                          onTap: () => context.push('/profile/settings'),
                        ),
                        const Divider(height: 1),
                        _LinkRow(
                          icon: Icons.help_outline_rounded,
                          label: 'یاساکان و یارمەتی',
                          onTap: () {},
                        ),
                        const Divider(height: 1),
                        _LinkRow(
                          icon: Icons.logout_rounded,
                          label: 'چوونەدەرەوە',
                          color: AppColors.danger,
                          onTap: _logout,
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

class _KpiMini extends StatelessWidget {
  const _KpiMini({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.forest;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}