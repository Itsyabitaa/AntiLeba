class LocationPoint {
  const LocationPoint({
    required this.deviceId,
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.localId,
    this.accuracy,
    this.altitude,
    this.speed,
    this.heading,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
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

  factory LocationPoint.fromDbMap(Map<String, Object?> row) {
    return LocationPoint(
      localId: row['id'] as int?,
      deviceId: row['device_id'] as String,
      latitude: row['latitude'] as double,
      longitude: row['longitude'] as double,
      recordedAt: DateTime.parse(row['recorded_at'] as String),
      accuracy: row['accuracy'] as double?,
      altitude: row['altitude'] as double?,
      speed: row['speed'] as double?,
      heading: row['heading'] as double?,
    );
  }

  final int? localId;
  final String deviceId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final double? heading;
  final DateTime recordedAt;

  Map<String, dynamic> toApiJson() => <String, dynamic>{
        'deviceId': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'recordedAt': recordedAt.toUtc().toIso8601String(),
        if (accuracy != null) 'accuracy': accuracy,
        if (altitude != null) 'altitude': altitude,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
      };

  Map<String, Object?> toDbMap() => <String, Object?>{
        'device_id': deviceId,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'altitude': altitude,
        'speed': speed,
        'heading': heading,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        'synced': 0,
      };

  LocationPoint copyWith({int? localId}) {
    return LocationPoint(
      localId: localId ?? this.localId,
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
}
