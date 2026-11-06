import 'package:flutter/material.dart';
import '../theme/earth_theme.dart';
import '../utils/animations.dart';
import '../widgets/glass_container.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final res = await ApiService.get('/orders');
      if (res['status'] == 'success') {
        setState(() {
          _orders = res['data'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error fetching orders: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return EarthTheme.warning;
      case 'processing':
      case 'preparing':
        return EarthTheme.clayOchre;
      case 'shipped':
      case 'in_transit':
        return EarthTheme.sageGreen;
      case 'delivered':
      case 'completed':
        return EarthTheme.success;
      case 'cancelled':
        return EarthTheme.danger;
      default:
        return EarthTheme.muted;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.schedule_rounded;
      case 'processing':
      case 'preparing':
        return Icons.local_florist_rounded;
      case 'shipped':
      case 'in_transit':
        return Icons.local_shipping_rounded;
      case 'delivered':
      case 'completed':
        return Icons.check_circle_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EarthTheme.warmSand,
      appBar: AppBar(
        backgroundColor: EarthTheme.warmSand,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'My Orders',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.w800,
            color: EarthTheme.forestGreen,
            letterSpacing: -0.3,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: EarthTheme.terracotta),
            )
          : _orders.isEmpty
              ? _buildEmpty()
              : Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                      itemCount: _orders.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        return StaggeredItem(
                          index: i,
                          child: _OrderCard(
                            order: _orders[i],
                            statusColor: _statusColor,
                            statusIcon: _statusIcon,
                          ),
                        );
                      },
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [EarthTheme.sageLight, EarthTheme.ochreLight],
              ),
              boxShadow: [
                BoxShadow(
                  color: EarthTheme.sageGreen.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Center(
              child: Text('📦', style: TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: EarthTheme.forestGreen,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Your future artisan orders will appear here',
            style: TextStyle(
              fontSize: 13,
              color: EarthTheme.muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final dynamic order;
  final Color Function(String) statusColor;
  final IconData Function(String) statusIcon;

  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status']?.toString() ?? 'pending';
    final statusC = statusColor(status);
    final items = order['items'] as List? ?? [];
    final total = (order['total_amount_fiat'] as num?)?.toDouble() ?? 0;
    final orderNum = order['id']?.toString() ?? '0000';
    final createdAt = order['created_at']?.toString() ?? '';

    return PressScale(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          builder: (_) => _OrderDetailSheet(
            order: order,
            statusColor: statusC,
            statusIcon: statusIcon(status),
            statusText: status,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(EarthTheme.radiusLg),
          border: Border.all(color: EarthTheme.borderLight),
          boxShadow: EarthTheme.subtleShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #$orderNum',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: EarthTheme.charcoal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: EarthTheme.muted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: statusC.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon(status), color: statusC, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusC,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: EarthTheme.borderLight),
            const SizedBox(height: 14),

            // Items preview
            SizedBox(
              height: 56,
              child: Stack(
                children: [
                  for (int i = 0; i < items.length.clamp(0, 4); i++)
                    Positioned(
                      left: i * 36.0,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: EarthTheme.warmSandLight,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            items[i]['emoji']?.toString() ?? '📦',
                            style: const TextStyle(fontSize: 22),
                          ),
                        ),
                      ),
                    ),
                  if (items.length > 4)
                    Positioned(
                      left: 4 * 36.0,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: EarthTheme.terracotta,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2.5),
                        ),
                        child: Center(
                          child: Text(
                            '+${items.length - 4}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${items.length} item${items.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: EarthTheme.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '\$${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: EarthTheme.forestGreen,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso);
      final months = [
        'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
    } catch (_) {
      return iso;
    }
  }
}

class _OrderDetailSheet extends StatelessWidget {
  final dynamic order;
  final Color statusColor;
  final IconData statusIcon;
  final String statusText;
  const _OrderDetailSheet({
    required this.order,
    required this.statusColor,
    required this.statusIcon,
    required this.statusText,
  });

  @override
  Widget build(BuildContext context) {
    final items = order['items'] as List? ?? [];
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: EarthTheme.warmSand,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EarthTheme.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Order #${order['id']}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: EarthTheme.forestGreen,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const Spacer(),
                  PillBadge(
                    label: statusText,
                    color: statusColor,
                    icon: statusIcon,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: EarthTheme.warmSandLight,
                            borderRadius: BorderRadius.circular(13),
                          ),
                          child: Center(
                            child: Text(
                              item['emoji']?.toString() ?? '📦',
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['name']?.toString() ?? 'Item',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Qty: ${item['quantity'] ?? 1}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: EarthTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${((item['price'] as num?)?.toDouble() ?? 0 * (item['quantity'] ?? 1)).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: EarthTheme.forestGreen,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        );
      },
    );
  }
}
