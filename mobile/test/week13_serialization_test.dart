import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/expense.dart';
import 'package:mobile/models/user.dart';

void main() {
  test('Expense serializes the backend field names', () {
    final expense = Expense.fromJson({
      'server_id': 42,
      'client_operation_id': 'op-1',
      'user_id': 'demo-user',
      'category_id': 'general',
      'amount': 12.5,
      'description': 'Cafe',
      'date': '2026-09-13T10:00:00.000Z',
      'created_at': '2026-09-13T10:00:00.000Z',
      'updated_at': '2026-09-13T10:00:00.000Z',
    });

    expect(expense.serverId, 42);
    expect(expense.clientOperationId, 'op-1');
    expect(expense.toJson()['server_id'], 42);
    expect(expense.toJson()['client_operation_id'], 'op-1');
  });

  test('User generated serialization preserves required fields', () {
    const user = User(id: 'demo-user', username: 'demo-user');
    expect(User.fromJson(user.toJson()).username, 'demo-user');
  });
}
