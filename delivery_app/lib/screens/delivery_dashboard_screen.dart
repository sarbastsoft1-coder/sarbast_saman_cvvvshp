import 'dart:async';

import 'package:flutter/material.dart';
import '../main.dart'; // For DeliveryTheme
import '../services/api_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../widgets/delivery_animations.dart';
import '../widgets/route_map_view.dart';
import 'login_screen.dart';
import 'route_map_screen.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen>
    with WidgetsBindingObserver {
  static const Duration _refreshInterval = Duration(seconds: 30);
  static const List<String> _inProgressStatuses = [
    'assigned',
    'picked_up',
    'out_for_delivery',
  ];

  List<dynamic> _tasks = [];
  Map<String, dynamic> _earnings = {};
  bool _isLoading = true;
  Timer? _refreshTimer;
  final LocationService _location = LocationService();
  final NotificationService _notifications = NotificationService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.addListener(_onLocationChanged);
    _startRefreshTimer();
    _fetchTasks();
    _fetchEarnings();
    _location.startTracking();
    // Courier alerts (new pickup jobs) are polled, not pushed.
    _notifications.addListener(_onNotificationsChanged);
    _notifications.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopRefreshTimer();
    _location.removeListener(_onLocationChanged);
    unawaited(_location.stopTracking());
    _location.dispose();
    _notifications
      ..removeListener(_onNotificationsChanged)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startRefreshTimer();
      _location.startTracking();
      _notifications.start();
    } else {
      // No point polling the API or holding a GPS subscription in the background.
      _stopRefreshTimer();
      _notifications.stop();
      unawaited(_location.stopTracking());
    }
  }

  void _onNotificationsChanged() {
    if (mounted) setState(() {});
  }

  /// Bell with an unread count. Tapping opens the alert list, which clears the
  /// count once read.
  Widget _buildNotificationButton() {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          tooltip: 'Alerts',
          icon: _notifications.unreachable
              ? const Icon(Icons.notifications_off_outlined)
              : const Icon(Icons.notifications_outlined),
          onPressed: _showNotifications,
        ),
        if (_notifications.unreadCount > 0)
          Positioned(
            top: 6,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: DeliveryTheme.terracotta,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _notifications.unreadCount > 9
                    ? '9+'
                    : '${_notifications.unreadCount}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showNotifications() async {
    final alert = _notifications.latest;
    if (alert == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _notifications.unreachable
                ? 'Cannot reach the server right now.'
                : 'No alerts.',
          ),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alerts'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                alert.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(alert.body),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );

    await _notifications.markAllRead();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) => _fetchTasks(silent: true));
  }

  void _stopRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  /// The task the courier is actually working on — the first in-progress one,
  /// falling back to whatever is at the top of the list.
  Map<String, dynamic>? get _activeTask {
    for (final task in _tasks) {
      if (task is Map && _inProgressStatuses.contains(task['status'])) {
        return Map<String, dynamic>.from(task);
      }
    }
    if (_tasks.isEmpty) return null;
    final first = _tasks.first;
    return first is Map ? Map<String, dynamic>.from(first) : null;
  }

  Future<void> _fetchTasks({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }
    try {
      final res = await ApiService.get('/delivery/tasks');
      if (res['status'] == 'success') {
        _tasks = res['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching delivery tasks: $e');
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load tasks: $e')),
        );
      }
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
    final activeId = _activeTask?['id'];
    _location.setActiveTask(activeId is int ? activeId : null);
  }

  Future<void> _fetchEarnings() async {
    try {
      final res = await ApiService.get('/delivery/earnings');
      if (!mounted) return;
      if (res['status'] == 'success' && res['data'] is Map) {
        setState(() {
          _earnings = Map<String, dynamic>.from(res['data'] as Map);
        });
      }
    } catch (e) {
      debugPrint('Error fetching earnings: $e');
    }
  }

  Widget _buildEarningsCard() {
    String money(dynamic v) {
      final n = double.tryParse('$v') ?? 0;
      return '\$${n.toStringAsFixed(2)}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeliveryTheme.earthBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Earnings (pending settlements)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DeliveryTheme.forestGreen,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _earnChip('Commission', money(_earnings['courier_commission'])),
              _earnChip('Gross cash', money(_earnings['gross_cash'])),
              _earnChip('Outstanding', money(_earnings['outstanding'])),
              _earnChip(
                'Stores',
                '${_earnings['stores_count'] ?? 0}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _earnChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DeliveryTheme.sageLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: DeliveryTheme.forestGreen,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _advanceTask(Map<String, dynamic> task) async {
    String currentStatus = task['status'] ?? 'pending';
    String newStatus = currentStatus;

    if (currentStatus == 'ready_for_pickup') {
      await _claimTask(task);
      return;
    } else if (currentStatus == 'assigned') {
      newStatus = 'picked_up';
    } else if (currentStatus == 'picked_up') {
      newStatus = 'out_for_delivery';
    } else if (currentStatus == 'out_for_delivery') {
      newStatus = 'delivered';
    }

    // Cash on delivery: the courier must record what the customer actually
    // handed over before a job can be closed. The server rejects a delivery
    // with no cash record, so collect it here rather than guessing.
    double? cashCollected;
    if (newStatus == 'delivered') {
      cashCollected = await _promptForCash(task);
      if (cashCollected == null || !mounted) return;
    }

    try {
      final res = await ApiService.post('/delivery/tasks/${task['id']}/status', {
        'status': newStatus,
        if (newStatus == 'delivered') 'cash_collected': cashCollected,
      });

      if (!mounted) return;
      if (res['status'] == 'success') {
        setState(() {
          final idx = _tasks.indexWhere((t) => t['id'] == task['id']);
          if (idx != -1) {
            _tasks[idx] = res['delivery'];
            // Re-inject order back to the task for display since it might not be returned deeply nested
            _tasks[idx]['order'] = task['order']; 
          }
        });
        if (newStatus == 'delivered' && mounted) {
          final variance = res['cash_variance'];
          final dueNow = (res['cash_due'] as num?)?.toDouble() ?? cashCollected!;
          final short = variance is num && variance < 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                short
                    ? 'Delivered. ${(-variance).toStringAsFixed(2)} short of '
                        '${dueNow.toStringAsFixed(2)} — recorded for review.'
                    : 'Delivered. ${cashCollected!.toStringAsFixed(2)} collected.',
              ),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Update failed.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update the delivery. Please try again.')),
        );
      }
    }
  }

  /// Asks the courier how much cash the customer paid. Returns null if they
  /// cancel, so nothing is marked delivered by accident.
  Future<double?> _promptForCash(Map<String, dynamic> task) {
    final due = (task['amount_due'] as num?)?.toDouble();
    final controller = TextEditingController(
      text: due != null ? due.toStringAsFixed(2) : '',
    );

    return showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Collect payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              due != null
                  ? 'Amount due: ${due.toStringAsFixed(2)}'
                  : 'Enter the cash the customer handed over.',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Cash collected'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(controller.text.trim());
              if (value == null || !value.isFinite || value < 0) return;
              Navigator.pop(ctx, value);
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  /// Claim a job so cash collected against it is attributed to this courier.
  Future<void> _claimTask(Map<String, dynamic> task) async {
    try {
      final res = await ApiService.post('/delivery/tasks/${task['id']}/claim', {});
      if (res['status'] == 'success' && mounted) {
        setState(() {
          final idx = _tasks.indexWhere((t) => t['id'] == task['id']);
          if (idx != -1) {
            _tasks[idx] = res['delivery'];
            _tasks[idx]['order'] = task['order'];
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Job assigned to you.')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message']?.toString() ?? 'Could not claim this job.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not claim this job. Please try again.')),
        );
      }
    }
  }

  void _openRouteMap(Map<String, dynamic> task) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RouteMapScreen(task: task, location: _location),
      ),
    );
  }

  Future<void> _logout() async {
    _stopRefreshTimer();
    // Drop this courier's alerts so the next account starts clean.
    _notifications.reset();
    await _location.stopTracking();
    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Text('🛵 ', style: TextStyle(fontSize: 20)),
            Text('Roni Logistics & Tracking'),
          ],
        ),
        actions: [
          _buildNotificationButton(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _fetchTasks();
              _fetchEarnings();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Live Route Map Visualizer
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 60),
                        child: _buildLiveMapVisualizer(),
                      ),
                      const SizedBox(height: 16),

                      FadeSlideIn(
                        delay: const Duration(milliseconds: 90),
                        child: _buildEarningsCard(),
                      ),
                      const SizedBox(height: 16),

                      // Device GPS reporting state
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 120),
                        child: _buildLocationCard(),
                      ),
                      const SizedBox(height: 24),

                      // Active Logistics Deliveries
                      FadeSlideIn(
                        delay: const Duration(milliseconds: 180),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Current Delivery Tasks',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: DeliveryTheme.forestGreen),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: DeliveryTheme.sageLight,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${_tasks.length} Available', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeliveryTheme.forestGreen)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Delivery Tasks List
                      if (_tasks.isEmpty) const Text('No active tasks currently.')
                      else ..._tasks.asMap().entries.map(
                        (entry) => FadeSlideIn(
                          delay: Duration(milliseconds: 220 + (entry.key * 60)),
                          child: _buildTaskCard(entry.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildLiveMapVisualizer() {
    final task = _activeTask;
    final geometry = task == null
        ? RouteGeometry(pickup: null, dropoff: null, courier: null, waypoints: const [])
        : RouteGeometry.fromTask(task, liveLat: _location.lastLat, liveLng: _location.lastLng);

    final gpsTracking = _location.isTracking;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DeliveryTheme.earthBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Live Route Map', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DeliveryTheme.forestGreen)),
                      Text(
                        task == null
                            ? 'No task selected'
                            : '${task['pickup_store_name'] ?? 'Pickup'} → ${task['customer_name'] ?? 'Dropoff'}',
                        style: const TextStyle(fontSize: 11, color: Colors.black45),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: gpsTracking ? DeliveryTheme.sageLight : const Color(0xFFF1E7E3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    gpsTracking ? '● GPS Active' : '○ GPS Off',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: gpsTracking ? DeliveryTheme.forestGreen : DeliveryTheme.terracotta,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: task == null
                ? _buildNoTaskMapState()
                : RouteMapView(
                    geometry: geometry,
                    height: 220,
                    draggable: false,
                  ),
          ),
          if (task != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Column(
                children: [
                  // Cash collected on delivery is banked against the courier who
                  // claimed the job, so claiming must come first.
                  if (task['driver_id'] == null)
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: FilledButton.icon(
                        onPressed: () => _claimTask(task),
                        icon: const Icon(Icons.assignment_ind_outlined, size: 18),
                        label: const Text(
                          'Claim this job',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: DeliveryTheme.forestGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 38,
                    child: OutlinedButton.icon(
                      onPressed: () => _openRouteMap(task),
                      icon: const Icon(Icons.map_outlined, size: 18),
                      label: const Text(
                        'Open Full Route Map',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DeliveryTheme.forestGreen,
                        side: const BorderSide(color: DeliveryTheme.earthBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNoTaskMapState() {
    return Container(
      color: const Color(0xFFE7ECE8),
      padding: const EdgeInsets.all(20),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🗺️', style: TextStyle(fontSize: 28)),
            SizedBox(height: 8),
            Text(
              'No route coordinates available',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: DeliveryTheme.forestGreen),
            ),
            SizedBox(height: 4),
            Text(
              'Accept a task to see its pickup and dropoff on the map.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    final location = _location;
    final isBlocked = location.status == LocationStatus.unsupported ||
        location.status == LocationStatus.serviceDisabled ||
        location.status == LocationStatus.permissionDenied ||
        location.status == LocationStatus.permissionDeniedForever ||
        location.status == LocationStatus.error;

    final lastFix = location.hasFix
        ? '${location.lastLat!.toStringAsFixed(5)}, ${location.lastLng!.toStringAsFixed(5)}'
        : 'none yet';
    final lastSent = location.lastSentAt == null
        ? 'never'
        : _formatTimestamp(location.lastSentAt!);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeliveryTheme.earthBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PulsingStatusDot(
                    color: location.isTracking
                        ? DeliveryTheme.sageGreen
                        : DeliveryTheme.terracotta,
                    active: location.isTracking,
                  ),
                  const SizedBox(width: 8),
                  const Text('Courier GPS Reporting', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: DeliveryTheme.forestGreen)),
                ],
              ),
              Text(_statusLabel(location.status), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeliveryTheme.terracotta)),
            ],
          ),
          const SizedBox(height: 8),
          Text(location.message ?? '', style: const TextStyle(fontSize: 11, color: Colors.black54)),
          const SizedBox(height: 10),
          _buildInfoRow('Last fix', '$lastFix${location.lastFixAt == null ? '' : ' • ${_formatTimestamp(location.lastFixAt!)}'}'),
          _buildInfoRow('Last sent to backend', lastSent),
          _buildInfoRow(
            'Reporting for',
            location.activeTaskId == null
                ? 'no active task'
                : 'task #${location.activeTaskId}',
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: FilledButton.icon(
                    onPressed: () => location.isTracking ? location.stopTracking() : location.startTracking(),
                    icon: Icon(location.isTracking ? Icons.pause : Icons.my_location, size: 18),
                    label: Text(location.isTracking ? 'Pause GPS' : (isBlocked ? 'Retry' : 'Start GPS'), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              if (location.status == LocationStatus.permissionDeniedForever) ...[
                const SizedBox(width: 10),
                SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: _location.openSettings,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DeliveryTheme.forestGreen,
                      side: const BorderSide(color: DeliveryTheme.earthBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('App Settings', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: DeliveryTheme.forestGreen),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(LocationStatus status) {
    switch (status) {
      case LocationStatus.idle: return 'IDLE';
      case LocationStatus.unsupported: return 'UNAVAILABLE';
      case LocationStatus.serviceDisabled: return 'SERVICES OFF';
      case LocationStatus.permissionDenied: return 'DENIED';
      case LocationStatus.permissionDeniedForever: return 'BLOCKED';
      case LocationStatus.tracking: return _location.sending ? 'SENDING' : 'TRACKING';
      case LocationStatus.error: return 'GPS ERROR';
    }
  }

  String _formatTimestamp(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    final status = task['status'] ?? 'pending';
    final order = task['order'] ?? {};
    final orderNumber = order['order_number'] ?? 'ORD-?';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: DeliveryTheme.earthBorder),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${task['id']} • $orderNumber', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: DeliveryTheme.forestGreen)),
              // `estimated_payout` was a formatted demo string and is no longer sent by
              // the API. Show the real commission instead of an invented figure.
              Text(
                task['courier_payout'] != null
                    ? 'Payout: ${(task['courier_payout'] as num).toStringAsFixed(2)}'
                    : '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: DeliveryTheme.clayOchre,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Pickup Row
          Row(
            children: [
              const Text('📦', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pickup: ${task['pickup_store_name'] ?? 'Store'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DeliveryTheme.forestGreen)),
                    Text(task['pickup_address'] ?? 'Address', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    Text('Pickup Window: ${task['estimated_pickup_time'] ?? ''}', style: const TextStyle(fontSize: 11, color: DeliveryTheme.terracotta, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropoff Row
          Row(
            children: [
              const Text('🏡', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dropoff: ${task['customer_name'] ?? 'Customer'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: DeliveryTheme.forestGreen)),
                    Text(task['dropoff_address'] ?? 'Address', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                    Text('Target: ${task['estimated_delivery_time'] ?? ''} • ${task['distance'] ?? ''}', style: const TextStyle(fontSize: 11, color: DeliveryTheme.forestGreen, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action Button depending on status
          SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _getButtonColor(status),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: status == 'delivered' ? null : () => _advanceTask(task),
              child: Text(_getButtonText(status), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary action: route map for this task
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: () => _openRouteMap(task),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('View Route Map', style: TextStyle(fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                foregroundColor: DeliveryTheme.forestGreen,
                side: const BorderSide(color: DeliveryTheme.earthBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getButtonColor(String status) {
    switch (status) {
      case 'ready_for_pickup': return DeliveryTheme.terracotta;
      case 'assigned': return DeliveryTheme.clayOchre;
      case 'picked_up': return DeliveryTheme.forestGreen;
      case 'out_for_delivery': return DeliveryTheme.sageGreen;
      default: return Colors.grey;
    }
  }

  String _getButtonText(String status) {
    switch (status) {
      case 'ready_for_pickup': return 'Accept Task 🛵';
      case 'assigned': return 'Confirm Pickup at Workshop 📦';
      case 'picked_up': return 'Start Delivery Route 🚀';
      case 'out_for_delivery': return 'Confirm Delivered to Customer ✓';
      default: return 'Completed ✓';
    }
  }
}
