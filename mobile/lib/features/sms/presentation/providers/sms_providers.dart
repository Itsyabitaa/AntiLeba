import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anti_leba/core/env/app_env.dart';
import 'package:anti_leba/core/storage/hive_bootstrap.dart';
import 'package:anti_leba/features/auth/presentation/providers/auth_providers.dart';
import 'package:anti_leba/features/sms/data/datasources/sms_local_datasource.dart';
import 'package:anti_leba/features/sms/data/repositories/sms_repository_impl.dart';
import 'package:anti_leba/features/sms/data/services/battery_status_service.dart';
import 'package:anti_leba/features/sms/data/services/sim_status_service.dart';
import 'package:anti_leba/features/sms/data/services/sms_message_formatter.dart';
import 'package:anti_leba/features/sms/data/services/sms_permission_service.dart';
import 'package:anti_leba/features/sms/data/services/sms_send_service.dart';
import 'package:anti_leba/features/sms/data/sms_fallback_engine.dart';
import 'package:anti_leba/features/sms/domain/sms_alert.dart';
import 'package:anti_leba/features/sms/domain/sms_repository.dart';
import 'package:anti_leba/features/sms/domain/sms_send_result.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';

final smsLocalDataSourceProvider = Provider<SmsLocalDataSource>((ref) {
  return SmsLocalDataSource(
    HiveBootstrap.pendingSmsBox,
    HiveBootstrap.sentSmsBox,
  );
});

final smsRepositoryProvider = Provider<SmsRepository>((ref) {
  return SmsRepositoryImpl(
    ref.watch(smsLocalDataSourceProvider),
    SmsPermissionService(),
    BatteryStatusService(),
    SimStatusService(),
    const SmsMessageFormatter(),
    SmsSendService(),
  );
});

final smsFallbackEngineProvider = Provider<SmsFallbackEngine>((ref) {
  final engine = SmsFallbackEngine(ref.watch(smsRepositoryProvider));
  ref.onDispose(engine.stop);
  return engine;
});

class SmsState {
  const SmsState({
    this.isRunning = false,
    this.isSending = false,
    this.pendingCount = 0,
    this.lastSentAt,
    this.simSnapshot,
    this.simChanged = false,
    this.error,
    this.emergencyNumberConfigured = false,
  });

  final bool isRunning;
  final bool isSending;
  final int pendingCount;
  final DateTime? lastSentAt;
  final SimSnapshot? simSnapshot;
  final bool simChanged;
  final String? error;
  final bool emergencyNumberConfigured;

  SmsState copyWith({
    bool? isRunning,
    bool? isSending,
    int? pendingCount,
    DateTime? lastSentAt,
    SimSnapshot? simSnapshot,
    bool? simChanged,
    String? error,
    bool? emergencyNumberConfigured,
    bool clearError = false,
  }) {
    return SmsState(
      isRunning: isRunning ?? this.isRunning,
      isSending: isSending ?? this.isSending,
      pendingCount: pendingCount ?? this.pendingCount,
      lastSentAt: lastSentAt ?? this.lastSentAt,
      simSnapshot: simSnapshot ?? this.simSnapshot,
      simChanged: simChanged ?? this.simChanged,
      error: clearError ? null : (error ?? this.error),
      emergencyNumberConfigured:
          emergencyNumberConfigured ?? this.emergencyNumberConfigured,
    );
  }
}

class SmsController extends StateNotifier<SmsState> {
  SmsController(this._ref)
      : super(
          SmsState(
            emergencyNumberConfigured: AppEnv.emergencySmsNumber.isNotEmpty,
          ),
        ) {
    _ref.listen<AsyncValue<dynamic>>(authControllerProvider, (previous, next) {
      if (next.valueOrNull == null) {
        unawaited(stop());
      }
    });
  }

  static const _simSerialKey = 'last_sim_serial';

  final Ref _ref;

  SmsFallbackEngine get _engine => _ref.read(smsFallbackEngineProvider);
  SmsRepository get _repository => _ref.read(smsRepositoryProvider);

  Future<void> start() async {
    _engine.start(onResult: _onSendResult);
    await _refreshSimSnapshot();
    final pending = await _repository.countPending();
    state = state.copyWith(
      isRunning: true,
      pendingCount: pending,
      emergencyNumberConfigured: AppEnv.emergencySmsNumber.isNotEmpty,
      clearError: true,
    );
  }

  Future<void> stop() async {
    await _engine.stop();
    state = SmsState(
      emergencyNumberConfigured: AppEnv.emergencySmsNumber.isNotEmpty,
    );
  }

  Future<void> onLocationCollected(LocationPoint point) async {
    await _engine.onLocationCollected(point);
    final pending = await _repository.countPending();
    state = state.copyWith(pendingCount: pending);
  }

  Future<void> onSyncFailedOffline(LocationPoint? point) async {
    await _engine.onSyncFailedOffline(point);
    final pending = await _repository.countPending();
    state = state.copyWith(pendingCount: pending);
  }

  Future<void> retryNow() async {
    state = state.copyWith(isSending: true);
    await _engine.retryPending();
  }

  Future<void> refreshSimSnapshot() => _refreshSimSnapshot();

  Future<void> _refreshSimSnapshot() async {
    final snapshot = await _repository.readSimSnapshot();
    final prefs = await SharedPreferences.getInstance();
    final previousSerial = prefs.getString(_simSerialKey);
    final changed =
        previousSerial != null && previousSerial != snapshot.serial;

    if (previousSerial == null || changed) {
      await prefs.setString(_simSerialKey, snapshot.serial);
    }

    state = state.copyWith(
      simSnapshot: snapshot,
      simChanged: changed,
    );
  }

  void _onSendResult(SmsSendResult result) {
    state = state.copyWith(
      isSending: false,
      pendingCount: result.remaining,
      lastSentAt: result.hadWork ? DateTime.now() : state.lastSentAt,
      error: result.error,
    );
  }
}

final smsControllerProvider =
    StateNotifierProvider<SmsController, SmsState>(
  (ref) => SmsController(ref),
);
