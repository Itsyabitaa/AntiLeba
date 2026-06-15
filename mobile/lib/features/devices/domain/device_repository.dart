import 'package:anti_leba/features/devices/domain/device.dart';

abstract class DeviceRepository {
  Future<Device> registerCurrentDevice();
  Future<List<Device>> listDevices();
}
