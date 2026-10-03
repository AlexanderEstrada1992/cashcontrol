import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class MonitoringService {
  static Future<void> run({
    required String dsn,
    required VoidCallback appRunner,
  }) async {
    if (dsn.trim().isEmpty) {
      appRunner();
      return;
    }

    await SentryFlutter.init((options) {
      options.dsn = dsn.trim();
      options.sendDefaultPii = false;
      options.tracesSampleRate = 0;
    }, appRunner: appRunner);
  }
}
