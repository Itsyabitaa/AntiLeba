import 'package:dio/dio.dart';

import 'package:anti_leba/core/errors/failures.dart';
import 'package:anti_leba/features/auth/domain/auth_session.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._dio);

  final Dio _dio;

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/register',
        data: <String, dynamic>{
          'fullName': fullName,
          'email': email,
          'password': password,
        },
      );
      return AuthSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: <String, dynamic>{
          'email': email,
          'password': password,
        },
      );
      return AuthSession.fromJson(response.data!);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) return;
      throw _mapError(e);
    }
  }

  Future<AuthSession> me() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/auth/me');
      final data = response.data!;
      return AuthSession(
        userId: data['id'] as String,
        email: data['email'] as String,
        accessToken: '',
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Failure _mapError(DioException error) {
    final status = error.response?.statusCode;
    final message = _extractMessage(error.response?.data);

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return NetworkFailure(message ?? 'Cannot reach the server');
    }
    if (status == 401) return AuthFailure(message ?? 'Invalid credentials');
    if (status == 409) return AuthFailure(message ?? 'Email already in use');
    if (status != null && status >= 500) {
      return ServerFailure(message ?? 'Server error', statusCode: status);
    }
    return AuthFailure(message ?? 'Authentication failed');
  }

  String? _extractMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String) return message;
      if (message is List) return message.join(', ');
    }
    return null;
  }
}
