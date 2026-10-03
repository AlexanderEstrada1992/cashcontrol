import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/monitoring_service.dart';

void main() {
  test('starts the app normally when Sentry has no DSN', () async {
    var appStarts = 0;

    await MonitoringService.run(dsn: '  ', appRunner: () => appStarts++);

    expect(appStarts, 1);
  });
}
