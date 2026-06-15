import 'package:anti_leba/features/photos/presentation/providers/photo_providers.dart';
import 'package:anti_leba/features/remote_commands/data/services/alarm_service.dart';
import 'package:anti_leba/features/remote_commands/domain/command_type.dart';
import 'package:anti_leba/features/remote_commands/domain/remote_command.dart';
import 'package:anti_leba/features/sim/presentation/providers/sim_providers.dart';
import 'package:anti_leba/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RemoteCommandExecutor {
  RemoteCommandExecutor(this._ref, this._alarm);

  final Ref _ref;
  final AlarmService _alarm;

  Future<void> execute(RemoteCommand command) async {
    switch (command.type) {
      case RemoteCommandType.activateTheftMode:
        await _ref
            .read(simControllerProvider.notifier)
            .activateTheftModeRemotely(deviceId: command.deviceId);
      case RemoteCommandType.requestLiveLocation:
        await _ref
            .read(trackingControllerProvider.notifier)
            .requestLiveLocation();
      case RemoteCommandType.triggerAlarm:
        final duration = command.payload?['durationSeconds'];
        await _alarm.playAlarm(
          durationSeconds: duration is int ? duration : 15,
        );
      case RemoteCommandType.captureImage:
        await _ref.read(photoControllerProvider.notifier).onRemoteCommand();
    }
  }
}
