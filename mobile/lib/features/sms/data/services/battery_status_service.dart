import 'package:battery_plus/battery_plus.dart';

class BatteryStatusService {
  BatteryStatusService({Battery? battery}) : _battery = battery ?? Battery();

  final Battery _battery;

  Future<int> readLevelPercent() async {
    try {
      return await _battery.batteryLevel;
    } catch (_) {
      return -1;
    }
  }
}
