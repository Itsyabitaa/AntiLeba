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

  final String id;
  final String deviceUid;
  final String label;
  final DeviceStatus status;
  final String? manufacturer;
  final String? model;
  final String? osVersion;
  final DateTime? lastSeenAt;
}
