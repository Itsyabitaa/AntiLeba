import 'package:anti_leba/features/sync/domain/sync_result.dart';
import 'package:anti_leba/features/tracking/data/datasources/location_local_datasource.dart';
import 'package:anti_leba/features/tracking/data/datasources/location_remote_datasource.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';
import 'package:anti_leba/features/tracking/domain/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(this._local, this._remote);

  final LocationLocalDataSource _local;
  final LocationRemoteDataSource _remote;

  @override
  Future<LocationPoint> saveLocally(LocationPoint point) async {
    await _local.insert(point);
    return point;
  }

  @override
  Future<SyncResult> syncPending() async {
    final pending = await _local.getUnsynced();
    if (pending.isEmpty) {
      return const SyncResult(uploaded: 0, skipped: 0, remaining: 0);
    }

    final clientEventIds =
        pending.map((point) => point.clientEventId).toList();

    try {
      final response = await _remote.uploadBatch(pending);
      await _local.markSynced(clientEventIds);
      final remaining = await _local.countUnsynced();
      return SyncResult(
        uploaded: response.inserted,
        skipped: response.skipped,
        remaining: remaining,
      );
    } catch (_) {
      await _local.recordFailedAttempt(clientEventIds);
      final remaining = await _local.countUnsynced();
      return SyncResult(
        uploaded: 0,
        skipped: 0,
        remaining: remaining,
      );
    }
  }

  @override
  Future<int> countUnsynced() => _local.countUnsynced();

  @override
  Future<List<LocationPoint>> listRecent(
    String deviceId, {
    int limit = 10,
  }) {
    return _remote.fetchRecent(deviceId: deviceId, limit: limit);
  }
}
