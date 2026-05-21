import 'package:logger/logger.dart';

import 'package:anti_leba/core/env/app_env.dart';

class AppLogger {
  AppLogger._();

  static final AppLogger I = AppLogger._();

  final Logger _logger = Logger(
    level: AppEnv.enableVerboseLogs ? Level.debug : Level.warning,
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 6,
      colors: true,
      printEmojis: false,
    ),
  );

  void d(Object? message) => _logger.d(message);
  void i(Object? message) => _logger.i(message);
  void w(Object? message) => _logger.w(message);
  void e(Object? message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
