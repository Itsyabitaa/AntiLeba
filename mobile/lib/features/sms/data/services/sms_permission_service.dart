import 'package:permission_handler/permission_handler.dart';

class SmsPermissionService {
  Future<bool> ensureGranted() async {
    final status = await Permission.sms.status;
    if (status.isGranted) return true;

    final result = await Permission.sms.request();
    if (result.isGranted) return true;

    // Some OEM builds map SMS to phone permission.
    final phone = await Permission.phone.request();
    return phone.isGranted;
  }
}
