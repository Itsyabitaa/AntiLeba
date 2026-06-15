import 'dart:async';

import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:anti_leba/core/env/app_env.dart';
import 'package:anti_leba/features/remote_commands/domain/remote_command.dart';

typedef RemoteCommandHandler = Future<void> Function(RemoteCommand command);

class RemoteCommandWebSocket {
  RemoteCommandWebSocket({Logger? logger}) : _logger = logger ?? Logger();

  final Logger _logger;
  io.Socket? _socket;
  RemoteCommandHandler? _onCommand;

  bool get isConnected => _socket?.connected ?? false;

  Future<void> connect({
    required String token,
    required String deviceId,
    required RemoteCommandHandler onCommand,
  }) async {
    await disconnect();

    _onCommand = onCommand;
    final completer = Completer<void>();

    _socket = io.io(
      AppEnv.commandsWsUrl,
      io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .setAuth(<String, dynamic>{'token': token})
          .enableReconnection()
          .setReconnectionAttempts(8)
          .setReconnectionDelay(3000)
          .build(),
    );

    final socket = _socket!;

    socket.onConnect((_) {
      _logger.i('Remote command WS connected — registering device');
      socket.emitWithAck(
        'device:register',
        <String, String>{'deviceId': deviceId},
        ack: (dynamic response) {
          _logger.d('device:register ack: $response');
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
    });

    socket.on('command:execute', (dynamic data) async {
      if (data is! Map) return;
      final command = RemoteCommand.fromJson(Map<String, dynamic>.from(data));
      if (command.deviceId != deviceId) {
        _logger.w('Ignoring command for foreign device ${command.deviceId}');
        return;
      }
      final handler = _onCommand;
      if (handler != null) {
        await handler(command);
      }
    });

    socket.onConnectError((dynamic error) {
      _logger.e('Remote command WS connect_error: $error');
      if (!completer.isCompleted) {
        completer.completeError(error is Object ? error : 'connect_error');
      }
    });

    socket.on('error', (dynamic error) {
      _logger.e('Remote command WS error: $error');
    });

    socket.onDisconnect((_) {
      _logger.w('Remote command WS disconnected');
    });

    socket.connect();

    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {
        if (socket.connected) return;
        throw TimeoutException('Remote command WS registration timed out');
      },
    );
  }

  Future<void> ack({
    required String commandId,
    required String deviceId,
    required String status,
    String? errorMessage,
  }) async {
    final socket = _socket;
    if (socket == null || !socket.connected) return;

    socket.emitWithAck(
      'command:ack',
      <String, dynamic>{
        'commandId': commandId,
        'deviceId': deviceId,
        'status': status,
        if (errorMessage != null) 'errorMessage': errorMessage,
      },
      ack: (_) {},
    );
  }

  Future<void> disconnect() async {
    _socket?.dispose();
    _socket = null;
    _onCommand = null;
  }
}
