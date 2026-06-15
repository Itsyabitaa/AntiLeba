import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti_leba/core/network/dio_client.dart';
import 'package:anti_leba/features/auth/presentation/providers/auth_providers.dart';
import 'package:anti_leba/features/tracking/data/datasources/location_local_datasource.dart';
import 'package:anti_leba/features/tracking/data/datasources/location_remote_datasource.dart';
import 'package:anti_leba/features/tracking/data/repositories/tracking_repository_impl.dart';
import 'package:anti_leba/features/tracking/data/services/location_permission_service.dart';
import 'package:anti_leba/features/tracking/data/services/location_tracking_service.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';
import 'package:anti_leba/features/tracking/domain/tracking_repository.dart';

final locationLocalDataSourceProvider = Provider<LocationLocalDataSource>((ref) {
  return LocationLocalDataSource(AppDatabase.instance);
});

final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  return TrackingRepositoryImpl(
    ref.watch(locationLocalDataSourceProvider),
    LocationRemoteDataSource(ref.watch(dioProvider)),
  );
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
    this.lastLocation,
    this.unsyncedCount = 0,
    this.lastCollectedAt,
    this.error,
  });

  final bool isRunning;
  final LocationPoint? lastLocation;
  final int unsyncedCount;
  final DateTime? lastCollectedAt;
  final String? error;

  TrackingState copyWith({
    bool? isRunning,
    LocationPoint? lastLocation,
    int? unsyncedCount,
    DateTime? lastCollectedAt,
    String? error,
    bool clearError = false,
  }) {
    return TrackingState(
      isRunning: isRunning ?? this.isRunning,
      lastLocation: lastLocation ?? this.lastLocation,
      unsyncedCount: unsyncedCount ?? this.unsyncedCount,
      lastCollectedAt: lastCollectedAt ?? this.lastCollectedAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class TrackingController extends StateNotifier<TrackingState> {
  TrackingController(this._ref) : super(const TrackingState()) {
    _ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      if (next.valueOrNull == null) {
        unawaited(stop());
      }
    });
  }

  final Ref _ref;

  LocationTrackingService get _tracking =>
      _ref.read(locationTrackingServiceProvider);
  TrackingRepository get _repository => _ref.read(trackingRepositoryProvider);

  Future<void> start(String deviceId) async {
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

    final unsynced = await _repository.countUnsynced();
    await _repository.syncPending();
    final remaining = await _repository.countUnsynced();

    state = state.copyWith(
      isRunning: true,
      unsyncedCount: remaining,
      clearError: true,
    );

    if (remaining < unsynced) {
      state = state.copyWith(unsyncedCount: remaining);
    }
  }

  Future<void> stop() async {
    await _tracking.stop();
    state = const TrackingState();
  }

  Future<void> refreshUnsyncedCount() async {
    final count = await _repository.countUnsynced();
    state = state.copyWith(unsyncedCount: count);
  }

  Future<void> syncNow() async {
    await _repository.syncPending();
    await refreshUnsyncedCount();
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
  }
}

final trackingControllerProvider =
    StateNotifierProvider<TrackingController, TrackingState>(
  (ref) => TrackingController(ref),
);
