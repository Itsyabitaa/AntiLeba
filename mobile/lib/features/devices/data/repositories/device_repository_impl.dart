import 'package:dio/dio.dart';

import 'package:anti_leba/core/errors/failures.dart';
import 'package:anti_leba/core/storage/session_storage.dart';
import 'package:anti_leba/features/devices/data/services/device_info_service.dart';
import 'package:anti_leba/features/devices/domain/device.dart';
import 'package:anti_leba/features/devices/domain/device_repository.dart';

class DeviceRemoteDataSource {
  DeviceRemoteDataSource(this._dio);

  final Dio _dio;

  Future<Device> register(DeviceRegistrationPayload payload) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/devices/register',
        data: payload.toJson(),
      );
      return Device.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<List<Device>> listDevices() async {
    try {
      final response = await _dio.get<List<dynamic>>('/devices');
      return response.data!
          .cast<Map<String, dynamic>>()
          .map(Device.fromJson)
          .toList();
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Failure _mapError(DioException error) {
    final status = error.response?.statusCode;
    final message = error.response?.data is Map<String, dynamic>
        ? (error.response!.data as Map<String, dynamic>)['message'] as String?
        : null;

    if (error.type == DioExceptionType.connectionError) {
      return NetworkFailure(message ?? 'Cannot reach the server');
    }
    if (status == 409) {
      return AuthFailure(message ?? 'Device already enrolled elsewhere');
    }
    return ServerFailure(message ?? 'Device registration failed', statusCode: status);
  }
}

class DeviceRepositoryImpl implements DeviceRepository {
  DeviceRepositoryImpl(this._remote, this._info, this._storage);

  final DeviceRemoteDataSource _remote;
  final DeviceInfoService _info;
  final SessionStorage _storage;

  @override
  Future<Device> registerCurrentDevice() async {
    final payload = await _info.collect();
    final device = await _remote.register(payload);
    await _storage.saveEnrolledDeviceId(device.id);
    return device;
  }

  @override
  Future<List<Device>> listDevices() => _remote.listDevices();
}
