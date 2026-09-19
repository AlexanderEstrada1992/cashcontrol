import 'dart:convert';

import '../models/expense.dart';
import '../models/user.dart';
import 'api_client.dart';

class ApiService {
  ApiService({required this.client});

  final ApiClient client;

  Future<AuthSession> login({required String username, required String password}) async {
    final response = await client.post('/api/auth/login', authenticated: false, body: {
      'username': username,
      'password': password,
    });
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthSession(
      user: User(id: data['userId'] as String, username: username),
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<Map<String, dynamic>> health() async {
    final response = await client.get('/api/health', authenticated: false);
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<Expense>> fetchExpenses(String userId) async {
    final response = await client.get('/api/gastos', queryParameters: {'user_id': userId});
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (decoded['data'] as List<dynamic>? ?? const []);
    return rows.map((row) => _expenseFromApi(row as Map<String, dynamic>, userId)).toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await client.post('/api/gastos', body: expense.toApiPayload());
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return _expenseFromApi(decoded['data'] as Map<String, dynamic>, expense.userId);
  }

  Expense _expenseFromApi(Map<String, dynamic> data, String userId) {
    final serverTimestamp = DateTime.tryParse(data['updated_at']?.toString() ?? '') ?? DateTime.now().toUtc();
    return Expense(
      localId: data['local_id']?.toString() ?? data['client_operation_id'].toString(),
      serverId: (data['server_id'] as num?)?.toInt(),
      clientOperationId: data['client_operation_id'].toString(),
      userId: data['user_id']?.toString() ?? userId,
      categoryId: data['category_id']?.toString() ?? 'general',
      amount: (data['amount'] as num).toDouble(),
      description: data['description']?.toString() ?? '',
      date: DateTime.parse(data['date'].toString()),
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ?? serverTimestamp,
      updatedAt: serverTimestamp,
      syncStatus: 'synced',
      lastSyncedAt: serverTimestamp,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

}

class AuthSession {
  const AuthSession({required this.user, required this.accessToken, required this.refreshToken});
  final User user;
  final String accessToken;
  final String refreshToken;
}
