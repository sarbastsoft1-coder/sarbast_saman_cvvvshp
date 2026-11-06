import 'package:flutter/material.dart';

import '../main.dart'; // For DeliveryTheme
import '../services/location_service.dart';
import '../widgets/route_map_view.dart';

/// Full screen route map for a single delivery task.
///
/// Shows pickup, dropoff, waypoints and the courier's position. When a
/// [LocationService] is supplied the courier marker follows the real device
/// fix instead of the last position stored on the task.
class RouteMapScreen extends StatefulWidget {
  const RouteMapScreen({super.key, required this.task, this.location});

  final Map<String, dynamic> task;
  final LocationService? location;

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  @override
  void initState() {
    super.initState();
    widget.location?.addListener(_onLocationChanged);
  }

  @override
  void dispose() {
    widget.location?.removeListener(_onLocationChanged);
    super.dispose();
  }

  void _onLocationChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final order = task['order'] ?? {};
    final orderNumber = order['order_number'] ?? 'Task ${task['id']}';
    final geometry = RouteGeometry.fromTask(
      task,
      liveLat: widget.location?.lastLat,
      liveLng: widget.location?.lastLng,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(child: RouteMapView(geometry: geometry)),
                Positioned(
                  left: 12,
                  top: 12,
                  right: 12,
                  child: _buildTaskSummary(orderNumber),
                ),
              ],
            ),
          ),
          _buildLocationFooter(),
        ],
      ),
    );
  }

  Widget _buildTaskSummary(String orderNumber) {
    final task = widget.task;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: DeliveryTheme.earthBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$orderNumber • ${task['status'] ?? 'pending'}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: DeliveryTheme.forestGreen,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📦 ${task['pickup_store_name'] ?? 'Pickup'}  →  🏡 ${task['customer_name'] ?? 'Dropoff'}',
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationFooter() {
    final location = widget.location;
    final hasFix = location?.hasFix ?? false;
    final text = !hasFix
        ? 'No live GPS fix — showing the last position stored on this task.'
        : 'Live GPS fix: ${location!.lastLat!.toStringAsFixed(5)}, '
            '${location.lastLng!.toStringAsFixed(5)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: DeliveryTheme.earthBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          const Row(
            children: [
              _LegendDot(color: DeliveryTheme.clayOchre, label: 'Pickup'),
              SizedBox(width: 12),
              _LegendDot(color: DeliveryTheme.forestGreen, label: 'Courier'),
              SizedBox(width: 12),
              _LegendDot(color: DeliveryTheme.terracotta, label: 'Dropoff'),
              SizedBox(width: 12),
              _LegendDot(color: DeliveryTheme.sageGreen, label: 'Waypoint'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.black45)),
      ],
    );
  }
}
