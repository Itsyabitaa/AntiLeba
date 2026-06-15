import 'package:anti_leba/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:anti_leba/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:anti_leba/features/auth/domain/auth_repository.dart';
import 'package:anti_leba/features/auth/domain/auth_session.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._local);

  final AuthRemoteDataSource _remote;
  final AuthLocalDataSource _local;

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final session = await _remote.login(email: email, password: password);
    await _local.saveSession(session);
    return session;
  }

  @override
  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final session = await _remote.register(
      fullName: fullName,
      email: email,
      password: password,
    );
    await _local.saveSession(session);
    return session;
  }

  @override
  Future<void> logout() async {
    try {
      await _remote.logout();
    } finally {
      await _local.clearSession();
    }
  }

  @override
  Future<AuthSession?> currentSession() => _local.readSession();
}
