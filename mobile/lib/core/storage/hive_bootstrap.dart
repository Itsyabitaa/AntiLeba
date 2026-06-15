import 'package:hive_flutter/hive_flutter.dart';

import 'package:anti_leba/features/tracking/data/datasources/location_local_datasource.dart';

class HiveBootstrap {
  HiveBootstrap._();

  static bool _ready = false;

  static Future<void> ensureInitialized() async {
    if (_ready) return;
    await Hive.initFlutter();
    await Hive.openBox<Map<String, dynamic>>(LocationLocalDataSource.boxName);
    _ready = true;
  }

  static Future<Box<Map<String, dynamic>>> pendingLocationsBox() async {
    await ensureInitialized();
    return Hive.box<Map<String, dynamic>>(LocationLocalDataSource.boxName);
  }
}
