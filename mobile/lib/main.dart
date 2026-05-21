import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti_leba/app.dart';
import 'package:anti_leba/core/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AntiLebaApp(),
    ),
  );
}
