import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti_leba/core/network/access_token_provider.dart';
import 'package:anti_leba/core/network/dio_client.dart';
import 'package:anti_leba/core/storage/secure_storage_provider.dart';
import 'package:anti_leba/core/storage/session_storage.dart';
import 'package:anti_leba/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:anti_leba/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:anti_leba/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:anti_leba/features/auth/domain/auth_repository.dart';
import 'package:anti_leba/features/auth/domain/auth_session.dart';
import 'package:anti_leba/features/devices/data/repositories/device_repository_impl.dart';
import 'package:anti_leba/features/devices/data/services/device_info_service.dart';
import 'package:anti_leba/features/devices/domain/device.dart';
import 'package:anti_leba/features/devices/domain/device_repository.dart';

final sessionStorageProvider = Provider<SessionStorage>((ref) {
  return SessionStorage(ref.watch(secureStorageProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
    AuthRemoteDataSource(ref.watch(dioProvider)),
    AuthLocalDataSource(ref.watch(sessionStorageProvider)),
  );
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepositoryImpl(
    DeviceRemoteDataSource(ref.watch(dioProvider)),
    DeviceInfoService(ref.watch(secureStorageProvider)),
    ref.watch(sessionStorageProvider),
  );
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._ref) : super(const AsyncValue.loading()) {
    restore();
  }

  final Ref _ref;

  AuthRepository get _auth => _ref.read(authRepositoryProvider);
  DeviceRepository get _devices => _ref.read(deviceRepositoryProvider);

  Future<void> restore() async {
    state = const AsyncValue.loading();
    try {
      final session = await _auth.currentSession();
      _syncToken(session?.accessToken);
      state = AsyncValue.data(session);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _auth.login(email: email, password: password);
      _syncToken(session.accessToken);
      await _devices.registerCurrentDevice();
      state = AsyncValue.data(session);
    } catch (error, stackTrace) {
      _syncToken(null);
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _auth.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      _syncToken(session.accessToken);
      await _devices.registerCurrentDevice();
      state = AsyncValue.data(session);
    } catch (error, stackTrace) {
      _syncToken(null);
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } finally {
      _syncToken(null);
      state = const AsyncValue.data(null);
    }
  }

  void _syncToken(String? token) {
    _ref.read(accessTokenProvider.notifier).state = token;
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>(
  (ref) => AuthController(ref),
);

class AuthRouterNotifier extends ChangeNotifier {
  AuthRouterNotifier(this._ref) {
    _ref.listen<AsyncValue<AuthSession?>>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;

  bool get isLoading =>
      _ref.read(authControllerProvider).isLoading;

  bool get isAuthenticated =>
      _ref.read(authControllerProvider).valueOrNull != null;
}

final authRouterNotifierProvider = Provider<AuthRouterNotifier>((ref) {
  return AuthRouterNotifier(ref);
});

final enrolledDeviceProvider = FutureProvider<Device?>((ref) async {
  final session = ref.watch(authControllerProvider).valueOrNull;
  if (session == null) return null;
  final devices = await ref.watch(deviceRepositoryProvider).listDevices();
  if (devices.isEmpty) return null;
  return devices.first;
});
