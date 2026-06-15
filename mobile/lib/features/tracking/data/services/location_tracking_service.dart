import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

import 'package:anti_leba/features/tracking/data/services/location_permission_service.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';
import 'package:anti_leba/features/tracking/domain/tracking_config.dart';
import 'package:anti_leba/features/tracking/domain/tracking_repository.dart';

typedef LocationCollectedCallback = Future<void> Function(LocationPoint point);

class LocationTrackingService {
  LocationTrackingService(this._permissions, this._repository);

  final LocationPermissionService _permissions;
  final TrackingRepository _repository;

  StreamSubscription<Position>? _positionSub;
  Timer? _syncTimer;
  String? _deviceId;

  bool get isRunning => _deviceId != null;

  Future<bool> start(
    String deviceId, {
    LocationCollectedCallback? onCollected,
  }) async {
    if (_deviceId == deviceId && _positionSub != null) return true;

    await stop();

    final granted = await _permissions.ensureGranted();
    if (!granted) return false;

    if (!await _permissions.isLocationServiceEnabled()) {
      return false;
    }

    _deviceId = deviceId;
    final settings = _locationSettings();

    await _collectPosition(settings, onCollected);

    _positionSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) => _collectPosition(settings, onCollected, position: position),
      onError: (_) {},
    );

    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_repository.syncPending());
    });

    return true;
  }

  Future<void> stop() async {
    await _positionSub?.cancel();
    _positionSub = null;
    _syncTimer?.cancel();
    _syncTimer = null;
    _deviceId = null;
  }

  LocationSettings _locationSettings() {
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: TrackingConfig.interval,
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Anti-Leba location tracking',
          notificationText: 'Collecting GPS every 5 minutes',
          enableWakeLock: true,
        ),
      );
    }

    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.other,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
      );
    }

    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  Future<void> _collectPosition(
    LocationSettings settings,
    LocationCollectedCallback? onCollected, {
    Position? position,
  }) async {
    final deviceId = _deviceId;
    if (deviceId == null) return;

    try {
      final pos = position ??
          await Geolocator.getCurrentPosition(locationSettings: settings);
      final point = LocationPoint(
        deviceId: deviceId,
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        altitude: pos.altitude,
        speed: pos.speed,
        heading: pos.heading,
        recordedAt: pos.timestamp,
      );
      final saved = await _repository.saveAndSync(point);
      if (onCollected != null) {
        await onCollected(saved);
      }
    } catch (_) {
      // Keep tracking alive even if a single sample fails.
    }
  }
}
