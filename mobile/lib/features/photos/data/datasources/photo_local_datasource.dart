import 'dart:io';

import 'package:hive/hive.dart';

import 'package:anti_leba/features/photos/domain/photo_repository.dart';

class PhotoLocalDataSource {
  PhotoLocalDataSource(this._boxFuture);

  static const String boxName = 'pending_photos';

  final Future<Box<dynamic>> Function() _boxFuture;

  Future<void> enqueue(PendingPhoto photo) async {
    final box = await _boxFuture();
    await box.put(photo.clientEventId, photo.toHiveMap());
  }

  Future<List<PendingPhoto>> getPending() async {
    final box = await _boxFuture();
    final pending = <PendingPhoto>[];
    for (final key in box.keys) {
      final raw = box.get(key);
      if (raw is Map) {
        pending.add(PendingPhoto.fromHiveMap(raw));
      }
    }
    pending.sort((a, b) => a.capturedAt.compareTo(b.capturedAt));
    return pending;
  }

  Future<int> countPending() async {
    final box = await _boxFuture();
    return box.length;
  }

  Future<void> remove(String clientEventId) async {
    final box = await _boxFuture();
    await box.delete(clientEventId);
  }

  Future<void> recordFailedAttempt(String clientEventId) async {
    final box = await _boxFuture();
    final raw = box.get(clientEventId);
    if (raw is! Map) return;
    final photo = PendingPhoto.fromHiveMap(raw);
    await box.put(
      clientEventId,
      photo
          .copyWith(
            retryCount: photo.retryCount + 1,
            lastAttemptAt: DateTime.now().toUtc(),
          )
          .toHiveMap(),
    );
  }

  Future<void> deleteLocalFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }
}
