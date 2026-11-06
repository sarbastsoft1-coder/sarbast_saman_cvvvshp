import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_bell.dart';

/// Hosts the floating HTML-style bottom nav and swaps body via [navigationShell].
/// Tabs: سەرەکی · داواکاری · بەرهەم · پارە · زیاتر
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    _TabInfo(
      label: 'سەرەکی',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _TabInfo(
      label: 'داواکاری',
      icon: Icons.inventory_2_outlined,
      activeIcon: Icons.inventory_2_rounded,
    ),
    _TabInfo(
      label: 'بەرهەم',
      icon: Icons.sell_outlined,
      activeIcon: Icons.sell_rounded,
    ),
    _TabInfo(
      label: 'پارە',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
    ),
    _TabInfo(
      label: 'زیاتر',
      icon: Icons.menu_rounded,
      activeIcon: Icons.menu_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.warmGradient),
        child: navigationShell,
      ),
      bottomNavigationBar: _AnimatedBottomBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class _TabInfo {
  const _TabInfo({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class _AnimatedBottomBar extends StatelessWidget {
  const _AnimatedBottomBar({
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xF2FFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x291E64B4),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              for (int i = 0; i < MainShell._tabs.length; i++)
                Expanded(
                  flex: i == currentIndex ? 23 : 10,
                  child: _NavItem(
                    info: MainShell._tabs[i],
                    isActive: i == currentIndex,
                    badgeCount: i == 1
                        ? NotificationScope.watch(context).unreadCount
                        : 0,
                    onTap: () => onTap(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.info,
    required this.isActive,
    required this.onTap,
    this.badgeCount = 0,
  });

  final _TabInfo info;
  final bool isActive;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1769D1) : Colors.transparent,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  isActive ? info.activeIcon : info.icon,
                  color: isActive ? Colors.white : AppColors.textMuted,
                  size: 22,
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -4,
                    child: UnreadBadge(count: badgeCount),
                  ),
              ],
            ),
            if (isActive) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  info.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Vazirmatn',
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
