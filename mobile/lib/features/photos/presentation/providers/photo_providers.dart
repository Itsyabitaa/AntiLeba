import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti_leba/core/network/dio_client.dart';
import 'package:anti_leba/core/storage/hive_bootstrap.dart';
import 'package:anti_leba/features/photos/data/datasources/photo_local_datasource.dart';
import 'package:anti_leba/features/photos/data/datasources/photo_remote_datasource.dart';
import 'package:anti_leba/features/photos/data/photo_sync_engine.dart';
import 'package:anti_leba/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:anti_leba/features/photos/data/services/camera_capture_service.dart';
import 'package:anti_leba/features/photos/data/services/camera_permission_service.dart';
import 'package:anti_leba/features/photos/domain/photo_repository.dart';
import 'package:anti_leba/features/photos/domain/photo_trigger.dart';

final photoLocalDataSourceProvider = Provider<PhotoLocalDataSource>((ref) {
  return PhotoLocalDataSource(HiveBootstrap.pendingPhotosBox);
});

final photoRemoteDataSourceProvider = Provider<PhotoRemoteDataSource>((ref) {
  return PhotoRemoteDataSource(ref.watch(dioProvider));
});

final photoRepositoryProvider = Provider<PhotoRepository>((ref) {
  return PhotoRepositoryImpl(
    ref.watch(photoLocalDataSourceProvider),
    ref.watch(photoRemoteDataSourceProvider),
    CameraCaptureService(CameraPermissionService()),
  );
});

final photoSyncEngineProvider = Provider<PhotoSyncEngine>((ref) {
  final engine = PhotoSyncEngine(ref.watch(photoRepositoryProvider));
  ref.onDispose(engine.stop);
  return engine;
});

class PhotoState {
  const PhotoState({
    this.isRunning = false,
    this.isCapturing = false,
    this.pendingCount = 0,
    this.lastCapturedAt,
    this.lastUploadedAt,
    this.error,
  });

  final bool isRunning;
  final bool isCapturing;
  final int pendingCount;
  final DateTime? lastCapturedAt;
  final DateTime? lastUploadedAt;
  final String? error;

  PhotoState copyWith({
    bool? isRunning,
    bool? isCapturing,
    int? pendingCount,
    DateTime? lastCapturedAt,
    DateTime? lastUploadedAt,
    String? error,
    bool clearError = false,
  }) {
    return PhotoState(
      isRunning: isRunning ?? this.isRunning,
      isCapturing: isCapturing ?? this.isCapturing,
      pendingCount: pendingCount ?? this.pendingCount,
      lastCapturedAt: lastCapturedAt ?? this.lastCapturedAt,
      lastUploadedAt: lastUploadedAt ?? this.lastUploadedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class PhotoController extends StateNotifier<PhotoState> {
  PhotoController(this._ref) : super(const PhotoState());

  final Ref _ref;
  String? _deviceId;

  PhotoRepository get _repository => _ref.read(photoRepositoryProvider);
  PhotoSyncEngine get _syncEngine => _ref.read(photoSyncEngineProvider);

  Future<void> start(String deviceId) async {
    _deviceId = deviceId;
    _syncEngine.start(onResult: _onUploadResult);
    final pending = await _repository.countPending();
    state = state.copyWith(
      isRunning: true,
      pendingCount: pending,
      clearError: true,
    );
  }

  Future<void> stop() async {
    await _syncEngine.stop();
    _deviceId = null;
    state = const PhotoState();
  }

  Future<void> captureOnTrigger({
    required String deviceId,
    required PhotoTrigger trigger,
    String? clientEventId,
  }) async {
    final id =
        clientEventId ?? 'photo-${DateTime.now().millisecondsSinceEpoch}';
    state = state.copyWith(isCapturing: true, clearError: true);

    try {
      final path = await _repository.captureFrontPhoto(
        deviceId: deviceId,
        trigger: trigger,
        clientEventId: id,
      );
      if (path == null) {
        state = state.copyWith(
          isCapturing: false,
          error: 'Camera capture failed or permission denied',
        );
        return;
      }

      state = state.copyWith(
        isCapturing: false,
        lastCapturedAt: DateTime.now(),
        pendingCount: await _repository.countPending(),
      );
      unawaited(_syncEngine.syncPending());
    } catch (error) {
      state = state.copyWith(
        isCapturing: false,
        error: error.toString(),
      );
    }
  }

  Future<void> captureManual() async {
    final deviceId = _deviceId;
    if (deviceId == null) return;
    await captureOnTrigger(
      deviceId: deviceId,
      trigger: PhotoTrigger.manual,
    );
  }

  Future<void> onRemoteCommand() async {
    final deviceId = _deviceId;
    if (deviceId == null) return;
    await captureOnTrigger(
      deviceId: deviceId,
      trigger: PhotoTrigger.remoteCommand,
    );
  }

  Future<void> onUnlockFailure() async {
    final deviceId = _deviceId;
    if (deviceId == null) return;
    await captureOnTrigger(
      deviceId: deviceId,
      trigger: PhotoTrigger.unlockFailure,
    );
  }

  Future<void> retryUploads() async {
    await _syncEngine.syncPending();
  }

  void _onUploadResult(PhotoUploadResult result) {
    state = state.copyWith(
      pendingCount: result.remaining,
      lastUploadedAt: result.hadWork ? DateTime.now() : state.lastUploadedAt,
      error: result.error,
    );
  }
}

final photoControllerProvider =
    StateNotifierProvider<PhotoController, PhotoState>(
  (ref) => PhotoController(ref),
);
