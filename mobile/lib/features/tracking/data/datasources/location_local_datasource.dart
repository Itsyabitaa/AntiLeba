import 'package:hive_flutter/hive_flutter.dart';

import 'package:anti_leba/features/tracking/domain/location_point.dart';

/// Hive-backed queue of GPS fixes waiting for upload (Sprint 4).
class LocationLocalDataSource {
  LocationLocalDataSource(this._openBox);

  static const String boxName = 'pending_locations';

  final Future<Box<dynamic>> Function() _openBox;

  Future<void> insert(LocationPoint point) async {
    final box = await _openBox();
    await box.put(point.clientEventId, point.toHiveMap());
  }

  Future<List<LocationPoint>> getUnsynced({int limit = 100}) async {
    final box = await _openBox();
    final points = <LocationPoint>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        points.add(LocationPoint.fromHiveMap(raw));
      }
    }
    points.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    if (points.length <= limit) return points;
    return points.sublist(0, limit);
  }

  Future<int> countUnsynced() async {
    final box = await _openBox();
    return box.length;
  }

  Future<void> markSynced(List<String> clientEventIds) async {
    if (clientEventIds.isEmpty) return;
    final box = await _openBox();
    await box.deleteAll(clientEventIds);
  }

  Future<void> purgeExceptDevice(String deviceId) async {
    final box = await _openBox();
    final staleKeys = <dynamic>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is! Map) {
        staleKeys.add(key);
        continue;
      }
      if (LocationPoint.fromHiveMap(raw).deviceId != deviceId) {
        staleKeys.add(key);
      }
    }
    if (staleKeys.isNotEmpty) {
      await box.deleteAll(staleKeys);
    }
  }

  Future<void> recordFailedAttempt(List<String> clientEventIds) async {
    if (clientEventIds.isEmpty) return;
    final box = await _openBox();
    final now = DateTime.now();
    for (final id in clientEventIds) {
      final raw = box.get(id);
      if (raw is! Map) continue;
      final point = LocationPoint.fromHiveMap(raw);
      await box.put(
        id,
        point
            .copyWith(
              retryCount: point.retryCount + 1,
              lastAttemptAt: now,
            )
            .toHiveMap(),
      );
    }
  }
}
