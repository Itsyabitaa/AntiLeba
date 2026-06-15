import 'package:anti_leba/features/photos/domain/photo_trigger.dart';

class PendingPhoto {
  PendingPhoto({
    required this.clientEventId,
    required this.deviceId,
    required this.localPath,
    required this.trigger,
    required this.capturedAt,
    this.retryCount = 0,
    this.lastAttemptAt,
  });

  factory PendingPhoto.fromHiveMap(Map<dynamic, dynamic> map) {
    return PendingPhoto(
      clientEventId: map['clientEventId'] as String,
      deviceId: map['deviceId'] as String,
      localPath: map['localPath'] as String,
      trigger: PhotoTrigger.values.firstWhere(
        (value) => value.name == map['trigger'],
        orElse: () => PhotoTrigger.manual,
      ),
      capturedAt: DateTime.parse(map['capturedAt'] as String),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      lastAttemptAt: map['lastAttemptAt'] != null
          ? DateTime.parse(map['lastAttemptAt'] as String)
          : null,
    );
  }

  final String clientEventId;
  final String deviceId;
  final String localPath;
  final PhotoTrigger trigger;
  final DateTime capturedAt;
  final int retryCount;
  final DateTime? lastAttemptAt;

  Map<String, dynamic> toHiveMap() => <String, dynamic>{
        'clientEventId': clientEventId,
        'deviceId': deviceId,
        'localPath': localPath,
        'trigger': trigger.name,
        'capturedAt': capturedAt.toUtc().toIso8601String(),
        'retryCount': retryCount,
        if (lastAttemptAt != null)
          'lastAttemptAt': lastAttemptAt!.toUtc().toIso8601String(),
      };

  PendingPhoto copyWith({
    int? retryCount,
    DateTime? lastAttemptAt,
  }) {
    return PendingPhoto(
      clientEventId: clientEventId,
      deviceId: deviceId,
      localPath: localPath,
      trigger: trigger,
      capturedAt: capturedAt,
      retryCount: retryCount ?? this.retryCount,
      lastAttemptAt: lastAttemptAt ?? this.lastAttemptAt,
    );
  }
}

class PhotoUploadResult {
  const PhotoUploadResult({
    required this.uploaded,
    required this.remaining,
    this.error,
  });

  final int uploaded;
  final int remaining;
  final String? error;

  bool get hadWork => uploaded > 0;
}

abstract class PhotoRepository {
  Future<String?> captureFrontPhoto({
    required String deviceId,
    required PhotoTrigger trigger,
    required String clientEventId,
  });

  Future<int> countPending();

  Future<PhotoUploadResult> uploadPending();
}
