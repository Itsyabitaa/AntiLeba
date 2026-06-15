class PhotoConfig {
  PhotoConfig._();

  static const Duration retryInterval = Duration(minutes: 2);
  static const int maxAttempts = 3;
}
