import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti_leba/core/network/dio_client.dart';
import 'package:anti_leba/core/storage/hive_bootstrap.dart';
import 'package:anti_leba/features/auth/domain/auth_session.dart';
import 'package:anti_leba/features/auth/presentation/providers/auth_providers.dart';
import 'package:anti_leba/features/sms/presentation/providers/sms_providers.dart';
import 'package:anti_leba/features/sync/data/location_sync_engine.dart';
import 'package:anti_leba/features/sync/domain/sync_result.dart';
import 'package:anti_leba/features/tracking/data/datasources/location_local_datasource.dart';
import 'package:anti_leba/features/tracking/data/datasources/location_remote_datasource.dart';
import 'package:anti_leba/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:anti_leba/features/tracking/data/services/location_permission_service.dart';
import 'package:anti_leba/features/tracking/data/services/location_tracking_service.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';
import 'package:anti_leba/features/tracking/domain/tracking_repository.dart';

final locationLocalDataSourceProvider = Provider<LocationLocalDataSource>((ref) {
  return LocationLocalDataSource(HiveBootstrap.pendingLocationsBox);
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepositoryImpl(
    ref.watch(locationLocalDataSourceProvider),
    LocationRemoteDataSource(ref.watch(dioProvider)),
  );
});

final locationSyncEngineProvider = Provider<LocationSyncEngine>((ref) {
  final engine = LocationSyncEngine(ref.watch(trackingRepositoryProvider));
  ref.onDispose(engine.stop);
  return engine;
});

final locationPermissionServiceProvider =
    Provider<LocationPermissionService>((ref) => LocationPermissionService());

final locationTrackingServiceProvider = Provider<LocationTrackingService>((ref) {
  return LocationTrackingService(
    ref.watch(locationPermissionServiceProvider),
    ref.watch(trackingRepositoryProvider),
  );
});

class TrackingState {
  const TrackingState({
    this.isRunning = false,
    this.isSyncing = false,
    this.lastLocation,
    this.unsyncedCount = 0,
    this.lastCollectedAt,
    this.lastSyncedAt,
    this.error,
  });

  final bool isRunning;
  final bool isSyncing;
  final LocationPoint? lastLocation;
  final int unsyncedCount;
  final DateTime? lastCollectedAt;
  final DateTime? lastSyncedAt;
  final String? error;

  TrackingState copyWith({
    bool? isRunning,
    bool? isSyncing,
    LocationPoint? lastLocation,
    int? unsyncedCount,
    DateTime? lastCollectedAt,
    DateTime? lastSyncedAt,
    String? error,
    bool clearError = false,
  }) {
    return TrackingState(
      isRunning: isRunning ?? this.isRunning,
      isSyncing: isSyncing ?? this.isSyncing,
      lastLocation: lastLocation ?? this.lastLocation,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      lastCollectedAt: lastCollectedAt ?? this.lastCollectedAt,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TrackingController extends StateNotifier<TrackingState> {
  TrackingController(this._ref) : super(const TrackingState()) {
    _ref.listen<AsyncValue<AuthSession?>>(
      authControllerProvider,
      (previous, next) {
        final wasAuthenticated = previous?.valueOrNull != null;
        final isAuthenticated = next.valueOrNull != null;
        if (wasAuthenticated && !isAuthenticated) {
          unawaited(stop());
        }
      },
    );
  }

  final Ref _ref;

  LocationTrackingService get _tracking =>
      _ref.read(locationTrackingServiceProvider);
  TrackingRepository get _repository => _ref.read(trackingRepositoryProvider);
  LocationSyncEngine get _syncEngine => _ref.read(locationSyncEngineProvider);

  Future<void> start(String deviceId) async {
    await _ref.read(smsControllerProvider.notifier).start();
    _syncEngine.start(onResult: _onSyncResult);

    final started = await _tracking.start(
      deviceId,
      onCollected: _onLocationCollected,
    );

    if (!started) {
      state = state.copyWith(
        isRunning: false,
        error: 'Location permission or GPS service unavailable',
      );
      return;
    }

    await _syncEngine.syncWithRetry();
    final remaining = await _repository.countUnsynced();

    state = state.copyWith(
      isRunning: true,
      unsyncedCount: remaining,
      clearError: true,
    );
  }

  Future<void> stop() async {
    if (!state.isRunning &&
        !_tracking.isRunning &&
        !_syncEngine.isRunning) {
      return;
    }
    await _tracking.stop();
    await _syncEngine.stop();
    await _ref.read(smsControllerProvider.notifier).stop();
    state = const TrackingState();
  }

  Future<void> syncNow() async {
    state = state.copyWith(isSyncing: true);
    await _syncEngine.syncWithRetry();
  }

  Future<void> refreshUnsyncedCount() async {
    final count = await _repository.countUnsynced();
    state = state.copyWith(unsyncedCount: count);
  }

  Future<void> _onLocationCollected(LocationPoint point) async {
    final unsynced = await _repository.countUnsynced();
    state = state.copyWith(
      lastLocation: point,
      lastCollectedAt: point.recordedAt,
      unsyncedCount: unsynced,
      isRunning: true,
      clearError: true,
    );
    unawaited(_ref.read(smsControllerProvider.notifier).onLocationCollected(point));
    unawaited(_syncEngine.syncWithRetry());
  }

  void _onSyncResult(SyncResult result) {
    state = state.copyWith(
      isSyncing: false,
      unsyncedCount: result.remaining,
      lastSyncedAt: result.hadWork ? DateTime.now() : state.lastSyncedAt,
    );
    if (result.remaining > 0 && !result.hadWork) {
      unawaited(
        _ref
            .read(smsControllerProvider.notifier)
            .onSyncFailedOffline(state.lastLocation),
      );
    }
  }
}

final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>(
  (ref) => TrackingController(ref),
);
