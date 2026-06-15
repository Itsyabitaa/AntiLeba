import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:uuid/uuid.dart';

class DeviceRegistrationPayload {
  const DeviceRegistrationPayload({
    required this.deviceUid,
    required this.label,
    this.manufacturer,
    this.model,
    this.osVersion,
    this.appVersion,
  });

  final String deviceUid;
  final String label;
  final String? manufacturer;
  final String? model;
  final String? osVersion;
  final String? appVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'deviceUid': deviceUid,
        'label': label,
        if (manufacturer != null) 'manufacturer': manufacturer,
        if (model != null) 'model': model,
        if (osVersion != null) 'osVersion': osVersion,
        if (appVersion != null) 'appVersion': appVersion,
      };
}

class DeviceInfoService {
  DeviceInfoService(this._storage);

  static const String _fallbackUidKey = 'device_uid_fallback';
  final FlutterSecureStorage _storage;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  Future<DeviceRegistrationPayload> collect() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isAndroid) {
      final android = await _deviceInfo.androidInfo;
      final deviceUid = android.id.isNotEmpty
          ? android.id
          : await _fallbackUid();
      final manufacturer = android.manufacturer;
      final model = android.model;
      return DeviceRegistrationPayload(
        deviceUid: deviceUid,
        label: '$manufacturer $model'.trim(),
        manufacturer: manufacturer,
        model: model,
        osVersion: 'Android ${android.version.release}',
        appVersion: packageInfo.version,
      );
    }

    if (Platform.isIOS) {
      final ios = await _deviceInfo.iosInfo;
      final deviceUid =
          ios.identifierForVendor ?? await _fallbackUid();
      return DeviceRegistrationPayload(
        deviceUid: deviceUid,
        label: ios.name,
        manufacturer: 'Apple',
        model: ios.utsname.machine,
        osVersion: 'iOS ${ios.systemVersion}',
        appVersion: packageInfo.version,
      );
    }

    return DeviceRegistrationPayload(
      deviceUid: await _fallbackUid(),
      label: Platform.operatingSystem,
      osVersion: Platform.operatingSystemVersion,
      appVersion: packageInfo.version,
    );
  }

  Future<String> _fallbackUid() async {
    final existing = await _storage.read(key: _fallbackUidKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final uid = const Uuid().v4();
    await _storage.write(key: _fallbackUidKey, value: uid);
    return uid;
  }
}
