import 'package:anti_leba/features/sms/domain/sms_alert.dart';
import 'package:anti_leba/features/sms/domain/sms_send_result.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';

abstract class SmsRepository {
  Future<SmsSendResult> sendEmergencyAlert(LocationPoint location);

  Future<SmsSendResult> retryPending();

  Future<int> countPending();

  Future<bool> wasSent(String alertId);

  Future<SimSnapshot> readSimSnapshot();
}
