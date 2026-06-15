/// Polling + native SIM broadcast interval for Sprint 6 monitoring.
class SimConfig {
  SimConfig._();

  static const Duration pollInterval = Duration(seconds: 15);
  static const int maxReportAttempts = 3;
}
