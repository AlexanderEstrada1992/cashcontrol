import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../repositories/expense_repository.dart';

class SyncService {
  SyncService({required this.repository});

  final ExpenseRepository repository;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  bool _running = false;

  void start({
    required String userId,
    required Future<void> Function() onChanged,
    Future<void> Function(bool online)? onConnectivityChanged,
  }) {
    _subscription = Connectivity().onConnectivityChanged.listen((results) async {
      final online = results.any((result) => result != ConnectivityResult.none);
      await onConnectivityChanged?.call(online);
      if (online) {
        await sync(userId);
        await onChanged();
      }
    });
  }

  Future<SyncReport> sync(String userId) async {
    if (_running) return const SyncReport(synced: 0, failed: 0);
    _running = true;
    try {
      return await repository.syncPending(userId);
    } finally {
      _running = false;
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
  }
}