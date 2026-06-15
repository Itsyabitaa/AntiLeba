import 'package:anti_leba/features/remote_commands/domain/command_type.dart';

class RemoteCommand {
  const RemoteCommand({
    required this.id,
    required this.deviceId,
    required this.type,
    this.payload,
    required this.issuedAt,
  });

  factory RemoteCommand.fromJson(Map<String, dynamic> json) {
    return RemoteCommand(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      type: RemoteCommandType.fromApi(json['type'] as String?) ??
          RemoteCommandType.captureImage,
      payload: json['payload'] as Map<String, dynamic>?,
      issuedAt: DateTime.parse(json['issuedAt'] as String),
    );
  }

  final String id;
  final String deviceId;
  final RemoteCommandType type;
  final Map<String, dynamic>? payload;
  final DateTime issuedAt;
}
