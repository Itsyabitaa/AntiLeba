/// Compile-time configuration. Override with:
///   flutter run --dart-define=API_BASE_URL=https://api.example.com
class AppEnv {
  const AppEnv._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );

  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Anti-Leba',
  );

  static const bool enableVerboseLogs = bool.fromEnvironment(
    'VERBOSE_LOGS',
    defaultValue: true,
  );
}
