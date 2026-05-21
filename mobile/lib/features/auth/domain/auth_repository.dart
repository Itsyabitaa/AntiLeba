import 'package:anti_leba/features/auth/domain/auth_session.dart';

/// Domain-layer contract. Implementations live under `data/`.
abstract class AuthRepository {
  Future<AuthSession> login({required String email, required String password});

  Future<AuthSession> register({
    required String fullName,
    required String email,
    required String password,
  });

  Future<void> logout();

  Future<AuthSession?> currentSession();
}
