import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti_leba/core/logging/app_logger.dart';

/// One-shot startup work that must finish before the first frame.
///
/// Returns a configured Riverpod [ProviderContainer] so callers can
/// pre-warm providers (e.g. session, secure storage) before runApp.
Future<ProviderContainer> bootstrap() async {
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.I.e(
      'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
    if (kReleaseMode) {
      // TODO(sprint-later): forward to crash reporter (Sentry/Crashlytics).
    } else {
      FlutterError.presentError(details);
    }
  };

  final container = ProviderContainer();
  return container;
}
