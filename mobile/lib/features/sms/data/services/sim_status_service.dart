import 'package:flutter/services.dart';

import 'package:anti_leba/features/sms/domain/sms_alert.dart';

class SimStatusService {
  SimStatusService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.antileba.anti_leba/device_telemetry');

  final MethodChannel _channel;

  Future<SimSnapshot> readSnapshot() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSimStatus',
      );
      if (result == null) return SimSnapshot.unknown();
      return SimSnapshot.fromMap(result);
    } on PlatformException {
      return SimSnapshot.unknown();
    }
  }
}
