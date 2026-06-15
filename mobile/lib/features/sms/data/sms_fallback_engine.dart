import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:anti_leba/core/connectivity/connectivity_service.dart';
import 'package:anti_leba/core/logging/app_logger.dart';
import 'package:anti_leba/features/sms/domain/sms_config.dart';
import 'package:anti_leba/features/sms/domain/sms_repository.dart';
import 'package:anti_leba/features/sms/domain/sms_send_result.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';

typedef SmsResultCallback = void Function(SmsSendResult result);

/// Sends emergency SMS when data cannot reach the API (no internet).
class SmsFallbackEngine {
  SmsFallbackEngine(this._repository, {ConnectivityService? connectivity})
      : _connectivity = connectivity ?? ConnectivityService();

  final SmsRepository _repository;
  final ConnectivityService _connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _retryTimer;
  bool _sending = false;
  LocationPoint? _lastLocation;
  SmsResultCallback? onResult;

  bool get isRunning => _connectivitySub != null;

  void start({SmsResultCallback? onResult}) {
    if (isRunning) return;
    this.onResult = onResult;

    _connectivitySub = _connectivity.onConnectivityChanged.listen((results) {
      if (!_connectivity.isOnlineResult(results) && _lastLocation != null) {
        unawaited(_sendWithRetry(_lastLocation!));
      }
    });

    _retryTimer = Timer.periodic(SmsConfig.retryInterval, (_) {
      unawaited(retryPending());
    });

    AppLogger.I.i('SmsFallbackEngine started');
  }

  Future<void> stop() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _lastLocation = null;
    onResult = null;
    AppLogger.I.i('SmsFallbackEngine stopped');
  }

  Future<void> onLocationCollected(LocationPoint point) async {
    _lastLocation = point;
    final online = await _connectivity.isOnline();
    if (!online) {
      await _sendWithRetry(point);
    }
  }

  Future<void> onSyncFailedOffline(LocationPoint? point) async {
    final online = await _connectivity.isOnline();
    if (online) return;
    final target = point ?? _lastLocation;
    if (target == null) return;
    await _sendWithRetry(target);
  }

  Future<SmsSendResult> retryPending() async {
    if (_sending) return const SmsSendResult.idle();
    _sending = true;
    try {
      final pending = await _repository.countPending();
      if (pending == 0) {
        const result = SmsSendResult.idle();
        onResult?.call(result);
        return result;
      }

      SmsSendResult last = SmsSendResult(
        sent: 0,
        queued: 0,
        skipped: 0,
        remaining: pending,
      );

      for (var attempt = 0; attempt < SmsConfig.maxAttempts; attempt++) {
        last = await _repository.retryPending();
        onResult?.call(last);
        if (last.remaining == 0 || last.sent > 0) {
          return last;
        }
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
      }

      return last;
    } finally {
      _sending = false;
    }
  }

  Future<SmsSendResult> _sendWithRetry(LocationPoint point) async {
    if (_sending) return const SmsSendResult.idle();
    _sending = true;

    try {
      if (await _repository.wasSent(point.clientEventId)) {
        final result = SmsSendResult(
          sent: 0,
          queued: 0,
          skipped: 1,
          remaining: await _repository.countPending(),
        );
        onResult?.call(result);
        return result;
      }

      SmsSendResult last = SmsSendResult(
        sent: 0,
        queued: 0,
        skipped: 0,
        remaining: await _repository.countPending(),
      );

      for (var attempt = 0; attempt < SmsConfig.maxAttempts; attempt++) {
        last = await _repository.sendEmergencyAlert(point);
        onResult?.call(last);
        if (last.sent > 0 || last.skipped > 0) {
          return last;
        }
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
      }

      return last;
    } finally {
      _sending = false;
    }
  }
}
