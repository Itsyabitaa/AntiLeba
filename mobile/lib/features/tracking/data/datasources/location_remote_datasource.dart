import 'package:dio/dio.dart';

import 'package:anti_leba/core/errors/failures.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';

class BatchUploadResponse {
  BatchUploadResponse({
    required this.inserted,
    required this.skipped,
  });

  factory BatchUploadResponse.fromJson(Map<String, dynamic> json) {
    return BatchUploadResponse(
      inserted: (json['inserted'] as num?)?.toInt() ??
          (json['count'] as num?)?.toInt() ??
          0,
      skipped: (json['skipped'] as num?)?.toInt() ?? 0,
    );
  }

  final int inserted;
  final int skipped;
}

class LocationRemoteDataSource {
  LocationRemoteDataSource(this._dio);

  final Dio _dio;

  Future<void> upload(LocationPoint point) async {
    try {
      await _dio.post<void>('/locations', data: point.toApiJson());
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<BatchUploadResponse> uploadBatch(List<LocationPoint> points) async {
    if (points.isEmpty) {
      return BatchUploadResponse(inserted: 0, skipped: 0);
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/locations/batch',
        data: <String, dynamic>{
          'locations': points.map((p) => p.toApiJson()).toList(),
        },
      );
      return BatchUploadResponse.fromJson(response.data!);
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Future<List<LocationPoint>> fetchRecent({
    required String deviceId,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/locations',
        queryParameters: <String, dynamic>{
          'deviceId': deviceId,
          'limit': limit,
        },
      );
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(LocationPoint.fromJson)
          .toList();
    } on DioException catch (error) {
      throw _mapError(error);
    }
  }

  Failure _mapError(DioException error) {
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return const NetworkFailure('Cannot reach the server');
    }
    final status = error.response?.statusCode;
    final message = error.response?.data is Map<String, dynamic>
        ? (error.response!.data as Map<String, dynamic>)['message']
        : null;
    return ServerFailure(
      message?.toString() ?? 'Location upload failed',
      statusCode: status,
    );
  }
}
