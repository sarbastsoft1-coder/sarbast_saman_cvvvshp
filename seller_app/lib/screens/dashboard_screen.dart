import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/routes.dart';
import '../app/theme.dart';
import '../providers/notification_provider.dart';
import '../services/api_service.dart';
import '../widgets/animated_counter.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_transitions.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _refreshCtrl;

  Map<String, dynamic> _store = {};
  Map<String, dynamic> _kpis = {};
  List<dynamic> _orders = [];
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fetchAll();
    // Also covers a session restored from a saved token, which skips login.
    NotificationProvider.instance.startPolling();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchAll();
      NotificationProvider.instance.refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    if (mounted) setState(() => _isLoading = true);
    _refreshCtrl.repeat();
    try {
      final dashboardRes = await ApiService.get('/seller/dashboard');
      final productsRes = await ApiService.get('/seller/products');
      if (!mounted) return;
      if (dashboardRes['status'] == 'success') {
        final data = dashboardRes['data'] ?? {};
        _store = data['store'] ?? {};
        _kpis = data['kpis'] ?? {};
        _orders = data['recent_orders'] ?? [];
      }
      if (productsRes['status'] == 'success') {
        _products = productsRes['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Dashboard fetch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('نەتوانرا داشبۆرد بکرێتەوە: $e')),
        );
      }
    }
    _refreshCtrl.stop();
    if (mounted) setState(() => _isLoading = false);
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'بەیانیت باش';
    if (hour < 18) return 'نیوەڕۆت باش';
    return 'ئێوارەت باش';
  }

  @override
  Widget build(BuildContext context) {
    final storeName = _store['name'] ?? 'دووکانەکەت';
    final craft = _store['craft_category'] ?? 'فرۆشیار';
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _fetchAll,
        color: AppColors.terracotta,
        child: _isLoading
            ? _LoadingState()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  _GreetingHeader(
                    greeting: _greeting,
                    storeName: storeName,
                    craft: craft,
                    onRefresh: _fetchAll,
                  ),
                  const SizedBox(height: 16),
                  _CashBanner(
                    kpis: _kpis,
                    onTap: () => context.go(AppRoutes.settlements),
                  ),
                  const SizedBox(height: 14),
                  _KpiGrid(kpis: _kpis),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    title: 'داواکارییەکان',
                    actionLabel: 'هەمووی',
                    onAction: () => context.go(AppRoutes.orders),
                  ),
                  const SizedBox(height: 10),
                  if (_orders.isEmpty)
                    _MiniEmpty(
                      icon: Icons.inbox_outlined,
                      text: 'هیچ داواکارییەک نییە. لێرە دەردەکەون.',
                    )
                  else
                    ..._orders.take(3).map((o) => FadeSlideIn(
                          delay: Duration(
                              milliseconds: 120 * _orders.indexOf(o)),
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _OrderRow(order: o),
                          ),
                        )),
                  const SizedBox(height: 22),
                  _SectionTitle(
                    title: 'بەرهەمەکان',
                    actionLabel: 'بەڕێوەبردن',
                    onAction: () => context.go(AppRoutes.products),
                  ),
                  const SizedBox(height: 10),
                  if (_products.isEmpty)
                    _MiniEmpty(
                      icon: Icons.inventory_2_outlined,
                      text: 'هێشتا هیچ بەرهەمێکت نییە.',
                    )
                  else
                    SizedBox(
                      height: 168,
                      child: StaggeredList(
                        axis: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        itemDelay: const Duration(milliseconds: 90),
                        children: _products
                            .take(6)
                            .map<Widget>((p) => SizedBox(
                                  width: 200,
                                  child: _ProductCard(product: p),
                                ))
                            .toList(),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

// ───────────────────────── Header ─────────────────────────

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({
    required this.greeting,
    required this.storeName,
    required this.craft,
    required this.onRefresh,
  });

  final String greeting;
  final String storeName;
  final String craft;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Roni',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.play_arrow_rounded,
                  color: AppColors.terracotta, size: 22),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.forest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'فرۆشیار',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'نوێکردنەوە',
                onPressed: onRefresh,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.paperSolid.withValues(alpha: 0.85),
                  side: const BorderSide(color: Color(0xF2FFFFFF)),
                ),
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '$greeting، $storeName',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.45,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            'دووکانەکەت ئەمڕۆ · $craft',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── KPI grid ─────────────────────────

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpis});
  final Map<String, dynamic> kpis;

  @override
  Widget build(BuildContext context) {
    final sales = (kpis['gross_sales'] is num)
        ? (kpis['gross_sales'] as num).toDouble()
        : 0.0;
    final tokens = (kpis['token_earnings'] is num)
        ? (kpis['token_earnings'] as num).toDouble()
        : 0.0;
    final ordersCount = (kpis['orders_count'] is num)
        ? (kpis['orders_count'] as num).toDouble()
        : 0.0;

    return StaggeredList(
      spacing: 12,
      initialDelay: const Duration(milliseconds: 100),
      children: [
        _KpiCard(
          title: 'فرۆشتنی ئەم هەفتە',
          value: '\$${sales.toStringAsFixed(2)}',
          subtitle: 'کۆی قەبارە',
          icon: Icons.attach_money_rounded,
          accent: AppColors.terracotta,
          counter: AnimatedCounter(
            value: sales,
            textBuilder: (v) => '\$${v.toDouble().toStringAsFixed(2)}',
            refreshKey: sales,
          ),
        ),
        _KpiCard(
          title: 'ڕۆنیکس',
          value: tokens.toStringAsFixed(0),
          subtitle: 'داهاتی نیشانە',
          icon: Icons.token_rounded,
          accent: AppColors.gold,
          counter: AnimatedCounter(
            value: tokens,
            textBuilder: (v) => v.toDouble().toStringAsFixed(0),
            refreshKey: tokens,
          ),
        ),
        _KpiCard(
          title: 'داواکاری',
          value: ordersCount.toStringAsFixed(0),
          subtitle: 'هەموو کات',
          icon: Icons.shopping_bag_rounded,
          accent: AppColors.info,
          counter: AnimatedCounter(
            value: ordersCount,
            textBuilder: (v) => v.toDouble().toStringAsFixed(0),
            refreshKey: ordersCount,
          ),
        ),
      ],
    );
  }
}

/// Cash-on-delivery exposure: how much buyers have handed to couriers that
/// has not reached the studio yet. Tapping through goes to the settlements.
class _CashBanner extends StatelessWidget {
  const _CashBanner({required this.kpis, required this.onTap});

  final Map<String, dynamic> kpis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    double read(String key) =>
        (kpis[key] is num) ? (kpis[key] as num).toDouble() : 0.0;

    final outstanding = read('cash_outstanding');
    final collected = read('cash_collected');
    final owed = outstanding > 0.009;

    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      gradient: AppColors.payGradient,
      borderColor: Colors.transparent,
      boxShadow: const [
        BoxShadow(
          color: Color(0x592F7FE0),
          blurRadius: 30,
          offset: Offset(0, 12),
        ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    owed ? 'پارە لە ڕێگادایە' : 'یەکشەممە دەنێردرێت',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${outstanding.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 29,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),
                Text(
                  collected > 0
                      ? '\$${collected.toStringAsFixed(0)} کۆکراوەتەوە'
                      : 'بۆ FIB / FastPay',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_outward_rounded,
              color: AppColors.terracotta,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.counter,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget counter;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                DefaultTextStyle(
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                  child: counter,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.sage,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Sections ─────────────────────────

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.terracotta,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.forest,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

class _MiniEmpty extends StatelessWidget {
  const _MiniEmpty({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.terracotta, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Order row ─────────────────────────

class _OrderRow extends StatefulWidget {
  const _OrderRow({required this.order});
  final Map<String, dynamic> order;

  @override
  State<_OrderRow> createState() => _OrderRowState();
}

class _OrderRowState extends State<_OrderRow> {
  bool _pressed = false;

  Color _statusColor() {
    switch (widget.order['status']?.toString()) {
      case 'pending':
        return AppColors.warning;
      case 'ready_for_pickup':
        return AppColors.info;
      case 'in_transit':
        return AppColors.clayOchre;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.danger;
    }
    return AppColors.textMuted;
  }

  String _statusLabel() {
    final s = (widget.order['status'] ?? 'pending').toString();
    return s.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final items = (widget.order['items'] as List?) ?? [];
    final first = items.isNotEmpty ? items[0] : null;
    final itemName = first?['product']?['name'] ?? 'Product';
    final total = widget.order['total_fiat']?.toString() ?? '0';
    final customer = widget.order['customer']?['name'] ?? 'Customer';
    final id = widget.order['order_number'] ?? 'ORD-${widget.order['id']}';

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/orders/${widget.order['id']}'),
        onHighlightChanged: (highlighted) {
          if (_pressed != highlighted && mounted) {
            setState(() => _pressed = highlighted);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$id • $customer',
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      itemName,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor().withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _statusLabel(),
                        style: TextStyle(
                          color: _statusColor(),
                          fontWeight: FontWeight.w700,
                          fontSize: 9.5,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '\$$total',
                style: const TextStyle(
                  color: AppColors.forest,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Product card ─────────────────────────

class _ProductCard extends StatefulWidget {
  const _ProductCard({required this.product});
  final Map<String, dynamic> product;

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final name = widget.product['name'] ?? 'Item';
    final price = (widget.product['sale_price_fiat'] ?? widget.product['price_fiat'])?.toString() ?? '0';
    final stock = widget.product['stock'] ?? 0;
    final img = widget.product['image'] as String?;

    return AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/products/${widget.product['id']}/edit'),
        onHighlightChanged: (highlighted) {
          if (_pressed != highlighted && mounted) {
            setState(() => _pressed = highlighted);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: img == null || img.isEmpty
                      ? Container(
                          color: AppColors.sand,
                          child: const Icon(Icons.image_outlined,
                              color: AppColors.terracotta, size: 28),
                        )
                      : Image.network(
                          img,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: AppColors.sand,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.terracotta),
                          ),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '\$$price${(widget.product['discount_percent'] as num? ?? 0) > 0 ? ' · −${widget.product['discount_percent']}%' : ''} • $stock in stock',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Loading ─────────────────────────

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              CircularProgressIndicator(
                  color: AppColors.terracotta, strokeWidth: 2.4),
              SizedBox(height: 14),
              Text(
                'Warming up the studio…',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}