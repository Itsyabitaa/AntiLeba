class SimSnapshot {
  const SimSnapshot({
    required this.status,
    required this.operator,
    required this.serial,
  });

  factory SimSnapshot.fromMap(Map<dynamic, dynamic> map) {
    return SimSnapshot(
      status: map['status'] as String? ?? 'UNKNOWN',
      operator: map['operator'] as String? ?? 'UNKNOWN',
      serial: map['serial'] as String? ?? 'UNKNOWN',
    );
  }

  factory SimSnapshot.unknown() {
    return const SimSnapshot(
      status: 'UNKNOWN',
      operator: 'UNKNOWN',
      serial: 'UNKNOWN',
    );
  }

  final String status;
  final String operator;
  final String serial;

  String get displayLabel => '$status · $operator';

  Map<String, dynamic> toMap() => <String, dynamic>{
        'status': status,
        'operator': operator,
        'serial': serial,
      };
}

class SmsAlert {
  SmsAlert({
    required this.alertId,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.batteryPercent,
    required this.simStatus,
    required this.timestamp,
    required this.recipient,
    required this.body,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  factory SmsAlert.fromLocation({
    required String alertId,
    required String deviceId,
    required double latitude,
    required double longitude,
    required int batteryPercent,
    required SimSnapshot sim,
    required DateTime timestamp,
    required String recipient,
    required String body,
  }) {
    return SmsAlert(
      alertId: alertId,
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      batteryPercent: batteryPercent,
      simStatus: sim.displayLabel,
      timestamp: timestamp,
      recipient: recipient,
      body: body,
    );
  }

  factory SmsAlert.fromHiveMap(Map<dynamic, dynamic> map) {
    return SmsAlert(
      alertId: map['alertId'] as String,
      deviceId: map['deviceId'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      batteryPercent: (map['batteryPercent'] as num).toInt(),
      simStatus: map['simStatus'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      recipient: map['recipient'] as String,
      body: map['body'] as String,
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.parse(map['lastAttemptAt'] as String)
          : null,
    );
  }

  final String alertId;
  final String deviceId;
  final double latitude;
  final double longitude;
  final int batteryPercent;
  final String simStatus;
  final DateTime timestamp;
  final String recipient;
  final String body;
  final int retryCount;
  final DateTime? lastAttemptAt;

  Map<String, dynamic> toHiveMap() => <String, dynamic>{
        'alertId': alertId,
        'deviceId': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'batteryPercent': batteryPercent,
        'simStatus': simStatus,
        'timestamp': timestamp.toUtc().toIso8601String(),
        'recipient': recipient,
        'body': body,
        'retryCount': retryCount,
        if (lastAttemptAt != null)
          'lastAttemptAt': lastAttemptAt!.toUtc().toIso8601String(),
      };

  SmsAlert copyWith({
    int? retryCount,
    DateTime? lastAttemptAt,
  }) {
    return SmsAlert(
      alertId: alertId,
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      batteryPercent: batteryPercent,
      simStatus: simStatus,
      timestamp: timestamp,
      recipient: recipient,
      body: body,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }
}
