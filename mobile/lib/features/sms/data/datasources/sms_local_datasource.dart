import 'package:hive_flutter/hive_flutter.dart';

import 'package:anti_leba/features/sms/domain/sms_alert.dart';

/// Hive-backed queue for SMS alerts that failed to send.
class SmsLocalDataSource {
  SmsLocalDataSource(this._openPendingBox, this._openSentBox);

  static const String pendingBoxName = 'pending_sms_alerts';
  static const String sentBoxName = 'sent_sms_alerts';

  final Future<Box<dynamic>> Function() _openPendingBox;
  final Future<Box<dynamic>> Function() _openSentBox;

  Future<void> enqueue(SmsAlert alert) async {
    final box = await _openPendingBox();
    await box.put(alert.alertId, alert.toHiveMap());
  }

  Future<List<SmsAlert>> getPending() async {
    final box = await _openPendingBox();
    final alerts = <SmsAlert>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        alerts.add(SmsAlert.fromHiveMap(raw));
      }
    }
    return alerts;
  }

  Future<int> countPending() async {
    final box = await _openPendingBox();
    return box.length;
  }

  Future<bool> wasSent(String alertId) async {
    final sentBox = await _openSentBox();
    return sentBox.containsKey(alertId);
  }

  Future<void> markSent(String alertId) async {
    final sentBox = await _openSentBox();
    await sentBox.put(alertId, DateTime.now().toUtc().toIso8601String());
  }

  Future<void> removePending(String alertId) async {
    final box = await _openPendingBox();
    await box.delete(alertId);
  }

  Future<void> recordFailedAttempt(String alertId) async {
    final box = await _openPendingBox();
    final raw = box.get(alertId);
    if (raw is! Map) return;
    final alert = SmsAlert.fromHiveMap(raw);
    await box.put(
      alertId,
      alert
          .copyWith(
            retryCount: alert.retryCount + 1,
            lastAttemptAt: DateTime.now(),
          )
          .toHiveMap(),
    );
  }
}
