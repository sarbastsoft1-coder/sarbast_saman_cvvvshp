import 'dart:async';

import 'product_discounts_screen.dart';
import 'package:flutter/material.dart';
import '../main.dart'; // For AdminTheme
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../widgets/admin_animations.dart';
import '../widgets/notification_bell.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'reward_tasks_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedNavIndex = 0;
  bool _isLoading = true;

  Map<String, dynamic> _kpis = {};
  List<dynamic> _users = [];
  List<dynamic> _articles = [];
  List<dynamic> _settings = [];

  double _tokenPeg = 1.25;
  double _platformFee = 0.0;
  double _deliveryFee = 4.50;

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    // Also covers a session restored from a saved token, which skips login.
    NotificationProvider.instance.startPolling();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    try {
      final kpiRes = await ApiService.get('/admin/kpis');
      final usersRes = await ApiService.get('/admin/users');
      final articlesRes = await ApiService.get('/admin/articles');
      final settingsRes = await ApiService.get('/admin/settings');

      if (kpiRes['status'] == 'success') _kpis = kpiRes['data'];
      if (usersRes['status'] == 'success') _users = usersRes['data'];
      if (articlesRes['status'] == 'success') _articles = articlesRes['data'];
      if (settingsRes['status'] == 'success') {
        _settings = settingsRes['data'];
        for (var s in _settings) {
          if (s['key'] == 'token_peg') {
            _tokenPeg = double.tryParse(s['value'].toString()) ?? 1.25;
          }
          if (s['key'] == 'platform_fee') {
            _platformFee = double.tryParse(s['value'].toString()) ?? 0.0;
          }
          if (s['key'] == 'delivery_fee') {
            _deliveryFee = double.tryParse(s['value'].toString()) ?? 4.50;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleUserStatus(int userId) async {
    try {
      final res = await ApiService.post(
        '/admin/users/$userId/toggle-status',
        {},
      );
      if (res['status'] == 'success') {
        final updatedUser = res['user'];
        setState(() {
          final idx = _users.indexWhere((u) => u['id'] == userId);
          if (idx != -1) {
            _users[idx] = updatedUser;
          }
        });
      }
    } catch (e) {
      debugPrint('Error toggling user: $e');
    }
  }

  Future<void> _publishArticle(String title) async {
    try {
      final res = await ApiService.post('/admin/articles/save', {
        'title': title,
        'summary': 'New article published from admin panel',
        'content': 'Content for $title',
      });
      if (res['status'] == 'success') {
        setState(() {
          _articles.insert(0, res['article']);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Published "$title" to community!')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error publishing article: $e');
    }
  }

  Future<void> _logout() async {
    // Drop the feed before the token goes, so the next admin to sign in on this
    // device never sees this account's notifications.
    NotificationProvider.instance.reset();
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(onOpenRoute: _handleActionRoute),
      ),
    );
  }

  /// Routes a notification's `action_route` onto the navigation rail.
  void _handleActionRoute(String route) {
    final index = switch (route) {
      '/product-discounts' => 0,
      '/reward-tasks' => 1,
      _ => -1,
    };

    Navigator.of(context).pop();
    if (index == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$route is not part of the admin panel')),
      );
      return;
    }
    setState(() => _selectedNavIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🏛️ ', style: TextStyle(fontSize: 20)),
            Text('Roni Admin Control Panel'),
          ],
        ),
        actions: [
          NotificationBellButton(onPressed: _openNotifications),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAllData),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Row(
        children: [
          // Navigation Rail / Sidebar
          NavigationRail(
            backgroundColor: AdminTheme.forestDark,
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (idx) =>
                setState(() => _selectedNavIndex = idx),
            labelType: NavigationRailLabelType.all,
            selectedLabelTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
            unselectedLabelTextStyle: const TextStyle(
              color: Colors.white60,
              fontSize: 11,
            ),
            selectedIconTheme: const IconThemeData(
              color: AdminTheme.terracotta,
            ),
            unselectedIconTheme: const IconThemeData(color: Colors.white60),
            destinations: _buildDestinations(NotificationScope.watch(context)),
          ),
          const VerticalDivider(thickness: 1, width: 1),

          // Main View Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.03),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: KeyedSubtree(
                            key: ValueKey(_selectedNavIndex),
                            child: _buildCurrentView(),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Navigation rail destinations. The points tasks tab carries the unread
  /// count, because reward submissions are what admins are notified about.
  List<NavigationRailDestination> _buildDestinations(
    NotificationProvider notifications,
  ) {
    return [
      const NavigationRailDestination(
        icon: Icon(Icons.local_offer_outlined),
        label: Text('Discounts'),
      ),
      NavigationRailDestination(
        icon: RailBadgeIcon(
          icon: Icons.stars_outlined,
          count: notifications.unreadCount,
          color: AdminTheme.terracotta,
        ),
        selectedIcon: RailBadgeIcon(
          icon: Icons.stars_rounded,
          count: notifications.unreadCount,
          color: AdminTheme.terracotta,
        ),
        label: const Text('Points tasks'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: Text('Users'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.article_outlined),
        selectedIcon: Icon(Icons.article),
        label: Text('Articashin'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
    ];
  }

  Widget _buildCurrentView() {
    if (_selectedNavIndex == 0) return const ProductDiscountsScreen();
    if (_selectedNavIndex == 1) return const RewardTasksScreen();
    switch (_selectedNavIndex - 2) {
      case 0:
        return _buildDashboardView();
      case 1:
        return _buildUsersView();
      case 2:
        return _buildArticlesView();
      case 3:
        return _buildSettingsView();
      default:
        return _buildDashboardView();
    }
  }

  Widget _buildDashboardView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Executive Platform Dashboard',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AdminTheme.forestGreen,
          ),
        ),
        const Text(
          'High-level overview across all 4 interconnected fronts',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 20),

        // KPI Cards Row
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return GridView.count(
              crossAxisCount: isWide ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 2.5,
              children: [
                FadeSlideIn(
                  delay: const Duration(milliseconds: 60),
                  child: _buildKpiCard(
                    'Gross Merchandise Volume',
                    _kpis['gross_volume']?.toString() ?? '\$0.00',
                    'Total sales value',
                    AdminTheme.forestGreen,
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 120),
                  child: _buildKpiCard(
                    'Active Ecosystem Users',
                    '${_kpis['active_users'] ?? 0} Users',
                    'Across all roles',
                    AdminTheme.forestGreen,
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 180),
                  child: _buildKpiCard(
                    'Circulating Terra Tokens',
                    _kpis['total_tokens_circulating']?.toString() ?? '0 TERRA',
                    'Zero inflation',
                    AdminTheme.clayOchre,
                  ),
                ),
                FadeSlideIn(
                  delay: const Duration(milliseconds: 240),
                  child: _buildKpiCard(
                    'Deliveries Today',
                    '${_kpis['completed_deliveries_today'] ?? 0} Completed',
                    'Avg 24m transit',
                    AdminTheme.terracotta,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 28),

        // Recent System Activity
        FadeSlideIn(
          delay: const Duration(milliseconds: 300),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Platform Registrations',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AdminTheme.forestGreen,
                ),
              ),
              const SizedBox(height: 12),
              _buildUserTablePreview(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard(String label, String value, String sub, Color color) {
    return BounceCard(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminTheme.earthBorder),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
          ],
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black45,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            sub,
            style: const TextStyle(
              fontSize: 10,
              color: AdminTheme.sageGreen,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildUserTablePreview() {
    final recentUsers = _kpis['recent_registrations'] as List<dynamic>? ?? [];
    if (recentUsers.isEmpty) return const Text('No recent users');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdminTheme.earthBorder),
      ),
      child: Column(
        children: recentUsers.map((u) {
          final name = u['name'] ?? 'User';
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AdminTheme.sageLight,
              child: Text(
                name[0],
                style: const TextStyle(
                  color: AdminTheme.forestGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AdminTheme.forestGreen,
              ),
            ),
            subtitle: Text(u['email'] ?? ''),
            trailing: Chip(
              label: Text(
                u['role'] ?? 'user',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: AdminTheme.sageLight,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUsersView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User & Guild Moderation',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AdminTheme.forestGreen,
          ),
        ),
        const Text(
          'Verify artisan workshops, manage customer profiles, and certify courier accounts',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.earthBorder),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _users.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final u = _users[i];
              final isActive = u['status'] == 'active';
              final name = u['name'] ?? 'User';
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AdminTheme.sageLight,
                  child: Text(
                    name[0],
                    style: const TextStyle(
                      color: AdminTheme.forestGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.forestGreen,
                  ),
                ),
                subtitle: Text('${u['email']} • Role: ${u['role']}'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive
                        ? Colors.grey[200]
                        : AdminTheme.sageLight,
                    foregroundColor: AdminTheme.forestGreen,
                  ),
                  onPressed: () => _toggleUserStatus(u['id']),
                  child: Text(
                    isActive ? 'Suspend' : 'Activate',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Article & Marketing CMS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.forestGreen,
                  ),
                ),
                Text(
                  'Manage "articashin" educational guides for circular craft trading',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminTheme.terracotta,
                foregroundColor: Colors.white,
              ),
              onPressed: () => _showNewArticleDialog(),
              child: const Text('+ New Article'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.earthBorder),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _articles.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (ctx, i) {
              final a = _articles[i];
              final isPublished =
                  a['is_published'] == 1 || a['is_published'] == true;
              return ListTile(
                title: Text(
                  a['title'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AdminTheme.forestGreen,
                  ),
                ),
                subtitle: Text('${a['category']} • (${a['read_time']})'),
                trailing: Chip(
                  label: Text(
                    isPublished ? 'Published' : 'Draft',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AdminTheme.forestGreen,
                    ),
                  ),
                  backgroundColor: AdminTheme.sageLight,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ecosystem System Settings',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AdminTheme.forestGreen,
          ),
        ),
        const Text(
          'Tune global token exchange parameters and platform rules',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminTheme.earthBorder),
          ),
          child: Column(
            children: [
              _buildSettingRow('Terra Token Peg (USD)', '\$$_tokenPeg', () {
                _promptSetting('Token Peg', _tokenPeg, (val) async {
                  setState(() => _tokenPeg = val);
                  await _saveSetting({'token_peg': val});
                });
              }),
              const Divider(),
              _buildSettingRow('Platform Fee (%)', '$_platformFee%', () {
                _promptSetting('Platform Fee', _platformFee, (val) async {
                  setState(() => _platformFee = val);
                  await _saveSetting({'platform_fee': val});
                });
              }),
              const Divider(),
              _buildSettingRow('Courier Base Fee (USD)', '\$$_deliveryFee', () {
                _promptSetting('Delivery Fee', _deliveryFee, (val) async {
                  setState(() => _deliveryFee = val);
                  await _saveSetting({
                    'delivery_fee': val,
                    'delivery_base_fee': val,
                  });
                });
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow(String title, String val, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: AdminTheme.forestGreen,
            ),
          ),
          Row(
            children: [
              Text(
                val,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AdminTheme.terracotta,
                ),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _saveSetting(Map<String, dynamic> body) async {
    try {
      final res = await ApiService.post('/admin/settings', body);
      if (!mounted) return;
      if (res['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Setting saved')),
        );
        await _fetchAllData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'Could not save setting'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save setting: $e')),
      );
    }
  }

  void _promptSetting(
    String title,
    double current,
    FutureOr<void> Function(double) onSave,
  ) {
    String input = current.toString();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit $title'),
        content: TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(hintText: current.toString()),
          onChanged: (v) => input = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final d = double.tryParse(input);
              Navigator.pop(ctx);
              if (d != null) await onSave(d);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNewArticleDialog() {
    String title = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Publish New Article (Articashin)'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Article Title',
            hintText: 'e.g. Sustainable Dyeing Traditions',
          ),
          onChanged: (v) => title = v,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (title.isNotEmpty) {
                Navigator.pop(ctx);
                _publishArticle(title);
              }
            },
            child: const Text('Publish'),
          ),
        ],
      ),
    );
  }
}
