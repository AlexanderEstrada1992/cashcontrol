import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/services/frame_performance_monitor.dart';
import 'package:mobile/services/safe_logger.dart';

void main() {
  test('reports aggregate slow-frame metrics once per 60 frames', () {
    final messages = <String>[];
    final monitor = FramePerformanceMonitor(
      logger: SafeLogger(sink: (message) => messages.add(message)),
    );

    for (var frame = 0; frame < 60; frame++) {
      monitor.recordFrame(
        build: const Duration(milliseconds: 20),
        raster: const Duration(milliseconds: 4),
      );
    }

    expect(messages, hasLength(1));
    expect(jsonDecode(messages.single), {
      'event': 'performanceWindow',
      'frame_count': 60,
      'slow_frame_count': 60,
      'build_ms': 20,
      'raster_ms': 4,
    });
    monitor.stop();
  });
}
