class LocationPoint {
  LocationPoint({
    required this.clientEventId,
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  factory LocationPoint.create({
    required String deviceId,
    required double latitude,
    required double longitude,
    required DateTime recordedAt,
    required String clientEventId,
    double? accuracy,
    double? altitude,
    double? speed,
    double? heading,
  }) {
    return LocationPoint(
      clientEventId: clientEventId,
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      recordedAt: recordedAt,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
    );
  }

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      clientEventId: json['clientEventId'] as String? ?? '',
      deviceId: json['deviceId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      altitude: (json['altitude'] as num?)?.toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      heading: (json['heading'] as num?)?.toDouble(),
    );
  }

  factory LocationPoint.fromHiveMap(Map<dynamic, dynamic> map) {
    return LocationPoint(
      clientEventId: map['clientEventId'] as String,
      deviceId: map['deviceId'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      altitude: (map['altitude'] as num?)?.toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.parse(map['lastAttemptAt'] as String)
          : null,
    );
  }

  final String clientEventId;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;
  final int retryCount;
  final DateTime? lastAttemptAt;

  Map<String, dynamic> toApiJson() => <String, dynamic>{
        'clientEventId': clientEventId,
        'deviceId': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        if (accuracy != null) 'accuracy': accuracy,
        if (altitude != null) 'altitude': altitude,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
      };

  Map<String, dynamic> toHiveMap() => <String, dynamic>{
        'clientEventId': clientEventId,
        'deviceId': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        'retryCount': retryCount,
        if (lastAttemptAt != null)
          'lastAttemptAt': lastAttemptAt!.toUtc().toIso8601String(),
      };

  LocationPoint copyWith({
    int? retryCount,
    DateTime? lastAttemptAt,
  }) {
    return LocationPoint(
      clientEventId: clientEventId,
      deviceId: deviceId,
      latitude: latitude,
      longitude: longitude,
      recordedAt: recordedAt,
      accuracy: accuracy,
      altitude: altitude,
      speed: speed,
      heading: heading,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }
}
