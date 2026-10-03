import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../repositories/expense_repository.dart';
import 'safe_logger.dart';

class SyncService {
  SyncService({required this.repository, SafeLogger? logger})
    : _logger = logger ?? SafeLogger();

  final ExpenseRepository repository;
  final SafeLogger _logger;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _running = false;

  void start({
    required String userId,
    required Future<void> Function() onChanged,
    Future<void> Function(bool online)? onConnectivityChanged,
    Future<void> Function(Object error)? onError,
  }) {
    _subscription?.cancel();
    _subscription = Connectivity().onConnectivityChanged.listen((
      results,
    ) async {
      final online = results.any((result) => result != ConnectivityResult.none);
      await onConnectivityChanged?.call(online);
      if (online) {
        try {
          await sync(userId);
          await onChanged();
        } catch (error) {
          await onError?.call(error);
        }
      }
    });
  }

  Future<SyncReport> sync(String userId) async {
    if (_running) return const SyncReport(synced: 0, failed: 0);
    _running = true;
    final stopwatch = Stopwatch()..start();
    _logger.record(SafeLogEvent.syncStarted);
    try {
      final report = await repository.syncPending(userId);
      _logger.record(
        SafeLogEvent.syncCompleted,
        count: report.synced,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      if (report.failed > 0) {
        _logger.record(
          SafeLogEvent.syncFailed,
          count: report.failed,
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }
      return report;
    } catch (_) {
      _logger.record(
        SafeLogEvent.syncFailed,
        durationMs: stopwatch.elapsedMilliseconds,
      );
      rethrow;
    } finally {
      _running = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}
