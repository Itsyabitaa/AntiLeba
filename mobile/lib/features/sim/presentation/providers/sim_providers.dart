import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anti_leba/core/network/dio_client.dart';
import 'package:anti_leba/features/devices/domain/device.dart';
import 'package:anti_leba/features/sim/data/datasources/sim_remote_datasource.dart';
import 'package:anti_leba/features/sim/data/repositories/sim_repository_impl.dart';
import 'package:anti_leba/features/sim/data/sim_monitor_engine.dart';
import 'package:anti_leba/features/sim/domain/sim_repository.dart';
import 'package:anti_leba/features/sms/data/services/battery_status_service.dart';
import 'package:anti_leba/features/sms/data/services/sim_status_service.dart';
import 'package:anti_leba/features/sms/data/services/sms_message_formatter.dart';
import 'package:anti_leba/features/sms/data/services/sms_permission_service.dart';
import 'package:anti_leba/features/sms/data/services/sms_send_service.dart';
import 'package:anti_leba/features/sms/domain/sms_alert.dart';
import 'package:anti_leba/features/tracking/domain/location_point.dart';

final simRemoteDataSourceProvider = Provider<SimRemoteDataSource>((ref) {
  return SimRemoteDataSource(ref.watch(dioProvider));
});

final simRepositoryProvider = Provider<SimRepository>((ref) {
  return SimRepositoryImpl(
    ref.watch(simRemoteDataSourceProvider),
    SimStatusService(),
    SmsPermissionService(),
    BatteryStatusService(),
    const SmsMessageFormatter(),
    SmsSendService(),
  );
});

final simMonitorEngineProvider = Provider<SimMonitorEngine>((ref) {
  final engine = SimMonitorEngine();
  ref.onDispose(engine.stop);
  return engine;
});

class SimState {
  const SimState({
    this.isMonitoring = false,
    this.theftModeActive = false,
    this.simSnapshot,
    this.registeredSerial,
    this.lastChangeAt,
    this.lastAlertSentAt,
    this.error,
  });

  final bool isMonitoring;
  final bool theftModeActive;
  final SimSnapshot? simSnapshot;
  final String? registeredSerial;
  final DateTime? lastChangeAt;
  final DateTime? lastAlertSentAt;
  final String? error;

  SimState copyWith({
    bool? isMonitoring,
    bool? theftModeActive,
    SimSnapshot? simSnapshot,
    String? registeredSerial,
    DateTime? lastChangeAt,
    DateTime? lastAlertSentAt,
    String? error,
    bool clearError = false,
  }) {
    return SimState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      theftModeActive: theftModeActive ?? this.theftModeActive,
      simSnapshot: simSnapshot ?? this.simSnapshot,
      registeredSerial: registeredSerial ?? this.registeredSerial,
      lastChangeAt: lastChangeAt ?? this.lastChangeAt,
      lastAlertSentAt: lastAlertSentAt ?? this.lastAlertSentAt,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SimController extends StateNotifier<SimState> {
  SimController(this._ref) : super(const SimState());

  static const _registeredSerialKey = 'registered_sim_serial';
  static const _registeredOperatorKey = 'registered_sim_operator';

  final Ref _ref;
  LocationPoint? _lastLocation;
  bool _responding = false;

  SimMonitorEngine get _engine => _ref.read(simMonitorEngineProvider);
  SimRepository get _repository => _ref.read(simRepositoryProvider);

  Future<void> start({
    required String deviceId,
    Device? device,
    LocationPoint? lastLocation,
  }) async {
    _lastLocation = lastLocation;
    final prefs = await SharedPreferences.getInstance();

    var registeredSerial =
        device?.simSerial ?? prefs.getString(_registeredSerialKey);
    var registeredOperator =
        device?.simOperator ?? prefs.getString(_registeredOperatorKey);

    final current = await _repository.readSimSnapshot();
    if (!_isTrackable(registeredSerial) && _isTrackable(current.serial)) {
      registeredSerial = current.serial;
      registeredOperator = current.operator;
      await prefs.setString(_registeredSerialKey, registeredSerial);
      await prefs.setString(_registeredOperatorKey, registeredOperator);
    }

    _engine.start(
      deviceId: deviceId,
      registeredSerial: registeredSerial,
      registeredOperator: registeredOperator,
      onChange: (event) => unawaited(_onSimChange(event)),
    );

    state = state.copyWith(
      isMonitoring: true,
      simSnapshot: current,
      registeredSerial: registeredSerial,
      clearError: true,
    );
  }

  Future<void> stop() async {
    await _engine.stop();
    state = const SimState();
  }

  void updateLastLocation(LocationPoint? point) {
    _lastLocation = point;
  }

  Future<void> _onSimChange(SimChangeEvent event) async {
    if (_responding || state.theftModeActive) return;
    _responding = true;

    try {
      state = state.copyWith(
        theftModeActive: true,
        lastChangeAt: event.detectedAt,
        simSnapshot: event.currentSim,
        clearError: true,
      );

      final report = await _repository.reportChange(event);
      if (!report.reported) {
        state = state.copyWith(error: report.error);
      }

      try {
        await _repository.sendTheftAlert(
          event: event,
          deviceIdForSms: event.deviceId,
          latitude: _lastLocation?.latitude,
          longitude: _lastLocation?.longitude,
        );
        state = state.copyWith(lastAlertSentAt: DateTime.now());
      } catch (error) {
        state = state.copyWith(error: error.toString());
      }
    } finally {
      _responding = false;
    }
  }

  bool _isTrackable(String? value) =>
      value != null && value.isNotEmpty && value != 'UNKNOWN';
}

final simControllerProvider =
    StateNotifierProvider<SimController, SimState>(
  (ref) => SimController(ref),
);
