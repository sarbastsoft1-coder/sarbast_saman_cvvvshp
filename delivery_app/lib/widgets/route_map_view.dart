import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../main.dart'; // For DeliveryTheme

/// The coordinates we were able to read off a delivery task, already validated.
///
/// Every field is nullable on purpose: the backend may not have stored any of
/// them, and we must never invent a position.
class RouteGeometry {
  RouteGeometry({
    required this.pickup,
    required this.dropoff,
    required this.courier,
    required this.waypoints,
  });

  final LatLng? pickup;
  final LatLng? dropoff;
  final LatLng? courier;
  final List<LatLng> waypoints;

  List<LatLng> get markers => [
        ?pickup,
        ...waypoints,
        ?courier,
        ?dropoff,
      ];

  /// pickup -> waypoints -> courier -> dropoff, with repeats removed.
  List<LatLng> get line {
    final ordered = [
      ?pickup,
      ...waypoints,
      ?courier,
      ?dropoff,
    ];
    return _dedupe(ordered);
  }

  bool get isEmpty => markers.isEmpty;

  /// True when every coordinate collapses onto the same spot, so a fitted
  /// camera would be meaningless.
  bool get isCollapsed {
    if (markers.length < 2) return true;
    final first = markers.first;
    for (final point in markers) {
      if ((point.latitude - first.latitude).abs() > 0.00005 ||
          (point.longitude - first.longitude).abs() > 0.00005) {
        return false;
      }
    }
    return true;
  }

  /// Explains *why* there is nothing to draw, honestly.
  String get emptyReason {
    if (isEmpty) {
      return 'This task has no pickup, dropoff or courier coordinates stored yet.';
    }
    if (isCollapsed) {
      return 'All coordinates for this task are identical, so there is no route to draw.';
    }
    return '';
  }

  static List<LatLng> _dedupe(List<LatLng> points) {
    final result = <LatLng>[];
    for (final point in points) {
      if (result.isEmpty ||
          (result.last.latitude - point.latitude).abs() > 0.000001 ||
          (result.last.longitude - point.longitude).abs() > 0.000001) {
        result.add(point);
      }
    }
    return result;
  }

  /// Reads a task map defensively — every field may be null, absent, or a
  /// string. [liveLat]/[liveLng] override the stored courier position with the
  /// real device fix when we have one.
  static RouteGeometry fromTask(
    Map<String, dynamic> task, {
    double? liveLat,
    double? liveLng,
  }) {
    final storedCourier = _toLatLng(task['current_lat'], task['current_lng']);
    final courier = _toLatLng(liveLat, liveLng) ?? storedCourier;

    return RouteGeometry(
      pickup: _toLatLng(task['pickup_lat'], task['pickup_lng']),
      dropoff: _toLatLng(task['dropoff_lat'], task['dropoff_lng']),
      courier: courier,
      waypoints: parseWaypoints(task['waypoints']),
    );
  }

  /// `waypoints` is a JSON array but may arrive already decoded, as a raw JSON
  /// string, or as null. Entries are `{"lat":..,"lng":..}`, `[lat, lng]` or
  /// `"lat,lng"`.
  static List<LatLng> parseWaypoints(Object? raw) {
    Object? value = raw;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return const [];
      try {
        value = jsonDecode(trimmed);
      } catch (_) {
        return const [];
      }
    }
    if (value is! List) return const [];

    final points = <LatLng>[];
    for (final entry in value) {
      final point = _parseWaypoint(entry);
      if (point != null) points.add(point);
    }
    return points;
  }

  static LatLng? _parseWaypoint(Object? entry) {
    if (entry is List && entry.length >= 2) {
      return _toLatLng(entry[0], entry[1]);
    }
    if (entry is Map) {
      return _toLatLng(
        entry['lat'] ?? entry['latitude'],
        entry['lng'] ?? entry['lon'] ?? entry['longitude'],
      );
    }
    if (entry is String) {
      final parts = entry.split(',');
      if (parts.length >= 2) return _toLatLng(parts[0], parts[1]);
    }
    return null;
  }

  static LatLng? _toLatLng(Object? lat, Object? lng) {
    final parsedLat = _toDouble(lat);
    final parsedLng = _toDouble(lng);
    if (parsedLat == null || parsedLng == null) return null;
    if (parsedLat.abs() > 90 || parsedLng.abs() > 180) return null;
    return LatLng(parsedLat, parsedLng);
  }

  static double? _toDouble(Object? value) {
    if (value is num) {
      final result = value.toDouble();
      return result.isNaN || result.isInfinite ? null : result;
    }
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}

/// A real OpenStreetMap view of one delivery task.
///
/// Renders the pickup, dropoff, courier and waypoint markers plus a polyline
/// through them, and falls back to an honest empty state when the task has no
/// usable coordinates.
class RouteMapView extends StatelessWidget {
  const RouteMapView({
    super.key,
    required this.geometry,
    this.height,
    this.showAttribution = true,
    this.draggable = true,
  });

  final RouteGeometry geometry;
  final double? height;
  final bool showAttribution;

  /// When `false` the map only zooms, so the surrounding scroll view keeps
  /// panning. Used for the inline map on the dashboard.
  final bool draggable;

  @override
  Widget build(BuildContext context) {
    if (geometry.isEmpty || geometry.isCollapsed) {
      return _buildEmptyState();
    }

    final line = geometry.line;
    final markers = <Marker>[
      if (geometry.pickup != null)
        Marker(
          point: geometry.pickup!,
          width: 40,
          height: 40,
          child: _buildMarkerPin('🏪', DeliveryTheme.clayOchre),
        ),
      for (final point in geometry.waypoints)
        Marker(
          point: point,
          width: 28,
          height: 28,
          child: _buildMarkerPin('•', DeliveryTheme.sageGreen, fontSize: 16),
        ),
      if (geometry.courier != null)
        Marker(
          point: geometry.courier!,
          width: 44,
          height: 44,
          child: _buildMarkerPin('🛵', DeliveryTheme.forestGreen),
        ),
      if (geometry.dropoff != null)
        Marker(
          point: geometry.dropoff!,
          width: 40,
          height: 40,
          child: _buildMarkerPin('🏡', DeliveryTheme.terracotta),
        ),
    ];

    return FlutterMap(
      options: MapOptions(
        initialCenter: geometry.markers.first,
        initialZoom: 15,
        initialCameraFit: CameraFit.coordinates(
          coordinates: geometry.markers,
          padding: const EdgeInsets.all(40),
          maxZoom: 17,
        ),
        minZoom: 2,
        maxZoom: 18,
        backgroundColor: const Color(0xFFE7ECE8),
        interactionOptions: InteractionOptions(
          flags: draggable
              ? InteractiveFlag.all & ~InteractiveFlag.rotate
              : InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.earthshop.delivery_app',
        ),
        if (line.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: line,
                strokeWidth: 4,
                color: DeliveryTheme.terracotta,
                borderColor: Colors.white,
                borderStrokeWidth: 2,
              ),
            ],
          ),
        MarkerLayer(markers: markers),
        if (showAttribution)
          const RichAttributionWidget(
            attributions: [TextSourceAttribution('OpenStreetMap contributors')],
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xFFE7ECE8),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🗺️', style: TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            const Text(
              'No route coordinates available',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: DeliveryTheme.forestGreen,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              geometry.emptyReason,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkerPin(String icon, Color color, {double fontSize = 18}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: Center(
        child: Text(icon, style: TextStyle(fontSize: fontSize)),
      ),
    );
  }
}
