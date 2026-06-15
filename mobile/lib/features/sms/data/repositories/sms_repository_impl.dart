import 'package:anti_leba/core/env/app_env.dart';
import 'package:anti_leba/core/logging/app_logger.dart';
import 'package:anti_leba/features/sms/data/datasources/sms_local_datasource.dart';
import 'package:anti_leba/features/sms/data/services/battery_status_service.dart';
import 'package:anti_leba/features/sms/data/services/sim_status_service.dart';
import 'package:anti_leba/features/sms/data/services/sms_message_formatter.dart';
import 'package:anti_leba/features/sms/data/services/sms_permission_service.dart';
import 'package:anti_leba/features/sms/data/services/sms_send_service.dart';
import 'package:anti_leba/features/sms/domain/sms_alert.dart';
import 'package:anti_leba/features/sms/domain/sms_config.dart';
import 'package:anti_leba/features/sms/domain/sms_repository.dart';
import 'package:anti_leba/features/sms/domain/sms_send_result.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';

class SmsRepositoryImpl implements SmsRepository {
  SmsRepositoryImpl(
    this._local,
    this._permissions,
    this._battery,
    this._sim,
    this._formatter,
    this._sender,
  );

  final SmsLocalDataSource _local;
  final SmsPermissionService _permissions;
  final BatteryStatusService _battery;
  final SimStatusService _sim;
  final SmsMessageFormatter _formatter;
  final SmsSendService _sender;

  @override
  Future<SimSnapshot> readSimSnapshot() => _sim.readSnapshot();

  @override
  Future<bool> wasSent(String alertId) => _local.wasSent(alertId);

  @override
  Future<int> countPending() => _local.countPending();

  @override
  Future<SmsSendResult> sendEmergencyAlert(LocationPoint location) async {
    if (await _local.wasSent(location.clientEventId)) {
      final remaining = await _local.countPending();
      return SmsSendResult(
        sent: 0,
        queued: 0,
        skipped: 1,
        remaining: remaining,
      );
    }

    if (AppEnv.emergencySmsNumber.isEmpty) {
      AppLogger.I.w('EMERGENCY_SMS_NUMBER not configured — skipping SMS');
      return SmsSendResult(
        sent: 0,
        queued: 0,
        skipped: 0,
        remaining: await _local.countPending(),
        error: 'Emergency number not configured',
      );
    }

    if (!await _permissions.ensureGranted()) {
      return SmsSendResult(
        sent: 0,
        queued: 0,
        skipped: 0,
        remaining: await _local.countPending(),
        error: 'SMS permission denied',
      );
    }

    final alert = await _buildAlert(location);
    return _attemptSend(alert);
  }

  @override
  Future<SmsSendResult> retryPending() async {
    final pending = await _local.getPending();
    if (pending.isEmpty) {
      return const SmsSendResult.idle();
    }

    if (AppEnv.emergencySmsNumber.isEmpty) {
      return SmsSendResult(
        sent: 0,
        queued: 0,
        skipped: 0,
        remaining: pending.length,
        error: 'Emergency number not configured',
      );
    }

    if (!await _permissions.ensureGranted()) {
      return SmsSendResult(
        sent: 0,
        queued: 0,
        skipped: 0,
        remaining: pending.length,
        error: 'SMS permission denied',
      );
    }

    var sent = 0;
    var skipped = 0;

    for (final alert in pending) {
      if (alert.retryCount >= SmsConfig.maxAttempts) {
        skipped += 1;
        continue;
      }

      final result = await _attemptSend(alert);
      sent += result.sent;
      skipped += result.skipped;
    }

    final remaining = await _local.countPending();
    return SmsSendResult(
      sent: sent,
      queued: 0,
      skipped: skipped,
      remaining: remaining,
    );
  }

  Future<SmsAlert> _buildAlert(LocationPoint location) async {
    final battery = await _battery.readLevelPercent();
    final sim = await _sim.readSnapshot();
    const recipient = AppEnv.emergencySmsNumber;
    final alert = SmsAlert.fromLocation(
      alertId: location.clientEventId,
      deviceId: location.deviceId,
      latitude: location.latitude,
      longitude: location.longitude,
      batteryPercent: battery < 0 ? 0 : battery,
      sim: sim,
      timestamp: location.recordedAt,
      recipient: recipient,
      body: '',
    );
    final body = _formatter.format(alert);
    return SmsAlert.fromLocation(
      alertId: alert.alertId,
      deviceId: alert.deviceId,
      latitude: alert.latitude,
      longitude: alert.longitude,
      batteryPercent: alert.batteryPercent,
      sim: sim,
      timestamp: alert.timestamp,
      recipient: recipient,
      body: body,
    );
  }

  Future<SmsSendResult> _attemptSend(SmsAlert alert) async {
    try {
      await _sender.send(to: alert.recipient, message: alert.body);
      await _local.markSent(alert.alertId);
      await _local.removePending(alert.alertId);
      return SmsSendResult(
        sent: 1,
        queued: 0,
        skipped: 0,
        remaining: await _local.countPending(),
      );
    } catch (error, stackTrace) {
      AppLogger.I.e(
        'SMS send failed',
        error: error,
        stackTrace: stackTrace,
      );
      await _local.enqueue(alert);
      await _local.recordFailedAttempt(alert.alertId);
      return SmsSendResult(
        sent: 0,
        queued: 1,
        skipped: 0,
        remaining: await _local.countPending(),
        error: error.toString(),
      );
    }
  }
}
