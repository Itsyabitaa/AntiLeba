import 'package:intl/intl.dart';

import 'package:anti_leba/features/sms/domain/sms_alert.dart';

class SmsMessageFormatter {
  const SmsMessageFormatter();

  String format(SmsAlert alert) {
    final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss')
        .format(alert.timestamp.toUtc())
        .padRight(19);
    return [
      'ANTI-LEBA ALERT',
      'Lat:${_coord(alert.latitude)} Lon:${_coord(alert.longitude)}',
      'Batt:${alert.batteryPercent}% SIM:${alert.simStatus}',
      'Time:$timestamp UTC',
      'ID:${alert.alertId.substring(0, 8)}',
    ].join('\n');
  }

  String _coord(double value) => value.toStringAsFixed(5);
}
