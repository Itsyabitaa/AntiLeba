import 'dart:io';

import 'package:dio/dio.dart';

import 'package:anti_leba/core/logging/app_logger.dart';
import 'package:anti_leba/features/photos/data/datasources/photo_local_datasource.dart';
import 'package:anti_leba/features/photos/data/datasources/photo_remote_datasource.dart';
import 'package:anti_leba/features/photos/data/services/camera_capture_service.dart';
import 'package:anti_leba/features/photos/domain/photo_config.dart';
import 'package:anti_leba/features/photos/domain/photo_repository.dart';
import 'package:anti_leba/features/photos/domain/photo_trigger.dart';

class PhotoRepositoryImpl implements PhotoRepository {
  PhotoRepositoryImpl(this._local, this._remote, this._camera);

  final PhotoLocalDataSource _local;
  final PhotoRemoteDataSource _remote;
  final CameraCaptureService _camera;

  @override
  Future<String?> captureFrontPhoto({
    required String deviceId,
    required PhotoTrigger trigger,
    required String clientEventId,
  }) async {
    final path = await _camera.captureFrontPhoto(
      deviceId: deviceId,
      clientEventId: clientEventId,
    );
    if (path == null) return null;

    await _local.enqueue(
      PendingPhoto(
        clientEventId: clientEventId,
        deviceId: deviceId,
        localPath: path,
        trigger: trigger,
        capturedAt: DateTime.now().toUtc(),
      ),
    );

    return path;
  }

  @override
  Future<int> countPending() => _local.countPending();

  @override
  Future<PhotoUploadResult> uploadPending() async {
    final pending = await _local.getPending();
    if (pending.isEmpty) {
      return const PhotoUploadResult(uploaded: 0, remaining: 0);
    }

    var uploaded = 0;
    String? lastError;

    for (final photo in pending) {
      if (photo.retryCount >= PhotoConfig.maxAttempts) {
        continue;
      }

      if (!await File(photo.localPath).exists()) {
        await _local.remove(photo.clientEventId);
        continue;
      }

      try {
        await _remote.upload(photo);
        await _local.remove(photo.clientEventId);
        await _local.deleteLocalFile(photo.localPath);
        uploaded += 1;
        AppLogger.I.i('Photo uploaded (${photo.clientEventId})');
      } on DioException catch (error) {
        lastError = error.message ?? 'Upload failed';
        AppLogger.I.e('Photo upload failed', error: error);
        await _local.recordFailedAttempt(photo.clientEventId);
      } catch (error) {
        lastError = error.toString();
        await _local.recordFailedAttempt(photo.clientEventId);
      }
    }

    final remaining = await _local.countPending();
    return PhotoUploadResult(
      uploaded: uploaded,
      remaining: remaining,
      error: lastError,
    );
  }
}
