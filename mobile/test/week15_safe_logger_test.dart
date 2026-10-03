import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/safe_logger.dart';

void main() {
  test('writes structured events with numeric metadata only', () {
    String? message;
    final logger = SafeLogger(sink: (value) => message = value);

    logger.record(SafeLogEvent.apiFailure, statusCode: 503, durationMs: 18);

    expect(jsonDecode(message!), {
      'event': 'apiFailure',
      'status_code': 503,
      'duration_ms': 18,
    });
    expect(message, isNot(contains('token')));
    expect(message, isNot(contains('description')));
    expect(message, isNot(contains('latitude')));
  });
}
