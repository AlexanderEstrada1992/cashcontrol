import 'package:flutter/scheduler.dart';

import 'safe_logger.dart';

class FramePerformanceMonitor {
  FramePerformanceMonitor({SafeLogger? logger})
    : _logger = logger ?? SafeLogger();

  static const Duration _frameBudget = Duration(microseconds: 16667);
  static const int _windowSize = 60;

  final SafeLogger _logger;
  int _frameCount = 0;
  int _slowFrameCount = 0;
  int _maxBuildMs = 0;
  int _maxRasterMs = 0;
  bool _started = false;

  void start() {
    if (_started) return;
    SchedulerBinding.instance.addTimingsCallback(_recordTimings);
    _started = true;
  }

  void stop() {
    if (!_started) return;
    SchedulerBinding.instance.removeTimingsCallback(_recordTimings);
    _started = false;
  }

  void recordFrame({required Duration build, required Duration raster}) {
    _frameCount++;
    if (build > _frameBudget || raster > _frameBudget) {
      _slowFrameCount++;
    }
    if (build.inMilliseconds > _maxBuildMs) {
      _maxBuildMs = build.inMilliseconds;
    }
    if (raster.inMilliseconds > _maxRasterMs) {
      _maxRasterMs = raster.inMilliseconds;
    }

    if (_frameCount < _windowSize) return;
    _logger.record(
      SafeLogEvent.performanceWindow,
      frameCount: _frameCount,
      slowFrameCount: _slowFrameCount,
      buildMs: _maxBuildMs,
      rasterMs: _maxRasterMs,
    );
    _frameCount = 0;
    _slowFrameCount = 0;
    _maxBuildMs = 0;
    _maxRasterMs = 0;
  }

  void _recordTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      recordFrame(build: timing.buildDuration, raster: timing.rasterDuration);
    }
  }
}
