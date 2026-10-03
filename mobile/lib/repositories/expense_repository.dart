import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../data/expense_local_data_source.dart';
import '../data/expense_remote_data_source.dart';
import '../models/expense.dart';
import '../services/api_service.dart';
import '../services/api_errors.dart';
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
    final snapshot = await remote.fetchExpenses(userId);
    await local.saveRemoteExpenses(userId, snapshot.expenses, syncedAt: snapshot.syncedAt);
  }

  Future<void> clearUserData(String userId) => local.clearUserData(userId);

  Future<Expense> getExpense(String userId, String id) async {
    final saved = await local.getExpenses(userId);
    Expense? cached;
    for (final expense in saved) {
        if (expense.localId == id || expense.serverId?.toString() == id ||
          (id.startsWith('local_') && expense.clientOperationId == id.substring(6))) {
        cached = expense;
        break;
      }
    }
    if (id.startsWith('local_') && cached != null) return cached;
    if (int.tryParse(id) == null || int.parse(id) <= 0) {
      throw const HttpFailure('No se encontró el gasto solicitado.');
    }
    try {
      final expense = await remote.fetchExpense(id, userId);
      await local.saveRemoteExpenses(userId, [expense]);
      return (await local.getExpenses(userId)).firstWhere((item) => item.clientOperationId == expense.clientOperationId);
    } on NetworkFailure {
      if (cached != null) return cached;
      rethrow;
    }
  }

  Future<Expense> createExpense({
    required String userId,
    required String operationId,
    required double amount,
    required String description,
    required DateTime date,
    required bool online,
    String categoryId = 'general',
    String? receiptPhotoPath,
    double? latitude,
    double? longitude,
  }) async {
    final now = DateTime.now().toUtc();
    final expense = Expense(localId: 'local_$operationId', clientOperationId: operationId, userId: userId,
      amount: amount, description: description, date: date, categoryId: categoryId,
      createdAt: now, updatedAt: now, syncStatus: 'pending', receiptPhotoPath: receiptPhotoPath,
      latitude: latitude, longitude: longitude);
    if (online) {
      try {
        final saved = await remote.createExpense(expense);
        if (receiptPhotoPath != null) {
          final row = saved.toMap()..['receipt_photo_path'] = receiptPhotoPath;
          await local.saveRemoteExpenses(userId, [Expense.fromMap(row)]);
        } else {
          await local.saveRemoteExpenses(userId, [saved]);
        }
        return saved;
      } on NetworkFailure {
        return local.createPending(expense);
      } on ServerFailure {
        return local.createPending(expense);
      }
    }
    return local.createPending(expense);
  }

  Future<Expense> createOfflineExpense({
    required String userId,
    required double amount,
    required String description,
    required DateTime date,
    String categoryId = 'general',
    String? receiptPhotoPath,
    double? latitude,
    double? longitude,
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
      receiptPhotoPath: receiptPhotoPath,
      latitude: latitude,
      longitude: longitude,
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
          final localRows = await transaction.query(
            'expenses',
            columns: ['receipt_photo_path'],
            where: 'client_operation_id = ?',
            whereArgs: [operationId],
            limit: 1,
          );
          final remoteMap = remote.toMap();
          if (localRows.isNotEmpty) {
            remoteMap['receipt_photo_path'] = localRows.first['receipt_photo_path'];
          }
          await transaction.insert(
            'expenses',
            remoteMap,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await transaction.delete(
            'pending_operations',
            where: 'client_operation_id = ?',
            whereArgs: [operationId],
          );
        });
        synced++;
      } catch (error) {
        if (error is AuthenticationFailure || error is ForbiddenFailure) rethrow;
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
        latitude: (payload['latitude'] as num?)?.toDouble(),
        longitude: (payload['longitude'] as num?)?.toDouble(),
      );
}

class SyncReport {
  const SyncReport({required this.synced, required this.failed});
  final int synced;
  final int failed;
}