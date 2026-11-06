import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'api_service.dart';

/// Lifecycle of the device GPS as far as the courier UI is concerned.
enum LocationStatus {
  idle,
  unsupported,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  tracking,
  error,
}

/// Wraps [Geolocator] and decides when a fix is worth reporting to
/// `POST /delivery/tasks/{id}/location`.
///
/// Reporting rules (deliberately conservative so the backend is not hammered):
///  * only the *active* task ever receives a report,
///  * never more than one POST per [minSendInterval],
///  * and only after the courier actually moved [minSendDistanceMeters] from
///    the last reported fix.
///
/// When GPS is unavailable (browser preview, permission denied, services off)
/// the service stays in a non-tracking status and says so. It never invents a
/// coordinate.
class LocationService extends ChangeNotifier {
  static const Duration minSendInterval = Duration(seconds: 20);
  static const double minSendDistanceMeters = 10;

  static const LocationSettings _streamSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5,
  );

  LocationStatus status = LocationStatus.idle;
  String? message;

  double? lastLat;
  double? lastLng;
  DateTime? lastFixAt;

  DateTime? lastSentAt;
  bool sending = false;

  int? _activeTaskId;
  int? _lastSentTaskId;
  double? _lastSentLat;
  double? _lastSentLng;
  StreamSubscription<Position>? _subscription;

  int? get activeTaskId => _activeTaskId;
  bool get hasFix => lastLat != null && lastLng != null;
  bool get isTracking => status == LocationStatus.tracking;

  /// The courier only reports position for the task they are working on.
  void setActiveTask(int? taskId) {
    _activeTaskId = taskId;
    notifyListeners();
  }

  /// Requests permission (once) and starts the GPS stream.
  Future<void> startTracking() async {
    if (kIsWeb) {
      _set(
        LocationStatus.unsupported,
        'Location is unavailable in the browser preview. Run the app on a mobile device to report GPS.',
      );
      return;
    }

    _set(LocationStatus.idle, 'Requesting location permission…');

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        _set(
          LocationStatus.serviceDisabled,
          'Device location services are switched off, so no position is being reported.',
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _set(
          LocationStatus.permissionDeniedForever,
          'Location permission is permanently denied. Enable it in system settings to report GPS.',
        );
        return;
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        _set(
          LocationStatus.permissionDenied,
          'Location permission denied — no position is being reported.',
        );
        return;
      }

      // Drop any previous subscription so a retry cannot leak one.
      await _cancelSubscription();

      _set(
        LocationStatus.tracking,
        _activeTaskId == null
            ? 'GPS active. Accept a task to start reporting your position.'
            : 'GPS active. Reporting your position to the active task.',
      );

      _subscription = Geolocator.getPositionStream(
        locationSettings: _streamSettings,
      ).listen(
        _onPosition,
        onError: (Object e) => _set(LocationStatus.error, 'GPS error: $e'),
      );

      await _readCurrentPosition();
    } catch (e) {
      _set(LocationStatus.error, 'Could not start GPS: $e');
    }
  }

  /// Stops the GPS stream. Safe to call when nothing is running.
  Future<void> stopTracking() async {
    await _cancelSubscription();
    if (status != LocationStatus.unsupported) {
      _set(LocationStatus.idle, 'GPS reporting paused.');
    }
  }

  /// Opens the OS app settings so a permanently denied permission can be fixed.
  /// A no-op on platforms without it.
  Future<void> openSettings() async {
    if (kIsWeb) return;
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('Could not open app settings: $e');
    }
  }

  Future<void> _cancelSubscription() async {
    final sub = _subscription;
    _subscription = null;
    if (sub != null) {
      await sub.cancel();
    }
  }

  Future<void> _readCurrentPosition() async {
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        _onPosition(last);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      _onPosition(position);
    } catch (e) {
      // The stream keeps running, so a failed one-shot read is not fatal.
      debugPrint('Current position unavailable: $e');
    }
  }

  void _onPosition(Position position) {
    if (position.latitude.isNaN || position.longitude.isNaN) return;

    lastLat = position.latitude;
    lastLng = position.longitude;
    lastFixAt = DateTime.now();
    notifyListeners();

    unawaited(_maybeReport(position.latitude, position.longitude));
  }

  /// Applies the throttle and POSTs the fix when it is actually due.
  Future<void> _maybeReport(double lat, double lng) async {
    final taskId = _activeTaskId;
    if (taskId == null || sending) return;

    final now = DateTime.now();
    final sentAt = lastSentAt;
    if (sentAt != null && _lastSentTaskId == taskId) {
      if (now.difference(sentAt) < minSendInterval) return;
      if (_distanceFromLastSent(lat, lng) < minSendDistanceMeters) return;
    }

    sending = true;
    notifyListeners();

    try {
      await ApiService.post('/delivery/tasks/$taskId/location', {
        'lat': lat,
        'lng': lng,
      });
      lastSentAt = DateTime.now();
      _lastSentTaskId = taskId;
      _lastSentLat = lat;
      _lastSentLng = lng;
    } catch (e) {
      debugPrint('Error reporting courier location: $e');
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  double _distanceFromLastSent(double lat, double lng) {
    final sentLat = _lastSentLat;
    final sentLng = _lastSentLng;
    if (sentLat == null || sentLng == null) return double.infinity;
    return Geolocator.distanceBetween(sentLat, sentLng, lat, lng);
  }

  void _set(LocationStatus next, String note) {
    status = next;
    message = note;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _subscription = null;
    super.dispose();
  }
}
