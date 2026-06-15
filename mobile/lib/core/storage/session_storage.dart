import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:anti_leba/features/auth/domain/auth_session.dart';

class SessionStorage {
  SessionStorage(this._storage);

  static const String _sessionKey = 'auth_session';
  static const String _deviceIdKey = 'enrolled_device_id';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  Future<AuthSession?> readSession() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    return AuthSession.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }

  Future<void> saveEnrolledDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  Future<String?> readEnrolledDeviceId() async {
    return _storage.read(key: _deviceIdKey);
  }

  Future<void> clearEnrolledDeviceId() async {
    await _storage.delete(key: _deviceIdKey);
  }

  Future<void> clearAll() async {
    await Future.wait(<Future<void>>[
      clearSession(),
      clearEnrolledDeviceId(),
    ]);
  }
}
