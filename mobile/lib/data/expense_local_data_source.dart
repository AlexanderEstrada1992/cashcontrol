import 'dart:convert';
import 'dart:io';

import 'package:sqflite/sqflite.dart';

import '../models/expense.dart';
import '../services/local_database.dart';

class ExpenseLocalDataSource {
  const ExpenseLocalDataSource(this.database);

  final LocalDatabase database;

  Future<List<Expense>> getExpenses(String userId) async {
    final rows = await (await database.database).query(
      'expenses',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'expense_date DESC, created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<DateTime?> getLastSync(String userId) async {
    final rows = await (await database.database).query(
      'app_metadata',
      where: 'key = ?',
      whereArgs: ['last_sync_$userId'],
      limit: 1,
    );
    return rows.isEmpty ? null : DateTime.tryParse(rows.first['value']! as String);
  }

  Future<void> saveRemoteExpenses(String userId, List<Expense> expenses, {DateTime? syncedAt}) async {
    final db = await database.database;
    await db.transaction((transaction) async {
      final existing = await transaction.query('expenses',
        columns: ['client_operation_id', 'receipt_photo_path'], where: 'user_id = ?', whereArgs: [userId]);
      final photos = {for (final row in existing) row['client_operation_id']: row['receipt_photo_path']};
      for (final expense in expenses) {
        final row = expense.toMap();
        row['receipt_photo_path'] ??= photos[expense.clientOperationId];
        await transaction.insert('expenses', row, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      if (syncedAt != null) {
        await transaction.insert(
          'app_metadata',
          {'key': 'last_sync_$userId', 'value': syncedAt.toUtc().toIso8601String()},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> clearUserData(String userId) async {
    final db = await database.database;
    final rows = await db.query('expenses', columns: ['receipt_photo_path'],
        where: 'user_id = ?', whereArgs: [userId]);
    for (final row in rows) {
      final path = row['receipt_photo_path'] as String?;
      if (path == null || path.isEmpty) continue;
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // Continue clearing the user's database data if temporary media is unavailable.
      }
    }
    await database.clearUserData(userId);
  }

  Future<Expense> createPending(Expense expense) async {
    final db = await database.database;
    await db.transaction((transaction) async {
      await transaction.insert('expenses', expense.toMap());
      await transaction.insert('pending_operations', {
        'client_operation_id': expense.clientOperationId,
        'operation_type': 'create',
        'entity': 'expense',
        'payload': jsonEncode(expense.toApiPayload()),
        'attempt_count': 0,
        'next_attempt_at': expense.createdAt.toIso8601String(),
        'status': 'pending',
        'created_at': expense.createdAt.toIso8601String(),
        'user_id': expense.userId,
      });
    });
    return expense;
  }
}
