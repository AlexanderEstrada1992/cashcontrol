import '../models/expense.dart';
import '../services/api_service.dart';

class ExpenseRemoteDataSource {
  const ExpenseRemoteDataSource(this.api);

  final ApiService api;

  Future<List<Expense>> fetchExpenses(String userId) => api.fetchExpenses(userId);
  Future<Expense> createExpense(Expense expense) => api.createExpense(expense);
}
