import 'dart:io';

import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationPermissionService {
  Future<bool> ensureGranted() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return true;
    }

    var status = await Permission.locationWhenInUse.status;
    if (!status.isGranted) {
      status = await Permission.locationWhenInUse.request();
    }
    if (!status.isGranted) return false;

    if (Platform.isAndroid) {
      var bg = await Permission.locationAlways.status;
      if (!bg.isGranted) {
        bg = await Permission.locationAlways.request();
      }
      return bg.isGranted || status.isGranted;
    }

    var always = await Permission.locationAlways.status;
    if (!always.isGranted) {
      always = await Permission.locationAlways.request();
    }
    return always.isGranted || status.isGranted;
  }

  Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();
}
