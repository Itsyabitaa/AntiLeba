import 'package:anti_leba/features/tracking/domain/location_point.dart';

abstract class TrackingRepository {
  Future<LocationPoint> saveAndSync(LocationPoint point);
  Future<int> syncPending();
  Future<int> countUnsynced();
  Future<List<LocationPoint>> listRecent(String deviceId, {int limit = 10});
}
