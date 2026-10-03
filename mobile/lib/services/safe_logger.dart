import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show debugPrint;

enum SafeLogEvent {
  syncStarted,
  syncCompleted,
  syncFailed,
  apiFailure,
  slowFrame,
  performanceWindow,
}

typedef LogSink = void Function(String message);

class SafeLogger {
  SafeLogger({LogSink? sink}) : _sink = sink ?? _writeToDeveloperLog;

  final LogSink _sink;

  void record(
    SafeLogEvent event, {
    int? count,
    int? attempt,
    int? statusCode,
    int? durationMs,
    int? buildMs,
    int? rasterMs,
    int? frameCount,
    int? slowFrameCount,
  }) {
    final values = <String, Object?>{
      'count': count,
      'attempt': attempt,
      'status_code': statusCode,
      'duration_ms': durationMs,
      'build_ms': buildMs,
      'raster_ms': rasterMs,
      'frame_count': frameCount,
      'slow_frame_count': slowFrameCount,
    };
    values.removeWhere((_, value) => value == null);
    _sink(jsonEncode({'event': event.name, ...values}));
  }

  static void _writeToDeveloperLog(String message) {
    developer.log(message, name: 'cashcontrol');
    debugPrint('[cashcontrol] $message');
  }
}
