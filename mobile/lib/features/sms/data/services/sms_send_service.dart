import 'package:flutter/services.dart';

import 'package:anti_leba/core/logging/app_logger.dart';

class SmsSendService {
  SmsSendService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.antileba.anti_leba/device_telemetry');

  final MethodChannel _channel;

  Future<void> send({required String to, required String message}) async {
    final capable = await isCapable();
    if (!capable) {
      throw StateError('Device cannot send SMS');
    }

    try {
      await _channel.invokeMethod<void>('sendSms', <String, String>{
        'to': to,
        'message': message,
      });
      AppLogger.I.i('SMS sent to $to (${message.length} chars)');
    } on PlatformException catch (error) {
      throw StateError(error.message ?? 'SMS send failed');
    }
  }

  Future<bool> isCapable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isSmsCapable');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }
}
