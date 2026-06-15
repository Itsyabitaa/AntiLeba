import 'package:dio/dio.dart';

import 'package:anti_leba/core/env/app_env.dart';
import 'package:anti_leba/core/logging/app_logger.dart';
import 'package:anti_leba/features/sim/data/datasources/sim_remote_datasource.dart';
import 'package:anti_leba/features/sim/domain/sim_config.dart';
import 'package:anti_leba/features/sim/domain/sim_repository.dart';
import 'package:anti_leba/features/sms/data/services/battery_status_service.dart';
import 'package:anti_leba/features/sms/data/services/sim_status_service.dart';
import 'package:anti_leba/features/sms/data/services/sms_message_formatter.dart';
import 'package:anti_leba/features/sms/data/services/sms_permission_service.dart';
import 'package:anti_leba/features/sms/data/services/sms_send_service.dart';
import 'package:anti_leba/features/sms/domain/sms_alert.dart';

class SimRepositoryImpl implements SimRepository {
  SimRepositoryImpl(
    this._remote,
    this._simStatus,
    this._permissions,
    this._battery,
    this._formatter,
    this._sender,
  );

  final SimRemoteDataSource _remote;
  final SimStatusService _simStatus;
  final SmsPermissionService _permissions;
  final BatteryStatusService _battery;
  final SmsMessageFormatter _formatter;
  final SmsSendService _sender;

  @override
  Future<SimSnapshot> readSimSnapshot() => _simStatus.readSnapshot();

  @override
  Future<SimReportResult> reportChange(SimChangeEvent event) async {
    for (var attempt = 0; attempt < SimConfig.maxReportAttempts; attempt++) {
      try {
        await _remote.reportChange(event);
        AppLogger.I.i('SIM change reported to server (${event.clientEventId})');
        return const SimReportResult(reported: true);
      } on DioException catch (error) {
        AppLogger.I.e('SIM change report failed', error: error);
        if (attempt == SimConfig.maxReportAttempts - 1) {
          return SimReportResult(
            reported: false,
            error: error.message ?? 'Report failed',
          );
        }
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }

    return const SimReportResult(reported: false, error: 'Report failed');
  }

  @override
  Future<void> sendTheftAlert({
    required SimChangeEvent event,
    required String? deviceIdForSms,
    double? latitude,
    double? longitude,
  }) async {
    if (AppEnv.emergencySmsNumber.isEmpty) {
      AppLogger.I.w('EMERGENCY_SMS_NUMBER not configured — skipping theft SMS');
      return;
    }

    if (!await _permissions.ensureGranted()) {
      AppLogger.I.w('SMS permission denied — theft alert not sent');
      return;
    }

    final battery = await _battery.readLevelPercent();
    final lat = latitude ?? 0;
    final lon = longitude ?? 0;
    final alert = SmsAlert.fromLocation(
      alertId: event.clientEventId,
      deviceId: deviceIdForSms ?? event.deviceId,
      latitude: lat,
      longitude: lon,
      batteryPercent: battery < 0 ? 0 : battery,
      sim: event.currentSim,
      timestamp: event.detectedAt,
      recipient: AppEnv.emergencySmsNumber,
      body: '',
    );

    final body = _formatter.formatTheft(
      alert,
      previousSim: '${event.previousOperator} · ${event.previousSerial}',
    );

    await _sender.send(to: AppEnv.emergencySmsNumber, message: body);
  }
}
