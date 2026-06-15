import 'dart:async';

import 'package:anti_leba/core/logging/app_logger.dart';
import 'package:anti_leba/features/photos/domain/photo_config.dart';
import 'package:anti_leba/features/photos/domain/photo_repository.dart';

typedef PhotoUploadCallback = void Function(PhotoUploadResult result);

class PhotoSyncEngine {
  PhotoSyncEngine(this._repository);

  static const int maxAttempts = 3;

  final PhotoRepository _repository;

  Timer? _retryTimer;
  bool _syncing = false;
  PhotoUploadCallback? onResult;

  bool get isRunning => _retryTimer != null;

  void start({PhotoUploadCallback? onResult}) {
    if (isRunning) return;
    this.onResult = onResult;
    _retryTimer = Timer.periodic(PhotoConfig.retryInterval, (_) {
      unawaited(syncPending());
    });
    unawaited(syncPending());
    AppLogger.I.i('PhotoSyncEngine started');
  }

  Future<void> stop() async {
    if (!isRunning) return;
    _retryTimer?.cancel();
    _retryTimer = null;
    onResult = null;
    AppLogger.I.i('PhotoSyncEngine stopped');
  }

  Future<PhotoUploadResult> syncPending() async {
    if (_syncing) {
      return PhotoUploadResult(
        uploaded: 0,
        remaining: await _repository.countPending(),
      );
    }

    _syncing = true;
    try {
      var last = await _repository.uploadPending();
      onResult?.call(last);

      for (var attempt = 0;
          attempt < maxAttempts && last.remaining > 0 && !last.hadWork;
          attempt++) {
        await Future<void>.delayed(Duration(seconds: 2 * (attempt + 1)));
        last = await _repository.uploadPending();
        onResult?.call(last);
        if (last.hadWork || last.remaining == 0) break;
      }

      return last;
    } finally {
      _syncing = false;
    }
  }
}
