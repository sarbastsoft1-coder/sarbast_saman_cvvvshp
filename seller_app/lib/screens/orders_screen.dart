import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/page_transitions.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<dynamic> _orders = [];
  bool _isLoading = true;
  String _filter = 'all';

  /// Keys are real `orders.status` values — a filter on a status the backend
  /// never writes simply matches nothing, which is how the shipping tab used
  /// to sit permanently empty.
  static const _filters = [
    {'key': 'all', 'label': 'All'},
    {'key': 'pending', 'label': 'New'},
    {'key': 'ready_for_pickup', 'label': 'Ready'},
    {'key': 'out_for_delivery', 'label': 'Shipping'},
    {'key': 'delivered', 'label': 'Delivered'},
    {'key': 'delivery_failed', 'label': 'Failed'},
  ];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final res = await ApiService.get('/seller/orders');
      if (res['status'] == 'success') {
        _orders = res['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Orders fetch: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('نەتوانرا داواکارییەکان بکرێنەوە: $e')),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<dynamic> get _filteredOrders {
    if (_filter == 'all') return _orders;
    return _orders
        .where((o) => o['status']?.toString() == _filter)
        .toList();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
      case 'preparing':
        return AppColors.warning;
      case 'ready_for_pickup':
      case 'assigned':
      case 'picked_up':
        return AppColors.info;
      case 'out_for_delivery':
        return AppColors.clayOchre;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
      case 'refunded':
      case 'delivery_failed':
        return AppColors.danger;
    }
    return AppColors.textMuted;
  }

  String _statusLabel(String s) => s.replaceAll('_', ' ').toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('داواکارییەکان'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetch,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, i) {
                final f = _filters[i];
                final active = f['key'] == _filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Center(
                    child: ChoiceChip(
                      label: Text(f['label']!),
                      selected: active,
                      onSelected: (_) =>
                          setState(() => _filter = f['key']!),
                      selectedColor: AppColors.terracotta,
                      backgroundColor: AppColors.paper,
                      labelStyle: TextStyle(
                        color: active ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: active
                              ? AppColors.terracotta
                              : AppColors.border,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                        color: AppColors.terracotta))
                : _filteredOrders.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long_rounded,
                        title: 'Nothing here yet',
                        subtitle:
                            'New orders show up here as soon as a buyer purchases from your studio.',
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: _filteredOrders.length,
                        itemBuilder: (context, i) {
                          final order =
                              _filteredOrders[i] as Map<String, dynamic>;
                          return FadeSlideIn(
                            delay: Duration(milliseconds: 70 * i),
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 12),
                              child: _OrderCard(
                                order: order,
                                statusColor:
                                    _statusColor(order['status'] ?? ''),
                                statusLabel: _statusLabel(
                                    order['status']?.toString() ?? ''),
                                onTap: () => context.push(
                                    '/orders/${order['id']}'),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.statusColor,
    required this.statusLabel,
    required this.onTap,
  });

  final Map<String, dynamic> order;
  final Color statusColor;
  final String statusLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final items = (order['items'] as List?) ?? [];
    final first = items.isNotEmpty ? items[0] : null;
    final itemName = first?['product']?['name'] ?? 'Product';
    final itemCount = items.length;
    final total = order['total_fiat']?.toString() ?? '0';
    final customer = order['customer']?['name'] ?? 'Customer';
    final id = order['order_number'] ?? 'ORD-${order['id']}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '$id • $customer',
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
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
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.local_florist_rounded,
                    size: 14, color: AppColors.terracotta),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    itemCount > 1
                        ? '$itemName + ${itemCount - 1} more'
                        : itemName,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }
}