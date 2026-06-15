import 'dart:io';

import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';

import 'package:anti_leba/core/logging/app_logger.dart';
import 'package:anti_leba/features/photos/data/services/camera_permission_service.dart';

class CameraCaptureService {
  CameraCaptureService(this._permissions);

  final CameraPermissionService _permissions;

  Future<String?> captureFrontPhoto({
    required String deviceId,
    required String clientEventId,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      AppLogger.I.w('Camera capture is only supported on mobile devices');
      return null;
    }

    if (!await _permissions.ensureGranted()) {
      AppLogger.I.w('Camera permission denied');
      return null;
    }

    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        AppLogger.I.w('No cameras available');
        return null;
      }

      final front = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      final picture = await controller.takePicture();
      final dir = await _evidenceDirectory(deviceId);
      final targetPath = '${dir.path}/$clientEventId.jpg';
      await File(picture.path).copy(targetPath);
      try {
        await File(picture.path).delete();
      } catch (_) {}

      AppLogger.I.i('Front camera photo saved to $targetPath');
      return targetPath;
    } catch (error, stackTrace) {
      AppLogger.I.e(
        'Camera capture failed',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } finally {
      await controller?.dispose();
    }
  }

  Future<Directory> _evidenceDirectory(String deviceId) async {
    final root = await getApplicationDocumentsDirectory();
    final dir = Directory('${root.path}/evidence/$deviceId');
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
