import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_transitions.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  bool _loading = true;
  bool _busy = false;

  /// The statuses the seller may still move an order to, keyed by its current
  /// one. These must match `Order::LOCKED_STATUSES` / the validation list in
  /// `SellerController::updateOrderStatus` — sending anything else is refused
  /// with a 422.
  ///
  /// Delivery is deliberately *not* here: cash is collected by the courier at
  /// the door, and the backend now rejects a delivery with no cash recorded.
  /// The courier confirms it in their app.
  static const _transitions = {
    'pending': 'ready_for_pickup',
    'preparing': 'ready_for_pickup',
  };

  static const _nextLabel = {
    'pending': 'Mark ready for pickup',
    'preparing': 'Mark ready for pickup',
  };

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await ApiService.get('/seller/orders/${widget.orderId}');
      if (res['status'] == 'success') {
        _order = (res['data'] ?? res['order']) as Map<String, dynamic>?;
      }
    } catch (e) {
      debugPrint('Order detail: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _advance() async {
    final status = _order?['status']?.toString();
    final next = _transitions[status];
    if (next == null) return;
    setState(() => _busy = true);
    try {
      final res = await ApiService.ensureOk(
        () => ApiService.post(
          '/seller/orders/${widget.orderId}/status',
          {'status': next},
        ),
      );
      if (!mounted) return;
      setState(() => _order = (res['order'] ?? _order)!);
      _toast('Order is now ${next.replaceAll('_', ' ')}', AppColors.success);
    } on ApiException catch (e) {
      _toast(e.message, AppColors.danger);
    } catch (e) {
      debugPrint('Status advance: $e');
      _toast('Could not update the order.', AppColors.danger);
    }
    if (mounted) setState(() => _busy = false);
  }

  void _toast(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// True when the backend would accept a refund: only a completed or failed
  /// delivery has money to give back (see `Order::isRefundable`).
  bool get _canRefund {
    final status = _order?['status']?.toString() ?? '';
    return status == 'delivered' || status == 'delivery_failed';
  }

  Future<void> _refund() async {
    final amount = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RefundSheet(
        orderId: widget.orderId,
        total: _order?['total_fiat']?.toString() ?? '0',
        // Omitting the amount refunds everything the courier collected.
        collected: (_order?['delivery']?['cash_collected'])?.toString(),
      ),
    );
    if (amount == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final res = await ApiService.ensureOk(
        () => ApiService.post(
          '/seller/orders/${widget.orderId}/refund',
          {
            if (amount.isNotEmpty) 'amount': amount,
            'reason': 'Refunded by the seller from the order screen.',
          },
        ),
      );
      if (!mounted) return;
      setState(() => _order = (res['order'] ?? _order)!);
      _toast('Refunded. Stock was restored.', AppColors.success);
    } on ApiException catch (e) {
      _toast(e.message, AppColors.danger);
    } catch (e) {
      debugPrint('Refund: $e');
      _toast('Could not refund the order.', AppColors.danger);
    }
    if (mounted) setState(() => _busy = false);
  }

  Color _statusColor() {
    switch (_order?['status']?.toString()) {
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.terracotta),
        ),
      );
    }
    if (_order == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.error_outline_rounded,
          title: 'Order not found',
          subtitle: 'The order may have been removed.',
        ),
      );
    }

    final order = _order!;
    final status = order['status']?.toString() ?? '';
    final items = (order['items'] as List?) ?? [];
    final id = order['order_number'] ?? 'ORD-${order['id']}';
    final customer = order['customer'] ?? {};
    final address = order['address'] ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(id.toString()),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          FadeSlideIn(
            child: GlassCard(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(20),
              gradient: AppColors.forestGradient,
              borderColor: Colors.transparent,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x330F1A14),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
              ],
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _statusColor(),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.receipt_long_rounded,
                        color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'STATUS',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          status.replaceAll('_', ' ').toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 120),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(text: 'Buyer'),
                  Text(
                    (customer['name'] ?? 'Customer').toString(),
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    (customer['email'] ?? '').toString(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if ((address['address'] ?? '').toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      [
                        address['address'] ?? '',
                        address['city'] ?? '',
                        address['postal_code'] ?? ''
                      ].where((e) => e.isNotEmpty).join(', '),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FadeSlideIn(
            delay: const Duration(milliseconds: 220),
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionLabel(text: 'Items'),
                  ...items.map<Widget>((it) {
                    final product = it['product'] ?? {};
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              width: 44,
                              height: 44,
                              color: AppColors.sand,
                              child: product['image'] != null
                                  ? Image.network(
                                          product['image'],
                                          fit: BoxFit.cover,
                                          errorBuilder: (c, e, s) =>
                                              const Icon(
                                                  Icons.image_outlined,
                                                  size: 18,
                                                  color:
                                                      AppColors.terracotta),
                                        )
                                  : const Icon(Icons.image_outlined,
                                      size: 18,
                                      color: AppColors.terracotta),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (product['name'] ?? 'Item').toString(),
                                  style: const TextStyle(
                                    color: AppColors.forest,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Qty ${it['quantity'] ?? 1}',
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${it['price_fiat'] ?? '0'}',
                            style: const TextStyle(
                              color: AppColors.forest,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total',
                        style: TextStyle(
                          color: AppColors.forest,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '\$${order['total_fiat'] ?? '0'}',
                        style: const TextStyle(
                          color: AppColors.terracotta,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if ((order['delivery'] as Map?) != null)
            FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _DeliveryCard(delivery: order['delivery'] as Map<String, dynamic>),
              ),
            ),
          const SizedBox(height: 22),
          if (_transitions.containsKey(status))
            FadeSlideIn(
              delay: const Duration(milliseconds: 320),
              child: SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy ? null : _advance,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(_nextLabel[status]!),
                ),
              ),
            ),
          if (status == 'ready_for_pickup' || status == 'assigned' || status == 'picked_up') ...[
            const SizedBox(height: 12),
            const _WaitingHint(
              icon: Icons.pedal_bike_rounded,
              text: 'Waiting for the courier to confirm pickup in their app.',
            ),
          ],
          if (status == 'out_for_delivery') ...[
            const SizedBox(height: 12),
            const _WaitingHint(
              icon: Icons.pedal_bike_rounded,
              text: 'With the courier. They confirm delivery and record the '
                  'cash the buyer hands over.',
            ),
          ],
          if (_canRefund) ...[
            const SizedBox(height: 12),
            FadeSlideIn(
              delay: const Duration(milliseconds: 360),
              child: SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _busy ? null : _refund,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: AppColors.danger, strokeWidth: 2),
                        )
                      : const Icon(Icons.undo_rounded),
                  label: const Text('Refund this order'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Courier progress plus the cash the buyer owes, when a delivery exists.
class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard({required this.delivery});

  final Map<String, dynamic> delivery;

  @override
  Widget build(BuildContext context) {
    final status = delivery['status']?.toString() ?? 'not scheduled';
    final due = delivery['amount_due'];
    final collected = delivery['cash_collected'];
    final failure = delivery['failure_reason']?.toString();
    final variance = (collected is num && due is num)
        ? (collected - due).toDouble()
        : null;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Delivery & cash'),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.pedal_bike_rounded,
                  size: 18, color: AppColors.terracotta),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  status.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.forest,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          if (failure != null && failure.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Delivery failed: $failure',
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CashFigure(
                  label: 'Cash due',
                  value: due == null ? '—' : '\$${_money(due)}',
                ),
              ),
              Expanded(
                child: _CashFigure(
                  label: 'Collected',
                  value: collected == null ? '—' : '\$${_money(collected)}',
                ),
              ),
            ],
          ),
          if (variance != null && variance.abs() > 0.009) ...[
            const SizedBox(height: 8),
            Text(
              variance < 0
                  ? 'Short by \$${_money(variance.abs())} — the balance is still '
                      'owed to the studio.'
                  : 'Over by \$${_money(variance)} — the buyer handed over more '
                      'than the order was for.',
              style: TextStyle(
                color: variance < 0 ? AppColors.warning : AppColors.info,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _money(Object v) =>
      (v is num ? v.toDouble() : double.tryParse('$v') ?? 0)
          .toStringAsFixed(2);
}

class _CashFigure extends StatelessWidget {
  const _CashFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.forest,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Explains why there is no button to press at this stage.
class _WaitingHint extends StatelessWidget {
  const _WaitingHint({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sand.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Collects the refund amount. Returns an empty string for "refund whatever
/// was collected", which the backend treats as a full refund.
class _RefundSheet extends StatefulWidget {
  const _RefundSheet({
    required this.orderId,
    required this.total,
    this.collected,
  });

  final String orderId;
  final String total;
  final String? collected;

  @override
  State<_RefundSheet> createState() => _RefundSheetState();
}

class _RefundSheetState extends State<_RefundSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.collected ?? widget.total,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: const BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Refund order',
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.collected != null
                  ? 'The courier took \$${widget.collected}. Refunding puts the '
                      'goods back in stock and takes the cash back off their balance.'
                  : 'The buyer has not paid yet, so this cancels against the '
                      'order total of \$${widget.total}.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'AMOUNT',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '\$ ',
                filled: true,
                fillColor: AppColors.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                errorText: _error,
              ),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _submit,
                      child: const Text('Refund'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    final raw = _controller.text.trim();
    final value = double.tryParse(raw);
    if (value == null) {
      setState(() => _error = 'Enter an amount');
      return;
    }
    if (value <= 0) {
      setState(() => _error = 'Refunds must be more than zero');
      return;
    }
    Navigator.of(context).pop(value.toStringAsFixed(2));
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.4,
      ),
    );
  }
}