import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/expense.dart';

class ApiService {
  ApiService({required this.baseUrl, required this.readToken});

  final String baseUrl;
  final Future<String?> Function() readToken;

  Future<Map<String, String>> _headers() async {
    final token = await readToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Expense>> fetchExpenses(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/gastos?user_id=${Uri.encodeQueryComponent(userId)}'),
      headers: await _headers(),
    );
    _ensureSuccess(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (decoded['data'] as List<dynamic>? ?? const []);
    return rows.map((row) => _expenseFromApi(row as Map<String, dynamic>, userId)).toList();
  }

  Future<Expense> createExpense(Expense expense) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/gastos'),
      headers: await _headers(),
      body: jsonEncode(expense.toApiPayload()),
    );
    _ensureSuccess(response);
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
    );
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('HTTP ${response.statusCode}: ${response.body}');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}