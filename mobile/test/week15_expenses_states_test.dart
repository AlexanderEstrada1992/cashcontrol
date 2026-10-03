import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/expense.dart';
import 'package:mobile/repositories/expense_repository.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/local_database.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:mobile/state/app_controller.dart';
import 'package:mobile/state/operation_state.dart';

void main() {
  late AppController controller;

  setUp(() async {
    final storage = _TestStorage();
    final api = ApiService(
      client: ApiClient(
        baseUrl: 'https://cashcontrol.test',
        storage: storage,
        client: MockClient((_) async => http.Response('{}', 200)),
      ),
    );
    controller = AppController(
      storage: storage,
      api: api,
      repository: _TestRepository(api),
      connectivity: () async => false,
      subscribe: false,
    );
    await controller.initialize();
  });

  tearDown(() => controller.dispose());

  Future<void> showExpenses(WidgetTester tester) async {
    await tester.pumpWidget(CashControlApp(controller: controller));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('shows the loading state', (tester) async {
    controller.cachedExpenses = [];
    controller.expensesState = const LoadingState();
    await showExpenses(tester);

    expect(find.text('Cargando datos...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('shows cached expense data', (tester) async {
    controller.cachedExpenses = [_expense];
    controller.expensesState = DataState([_expense]);
    await showExpenses(tester);

    expect(find.text('Gasto de prueba'), findsOneWidget);
  });

  testWidgets('shows the empty state', (tester) async {
    controller.cachedExpenses = [];
    controller.expensesState = const DataState([]);
    await showExpenses(tester);

    expect(find.text('No hay gastos para mostrar'), findsOneWidget);
  });

  testWidgets('shows the load error state', (tester) async {
    controller.cachedExpenses = [];
    controller.expensesState = const ErrorState('API no disponible');
    await showExpenses(tester);

    expect(find.text('No se pudo cargar la información'), findsOneWidget);
    expect(find.text('API no disponible'), findsOneWidget);
  });
}

final _timestamp = DateTime.utc(2026, 10, 3);
final _expense = Expense(
  localId: 'local-test-op',
  clientOperationId: 'test-op',
  userId: 'internal-test-user',
  amount: 12.5,
  description: 'Gasto de prueba',
  date: _timestamp,
  createdAt: _timestamp,
  updatedAt: _timestamp,
  syncStatus: 'synced',
);

class _TestStorage extends SecureStorageService {
  @override
  Future<String?> getUserId() async => 'internal-test-user';

  @override
  Future<String?> getAccessToken() async => 'test-access-token';
}

class _TestRepository extends ExpenseRepository {
  _TestRepository(ApiService api) : super(database: LocalDatabase(), api: api);

  @override
  Future<List<Expense>> getLocalExpenses(String userId) async => [];

  @override
  Future<DateTime?> getLastSync(String userId) async => _timestamp;
}
