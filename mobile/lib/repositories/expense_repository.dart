import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/expense_local_data_source.dart';
import '../data/expense_remote_data_source.dart';
import '../models/expense.dart';
import '../services/api_service.dart';
import '../services/local_database.dart';

class ExpenseRepository {
  ExpenseRepository({required this.database, required this.api, ExpenseLocalDataSource? local, ExpenseRemoteDataSource? remote})
      : local = local ?? ExpenseLocalDataSource(database),
        remote = remote ?? ExpenseRemoteDataSource(api);

  final LocalDatabase database;
  final ApiService api;
  final ExpenseLocalDataSource local;
  final ExpenseRemoteDataSource remote;

  Future<List<Expense>> getLocalExpenses(String userId) => local.getExpenses(userId);

  Future<DateTime?> getLastSync(String userId) => local.getLastSync(userId);

  Future<bool> hasLocalExpense({
    required String userId,
    required double amount,
    required String description,
    required DateTime date,
  }) async {
    final db = await database.database;
    final rows = await db.query(
      'expenses',
      columns: ['local_id'],
      where: 'user_id = ? AND amount = ? AND description = ? AND expense_date >= ? AND expense_date < ?',
      whereArgs: [
        userId,
        amount,
        description,
        DateTime.utc(date.year, date.month, date.day).toIso8601String(),
        DateTime.utc(date.year, date.month, date.day + 1).toIso8601String(),
      ],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  Future<void> refreshFromServer(String userId) async {
    final remoteExpenses = await remote.fetchExpenses(userId);
    await local.saveRemoteExpenses(userId, remoteExpenses);
  }

  Future<Expense> createOfflineExpense({
    required String userId,
    required double amount,
    required String description,
    required DateTime date,
    String categoryId = 'general',
  }) async {
    final now = DateTime.now().toUtc();
    final operationId = '${userId}_${now.microsecondsSinceEpoch}';
    final expense = Expense(
      localId: 'local_$operationId',
      clientOperationId: operationId,
      userId: userId,
      categoryId: categoryId,
      amount: amount,
      description: description,
      date: date,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'pending',
    );
    return local.createPending(expense);
  }

  Future<SyncReport> syncPending(String userId) async {
    final db = await database.database;
    final now = DateTime.now().toUtc();
    final operations = await db.query(
      'pending_operations',
      where: 'user_id = ? AND status IN (?, ?) AND next_attempt_at <= ?',
      whereArgs: [userId, 'pending', 'failed', now.toIso8601String()],
      orderBy: 'created_at ASC',
    );
    var synced = 0;
    var failed = 0;
    for (final operation in operations) {
      final operationId = operation['client_operation_id']! as String;
      final attempts = operation['attempt_count']! as int;
      try {
        final payload = jsonDecode(operation['payload']! as String) as Map<String, dynamic>;
        final remote = await api.createExpense(_expenseFromPayload(payload));
        await db.transaction((transaction) async {
          await transaction.insert(
            'expenses',
            remote.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await transaction.delete(
            'pending_operations',
            where: 'client_operation_id = ?',
            whereArgs: [operationId],
          );
        });
        synced++;
      } catch (_) {
        final nextAttempts = attempts + 1;
        final isFailed = nextAttempts >= 5;
        final delaySeconds = 1 << (nextAttempts > 0 ? nextAttempts - 1 : 0);
        await db.update(
          'pending_operations',
          {
            'attempt_count': nextAttempts,
            'next_attempt_at': now
                .add(Duration(seconds: delaySeconds > 8 ? 8 : delaySeconds))
                .toIso8601String(),
            'status': isFailed ? 'failed' : 'pending',
          },
          where: 'client_operation_id = ?',
          whereArgs: [operationId],
        );
        await db.update(
          'expenses',
          {'sync_status': isFailed ? 'failed' : 'pending'},
          where: 'client_operation_id = ?',
          whereArgs: [operationId],
        );
        failed++;
      }
    }
    return SyncReport(synced: synced, failed: failed);
  }

  Expense _expenseFromPayload(Map<String, dynamic> payload) => Expense(
        localId: payload['client_operation_id'] as String,
        clientOperationId: payload['client_operation_id'] as String,
        userId: payload['user_id'] as String,
        categoryId: payload['category_id'] as String,
        amount: (payload['amount'] as num).toDouble(),
        description: payload['description'] as String,
        date: DateTime.parse(payload['date'] as String),
        createdAt: DateTime.parse(payload['updated_at'] as String),
        updatedAt: DateTime.parse(payload['updated_at'] as String),
        syncStatus: 'pending',
      );
}

class SyncReport {
  const SyncReport({required this.synced, required this.failed});
  final int synced;
  final int failed;
}