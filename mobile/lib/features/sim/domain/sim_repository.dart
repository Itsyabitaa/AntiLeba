import 'package:anti_leba/features/sms/domain/sms_alert.dart';

class SimChangeEvent {
  SimChangeEvent({
    required this.clientEventId,
    required this.deviceId,
    required this.previousSerial,
    required this.newSerial,
    required this.previousOperator,
    required this.newOperator,
    required this.detectedAt,
    required this.currentSim,
  });

  final String clientEventId;
  final String deviceId;
  final String previousSerial;
  final String newSerial;
  final String previousOperator;
  final String newOperator;
  final DateTime detectedAt;
  final SimSnapshot currentSim;

  Map<String, dynamic> toApiJson() => <String, dynamic>{
        'deviceId': deviceId,
        'clientEventId': clientEventId,
        'previousSerial': previousSerial,
        'newSerial': newSerial,
        'previousOperator': previousOperator,
        'newOperator': newOperator,
        'detectedAt': detectedAt.toUtc().toIso8601String(),
      };
}

class SimReportResult {
  const SimReportResult({required this.reported, this.error});

  final bool reported;
  final String? error;
}

abstract class SimRepository {
  Future<SimSnapshot> readSimSnapshot();

  Future<SimReportResult> reportChange(SimChangeEvent event);

  Future<void> sendTheftAlert({
    required SimChangeEvent event,
    required String? deviceIdForSms,
    double? latitude,
    double? longitude,
  });
}
