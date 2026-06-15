import 'package:anti_leba/features/sync/domain/sync_result.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';

abstract class TrackingRepository {
  Future<LocationPoint> saveLocally(LocationPoint point);
  Future<SyncResult> syncPending();
  Future<int> countUnsynced();
  Future<List<LocationPoint>> listRecent(String deviceId, {int limit = 10});
}
