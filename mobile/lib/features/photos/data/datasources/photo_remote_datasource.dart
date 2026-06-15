import 'package:dio/dio.dart';

import 'package:anti_leba/features/photos/domain/photo_repository.dart';

class PhotoRemoteDataSource {
  PhotoRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> upload(PendingPhoto photo) async {
    final fileName = '${photo.clientEventId}.jpg';
    final formData = FormData.fromMap(<String, dynamic>{
      'deviceId': photo.deviceId,
      'clientEventId': photo.clientEventId,
      'trigger': photo.trigger.apiValue,
      'capturedAt': photo.capturedAt.toUtc().toIso8601String(),
      'file': await MultipartFile.fromFile(
        photo.localPath,
        filename: fileName,
      ),
    });

    await _dio.post<void>(
      '/photos',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
  }
}
