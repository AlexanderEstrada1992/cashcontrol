import 'dart:convert';

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

  Future<void> saveRemoteExpenses(String userId, List<Expense> expenses) async {
    final db = await database.database;
    await db.transaction((transaction) async {
      for (final expense in expenses) {
        await transaction.insert('expenses', expense.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await transaction.insert(
        'app_metadata',
        {'key': 'last_sync_$userId', 'value': DateTime.now().toUtc().toIso8601String()},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
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
