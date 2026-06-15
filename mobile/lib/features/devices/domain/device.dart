enum DeviceStatus { active, lost, recovered, disabled }

class Device {
  const Device({
    required this.id,
    required this.deviceUid,
    required this.label,
    required this.status,
    this.manufacturer,
    this.model,
    this.osVersion,
    this.lastSeenAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      deviceUid: json['deviceUid'] as String,
      label: json['label'] as String,
      status: _parseStatus(json['status'] as String?),
      manufacturer: json['manufacturer'] as String?,
      model: json['model'] as String?,
      osVersion: json['osVersion'] as String?,
      lastSeenAt: json['lastSeenAt'] != null
          ? DateTime.tryParse(json['lastSeenAt'] as String)
          : null,
    );
  }

  final String id;
  final String deviceUid;
  final String label;
  final DeviceStatus status;
  final String? manufacturer;
  final String? model;
  final String? osVersion;
  final DateTime? lastSeenAt;

  static DeviceStatus _parseStatus(String? raw) {
    switch (raw?.toUpperCase()) {
      case 'LOST':
        return DeviceStatus.lost;
      case 'RECOVERED':
        return DeviceStatus.recovered;
      case 'DISABLED':
        return DeviceStatus.disabled;
      default:
        return DeviceStatus.active;
    }
  }
}
