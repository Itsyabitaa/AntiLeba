import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:anti_leba/core/logging/app_logger.dart';
import 'package:anti_leba/features/sync/domain/sync_result.dart';
import 'package:anti_leba/features/tracking/domain/tracking_repository.dart';

typedef SyncResultCallback = void Function(SyncResult result);

/// Background engine: listens for connectivity and retries failed uploads.
class LocationSyncEngine {
  LocationSyncEngine(this._repository, {Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  static const int maxAttempts = 3;
  static const Duration retryInterval = Duration(minutes: 2);

  final TrackingRepository _repository;
  final Connectivity _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _retryTimer;
  bool _syncing = false;
  SyncResultCallback? onResult;

  bool get isRunning => _connectivitySub != null;

  void start({SyncResultCallback? onResult}) {
    if (isRunning) return;
    this.onResult = onResult;

    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      (results) {
        if (_isOnline(results)) {
          unawaited(syncWithRetry());
        }
      },
    );

    _retryTimer = Timer.periodic(retryInterval, (_) {
      unawaited(syncWithRetry());
    });

    unawaited(syncWithRetry());
    AppLogger.I.i('LocationSyncEngine started');
  }

  Future<void> stop() async {
    if (!isRunning) return;
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    onResult = null;
    AppLogger.I.i('LocationSyncEngine stopped');
  }

  Future<SyncResult> syncWithRetry() async {
    if (_syncing) return const SyncResult.idle();
    _syncing = true;

    try {
      final pending = await _repository.countUnsynced();
      if (pending == 0) {
        const result = SyncResult(uploaded: 0, skipped: 0, remaining: 0);
        onResult?.call(result);
        return result;
      }

      SyncResult last = SyncResult(uploaded: 0, skipped: 0, remaining: pending);

      for (var attempt = 0; attempt < maxAttempts; attempt++) {
        last = await _repository.syncPending();
        onResult?.call(last);
        if (last.remaining == 0 || last.hadWork) {
          return last;
        }
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
      }

      return last;
    } finally {
      _syncing = false;
    }
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }
}
