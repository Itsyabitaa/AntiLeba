import 'dart:async';

import 'package:anti_leba/core/logging/app_logger.dart';
import 'package:anti_leba/features/sim/domain/sim_config.dart';
import 'package:anti_leba/features/sim/domain/sim_repository.dart';
import 'package:anti_leba/features/sms/data/services/sim_status_service.dart';

typedef SimChangeCallback = void Function(SimChangeEvent event);

/// Watches SIM serial/operator and fires when it diverges from the registered baseline.
class SimMonitorEngine {
  SimMonitorEngine({SimStatusService? simStatus})
      : _simStatus = simStatus ?? SimStatusService();

  final SimStatusService _simStatus;

  StreamSubscription<dynamic>? _nativeSub;
  Timer? _pollTimer;
  String? _deviceId;
  String? _registeredSerial;
  String? _registeredOperator;
  SimChangeCallback? _onChange;
  bool _handling = false;

  bool get isRunning => _pollTimer != null;

  void start({
    required String deviceId,
    required String? registeredSerial,
    required String? registeredOperator,
    required SimChangeCallback onChange,
  }) {
    if (isRunning) return;

    _deviceId = deviceId;
    _registeredSerial = registeredSerial;
    _registeredOperator = registeredOperator;
    _onChange = onChange;

    _pollTimer = Timer.periodic(SimConfig.pollInterval, (_) {
      unawaited(_evaluate());
    });

    _nativeSub = _simStatus.watchChanges().listen((_) {
      unawaited(_evaluate());
    });

    unawaited(_evaluate());
    AppLogger.I.i('SimMonitorEngine started');
  }

  Future<void> stop() async {
    if (!isRunning) return;
    await _nativeSub?.cancel();
    _nativeSub = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    _deviceId = null;
    _registeredSerial = null;
    _registeredOperator = null;
    _onChange = null;
    AppLogger.I.i('SimMonitorEngine stopped');
  }

  Future<void> _evaluate() async {
    if (_handling || _deviceId == null || _onChange == null) return;

    final current = await _simStatus.readSnapshot();
    final baseline = _registeredSerial;

    if (!_isTrackable(baseline)) {
      AppLogger.I.d('SIM baseline not set — skipping change detection');
      return;
    }

    if (!_isTrackable(current.serial) || current.serial == baseline) {
      return;
    }

    _handling = true;
    try {
      final event = SimChangeEvent(
        clientEventId: 'sim-${DateTime.now().millisecondsSinceEpoch}',
        deviceId: _deviceId!,
        previousSerial: baseline!,
        newSerial: current.serial,
        previousOperator: _registeredOperator ?? 'UNKNOWN',
        newOperator: current.operator,
        detectedAt: DateTime.now().toUtc(),
        currentSim: current,
      );

      AppLogger.I.w(
        'SIM change detected: $baseline → ${current.serial}',
      );
      _onChange!.call(event);
    } finally {
      _handling = false;
    }
  }

  bool _isTrackable(String? value) =>
      value != null && value.isNotEmpty && value != 'UNKNOWN';
}
