import 'package:flutter/services.dart';

class AlarmService {
  AlarmService() : _channel = const MethodChannel(_channelName);

  static const _channelName = 'com.antileba.anti_leba/device_telemetry';

  final MethodChannel _channel;

  Future<void> playAlarm({int durationSeconds = 15}) async {
    await _channel.invokeMethod<void>('playAlarm', <String, int>{
      'durationSeconds': durationSeconds,
    });
  }

  Future<void> stopAlarm() async {
    await _channel.invokeMethod<void>('stopAlarm');
  }
}
