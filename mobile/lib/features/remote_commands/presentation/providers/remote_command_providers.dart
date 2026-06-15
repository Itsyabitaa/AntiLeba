import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti_leba/core/network/access_token_provider.dart';
import 'package:anti_leba/features/remote_commands/data/remote_command_executor.dart';
import 'package:anti_leba/features/remote_commands/data/remote_command_websocket.dart';
import 'package:anti_leba/features/remote_commands/data/services/alarm_service.dart';
import 'package:anti_leba/features/remote_commands/domain/remote_command.dart';

final alarmServiceProvider = Provider<AlarmService>((ref) => AlarmService());

final remoteCommandWebSocketProvider = Provider<RemoteCommandWebSocket>((ref) {
  final socket = RemoteCommandWebSocket();
  ref.onDispose(() => unawaited(socket.disconnect()));
  return socket;
});

final remoteCommandExecutorProvider = Provider<RemoteCommandExecutor>((ref) {
  return RemoteCommandExecutor(ref, ref.watch(alarmServiceProvider));
});

class RemoteCommandState {
  const RemoteCommandState({
    this.isListening = false,
    this.isConnected = false,
    this.lastCommand,
    this.lastExecutedAt,
    this.lastAckStatus,
    this.error,
  });

  final bool isListening;
  final bool isConnected;
  final RemoteCommand? lastCommand;
  final DateTime? lastExecutedAt;
  final String? lastAckStatus;
  final String? error;

  RemoteCommandState copyWith({
    bool? isListening,
    bool? isConnected,
    RemoteCommand? lastCommand,
    DateTime? lastExecutedAt,
    String? lastAckStatus,
    String? error,
    bool clearError = false,
  }) {
    return RemoteCommandState(
      isListening: isListening ?? this.isListening,
      isConnected: isConnected ?? this.isConnected,
      lastCommand: lastCommand ?? this.lastCommand,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      lastAckStatus: lastAckStatus ?? this.lastAckStatus,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class RemoteCommandController extends StateNotifier<RemoteCommandState> {
  RemoteCommandController(this._ref) : super(const RemoteCommandState());

  final Ref _ref;
  String? _deviceId;

  RemoteCommandWebSocket get _socket =>
      _ref.read(remoteCommandWebSocketProvider);
  RemoteCommandExecutor get _executor =>
      _ref.read(remoteCommandExecutorProvider);

  Future<void> start(String deviceId) async {
    _deviceId = deviceId;
    final token = _ref.read(accessTokenProvider);
    if (token == null || token.isEmpty) {
      state = state.copyWith(
        isListening: false,
        error: 'Missing auth token for remote commands',
      );
      return;
    }

    state = state.copyWith(isListening: true, clearError: true);

    try {
      await _socket.connect(
        token: token,
        deviceId: deviceId,
        onCommand: _handleCommand,
      );
      state = state.copyWith(
        isConnected: true,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isConnected: false,
        error: error.toString(),
      );
    }
  }

  Future<void> stop() async {
    await _socket.disconnect();
    _deviceId = null;
    state = const RemoteCommandState();
  }

  Future<void> _handleCommand(RemoteCommand command) async {
    state = state.copyWith(lastCommand: command, clearError: true);
    final deviceId = _deviceId;
    if (deviceId == null) return;

    try {
      await _executor.execute(command);
      await _socket.ack(
        commandId: command.id,
        deviceId: deviceId,
        status: 'ACKNOWLEDGED',
      );
      state = state.copyWith(
        lastExecutedAt: DateTime.now(),
        lastAckStatus: 'ACKNOWLEDGED',
      );
    } catch (error) {
      await _socket.ack(
        commandId: command.id,
        deviceId: deviceId,
        status: 'FAILED',
        errorMessage: error.toString(),
      );
      state = state.copyWith(
        lastAckStatus: 'FAILED',
        error: error.toString(),
      );
    }
  }
}

final remoteCommandControllerProvider =
    StateNotifierProvider<RemoteCommandController, RemoteCommandState>(
  (ref) => RemoteCommandController(ref),
);
