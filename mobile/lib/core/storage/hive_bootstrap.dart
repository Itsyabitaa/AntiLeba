import 'package:hive_flutter/hive_flutter.dart';

import 'package:anti_leba/features/sms/data/datasources/sms_local_datasource.dart';
import 'package:anti_leba/features/photos/data/datasources/photo_local_datasource.dart';
import 'package:anti_leba/features/tracking/data/datasources/location_local_datasource.dart';

class HiveBootstrap {
  HiveBootstrap._();

  static bool _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready) return;
    await Hive.initFlutter();
    // Untyped boxes — stored maps deserialize as Map<dynamic, dynamic>.
    await Hive.openBox<dynamic>(LocationLocalDataSource.boxName);
    await Hive.openBox<dynamic>(SmsLocalDataSource.pendingBoxName);
    await Hive.openBox<dynamic>(SmsLocalDataSource.sentBoxName);
    await Hive.openBox<dynamic>(PhotoLocalDataSource.boxName);
    _ready = true;
  }

  static Future<Box<dynamic>> pendingLocationsBox() async {
    await ensureInitialized();
    return Hive.box<dynamic>(LocationLocalDataSource.boxName);
  }

  static Future<Box<dynamic>> pendingSmsBox() async {
    await ensureInitialized();
    return Hive.box<dynamic>(SmsLocalDataSource.pendingBoxName);
  }

  static Future<Box<dynamic>> sentSmsBox() async {
    await ensureInitialized();
    return Hive.box<dynamic>(SmsLocalDataSource.sentBoxName);
  }

  static Future<Box<dynamic>> pendingPhotosBox() async {
    await ensureInitialized();
    return Hive.box<dynamic>(PhotoLocalDataSource.boxName);
  }
}
