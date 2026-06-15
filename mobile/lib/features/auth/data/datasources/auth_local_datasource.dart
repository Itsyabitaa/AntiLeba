import 'package:anti_leba/core/storage/session_storage.dart';
import 'package:anti_leba/features/auth/domain/auth_session.dart';

class AuthLocalDataSource {
  AuthLocalDataSource(this._storage);

  final SessionStorage _storage;

  Future<void> saveSession(AuthSession session) =>
      _storage.saveSession(session);

  Future<AuthSession?> readSession() => _storage.readSession();

  Future<void> clearSession() => _storage.clearAll();
}
