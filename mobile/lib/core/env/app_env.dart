/// Compile-time configuration. Override with:
///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000
class AppEnv {
  const AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  /// NestJS global prefix — appended to [apiBaseUrl] by Dio.
  static const String apiPrefix = '/api';

  static String get apiRoot => '$apiBaseUrl$apiPrefix';

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Anti-Leba',
  );

  static const bool enableVerboseLogs = bool.fromEnvironment(
    'VERBOSE_LOGS',
    defaultValue: true,
  );
}
