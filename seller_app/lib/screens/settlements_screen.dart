import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/glass_card.dart';
import '../widgets/page_transitions.dart';

/// Cash-on-delivery handover: what each courier is holding on the studio's
/// behalf, and confirmation that they gave it back.
///
/// Without this the seller takes cash-only orders and has no record of the
/// money physically moving, which is the whole reason `settlements` exists.
class SettlementsScreen extends StatefulWidget {
  const SettlementsScreen({super.key});

  @override
  State<SettlementsScreen> createState() => _SettlementsScreenState();
}

class _SettlementsScreenState extends State<SettlementsScreen> {
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await ApiService.get('/seller/settlements');
      if (!mounted) return;
      setState(() {
        _error = null;
        if (res['status'] == 'success') {
          _rows = ((res['data'] ?? []) as List)
              .cast<Map<String, dynamic>>()
              .toList();
        }
      });
    } catch (e) {
      debugPrint('Settlements fetch: $e');
      if (mounted) {
        setState(() => _error = 'Could not load settlements.');
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  double _sum(String key, {bool pendingOnly = true}) => _rows
      .where((r) => !pendingOnly || r['status'] == 'pending')
      .fold(0.0, (acc, r) => acc + _num(r[key]));

  @override
  Widget build(BuildContext context) {
    final outstanding = _sum('outstanding');
    final settledCount = _rows.where((r) => r['status'] != 'pending').length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('پارە'),
        actions: [
          IconButton(
            tooltip: 'نوێکردنەوە',
            onPressed: _fetch,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.terracotta))
          : _error != null
              ? EmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'بەردەست نییە',
                  subtitle: _error!,
                  action: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _fetch,
                      child: const Text('Try again'),
                    ),
                  ),
                )
              : _rows.isEmpty
                  ? const EmptyState(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'No cash to settle',
                      subtitle:
                          'When a courier delivers for cash, their balance shows '
                          'up here so you can confirm the handover.',
                    )
                  : RefreshIndicator(
                      onRefresh: _fetch,
                      color: AppColors.terracotta,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        children: [
                          FadeSlideIn(
                            child: _SummaryCard(
                              outstanding: outstanding,
                              settledCount: settledCount,
                            ),
                          ),
                          const SizedBox(height: 18),
                          for (int i = 0; i < _rows.length; i++)
                            FadeSlideIn(
                              delay: Duration(milliseconds: 60 * i),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _SettlementCard(
                                  row: _rows[i],
                                  onSettle: _settle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Future<void> _settle(Map<String, dynamic> row) async {
    final notes = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SettleSheet(
        courierName: row['courier_name']?.toString() ?? 'This courier',
        outstanding: _num(row['outstanding']),
        commission: _num(row['courier_commission']),
        refundSurplus: _num(row['refund_surplus']),
      ),
    );
    if (notes == null || !mounted) return;

    try {
      await ApiService.ensureOk(
        () => ApiService.post(
          '/seller/settlements/${row['id']}/settle',
          {
            'notes': notes,
            // The backend refuses a hand-over that is short by more than a
            // cent. The sheet only offers this when the seller says so.
            'accept_shortfall': true,
          },
        ),
      );
      if (!mounted) return;
      _toast('Handover recorded.', AppColors.success);
      _fetch();
    } on ApiException catch (e) {
      _toast(e.message, AppColors.danger);
    } catch (e) {
      debugPrint('Settle: $e');
      _toast('Could not record the handover.', AppColors.danger);
    }
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
}

/// Total money the couriers are currently sitting on.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.outstanding, required this.settledCount});

  final double outstanding;
  final int settledCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.forestGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330F1A14),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HELD BY COURIERS',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${outstanding.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            outstanding > 0
                ? 'Collected from buyers, not yet handed over.'
                : 'Every courier has handed their cash over.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          if (settledCount > 0) ...[
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$settledCount settled',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettlementCard extends StatelessWidget {
  const _SettlementCard({required this.row, required this.onSettle});

  final Map<String, dynamic> row;
  final void Function(Map<String, dynamic>) onSettle;

  @override
  Widget build(BuildContext context) {
    final status = row['status']?.toString() ?? 'pending';
    final pending = status == 'pending';
    final outstanding = _num(row['outstanding']);
    final surplus = _num(row['refund_surplus']);
    final settledAt = row['settled_at']?.toString();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.terracotta.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Text('🛵', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (row['courier_name'] ?? 'Courier').toString(),
                      style: const TextStyle(
                        color: AppColors.forest,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${row['deliveries_count'] ?? 0} '
                      '${(row['deliveries_count'] == 1) ? 'delivery' : 'deliveries'}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (pending ? AppColors.warning : AppColors.success)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pending ? 'PENDING' : status.toUpperCase(),
                  style: TextStyle(
                    color: pending ? AppColors.warning : AppColors.success,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Figure(
                  label: 'Collected',
                  value: '\$${_num(row['gross_cash']).toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _Figure(
                  label: 'Courier fee',
                  value:
                      '\$${_num(row['courier_commission']).toStringAsFixed(2)}',
                ),
              ),
              Expanded(
                child: _Figure(
                  label: 'Net to you',
                  value: '\$${_num(row['net_to_store']).toStringAsFixed(2)}',
                ),
              ),
            ],
          ),
          if (_num(row['refunded_cash']) > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.undo_rounded,
                    size: 14, color: AppColors.danger),
                const SizedBox(width: 6),
                Text(
                  'Refunded \$${_num(row['refunded_cash']).toStringAsFixed(2)} '
                  'to buyers',
                  style: const TextStyle(
                    color: AppColors.danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (surplus > 0) ...[
            const SizedBox(height: 12),
            const _Notice(
              color: AppColors.danger,
              text: 'Refunds are higher than the cash this courier took. '
                  'Reconcile the difference before settling.',
            ),
          ] else if (pending && outstanding > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: AppColors.warning),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '\$${outstanding.toStringAsFixed(2)} still to hand over',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (!pending) ...[
            const SizedBox(height: 12),
            Text(
              settledAt == null
                  ? 'Handover recorded.'
                  : 'Settled ${_prettyDate(settledAt)}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ] else ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: surplus > 0 ? null : () => onSettle(row),
                child: Text(
                  surplus > 0 ? 'Reconcile first' : 'Confirm handover',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Confirms a hand-over, with a note for the audit trail.
class _SettleSheet extends StatefulWidget {
  const _SettleSheet({
    required this.courierName,
    required this.outstanding,
    required this.commission,
    required this.refundSurplus,
  });

  final String courierName;
  final double outstanding;
  final double commission;
  final double refundSurplus;

  @override
  State<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<_SettleSheet> {
  final _notes = TextEditingController();
  bool _acknowledgeShort = false;
  late final bool _needsAck =
      widget.outstanding > 0.009 && widget.refundSurplus <= 0.009;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
              'Confirm hand-over',
              style: TextStyle(
                color: AppColors.forest,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.outstanding > 0.009
                  ? '${widget.courierName} is holding '
                      '\$${widget.outstanding.toStringAsFixed(2)} of your money.'
                  : '${widget.courierName} has handed over everything and '
                      'earns \$${widget.commission.toStringAsFixed(2)} '
                      'commission.',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'NOTE (OPTIONAL)',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. counted at the studio, 2 October',
                filled: true,
                fillColor: AppColors.paper,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            if (_needsAck) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _acknowledgeShort,
                        activeColor: AppColors.warning,
                        onChanged: (v) =>
                            setState(() => _acknowledgeShort = v ?? false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'I have counted this cash and the difference is already '
                        'accounted for.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                        backgroundColor: AppColors.terracotta,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: (_needsAck && !_acknowledgeShort)
                          ? null
                          : () => Navigator.of(context).pop(_notes.text.trim()),
                      child: const Text('Confirm'),
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
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

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
            fontSize: 9,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.forest,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.color, required this.text});

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      ),
    );
  }
}

double _num(Object? v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}

/// `settled_at` arrives as an ISO string; show just the day.
String _prettyDate(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  return '${parsed.day}/${parsed.month}/${parsed.year}';
}
