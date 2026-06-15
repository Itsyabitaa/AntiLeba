import 'package:telephony/telephony.dart';

import 'package:anti_leba/core/logging/app_logger.dart';

class SmsSendService {
  SmsSendService({Telephony? telephony}) : _telephony = telephony ?? Telephony.instance;

  final Telephony _telephony;

  Future<void> send({required String to, required String message}) async {
    final capable = (await _telephony.isSmsCapable) ?? false;
    if (!capable) {
      throw StateError('Device cannot send SMS');
    }

    await _telephony.sendSms(
      to: to,
      message: message,
      isMultipart: message.length > 160,
    );
    AppLogger.I.i('SMS sent to $to (${message.length} chars)');
  }
}
