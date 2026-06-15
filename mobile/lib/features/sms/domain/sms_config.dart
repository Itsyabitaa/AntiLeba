class SmsConfig {
  const SmsConfig._();

  static const int maxAttempts = 3;
  static const Duration retryInterval = Duration(minutes: 2);
}
