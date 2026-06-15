import 'package:anti_leba/features/tracking/data/datasources/location_local_datasource.dart';
import 'package:anti_leba/features/tracking/data/datasources/location_remote_datasource.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';
import 'package:anti_leba/features/tracking/domain/tracking_repository.dart';

class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(this._local, this._remote);

  final LocationLocalDataSource _local;
  final LocationRemoteDataSource _remote;

  @override
  Future<LocationPoint> saveAndSync(LocationPoint point) async {
    final localId = await _local.insert(point);
    final stored = point.copyWith(localId: localId);

    try {
      await _remote.upload(stored);
      await _local.markSynced(<int>[localId]);
      return stored;
    } catch (_) {
      return stored;
    }
  }

  @override
  Future<int> syncPending() async {
    final pending = await _local.getUnsynced();
    if (pending.isEmpty) return 0;

    try {
      await _remote.uploadBatch(pending);
      final ids = pending
          .map((point) => point.localId)
          .whereType<int>()
          .toList();
      await _local.markSynced(ids);
      return ids.length;
    } catch (_) {
      return 0;
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
