import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/models/expense.dart';
import 'package:mobile/repositories/expense_repository.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/local_database.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:mobile/state/app_controller.dart';
import 'package:mobile/state/operation_state.dart';

void main() {
  test(
    'offline refresh preserves cached expenses without issuing HTTP',
    () async {
      var httpRequests = 0;
      final storage = _OfflineStorage();
      final api = ApiService(
        client: ApiClient(
          baseUrl: 'https://cashcontrol.test',
          storage: storage,
          client: MockClient((_) async {
            httpRequests++;
            return http.Response('{}', 200);
          }),
        ),
      );
      final repository = _OfflineRepository(api);
      final controller = AppController(
        storage: storage,
        api: api,
        repository: repository,
        connectivity: () async => false,
        subscribe: false,
      );

      await controller.initialize();
      await controller.refresh();

      expect(controller.expensesState, isA<DataState<List<Expense>>>());
      expect(controller.cachedExpenses, hasLength(1));
      expect(controller.cachedExpenses.single.description, 'Registro local');
      expect(controller.syncMessage, contains('desactualizados'));
      expect(repository.remoteRefreshes, 0);
      expect(httpRequests, 0);

      controller.dispose();
    },
  );
}

class _OfflineStorage extends SecureStorageService {
  @override
  Future<String?> getUserId() async => 'offline-user';

  @override
  Future<String?> getAccessToken() async => 'offline-access';
}

class _OfflineRepository extends ExpenseRepository {
  _OfflineRepository(ApiService api)
    : super(database: LocalDatabase(), api: api);

  int remoteRefreshes = 0;
  final _stamp = DateTime.utc(2026, 10, 1);
  late final _cachedExpense = Expense(
    localId: 'offline-1',
    clientOperationId: 'offline-1',
    userId: 'offline-user',
    amount: 14,
    description: 'Registro local',
    date: _stamp,
    createdAt: _stamp,
    updatedAt: _stamp,
    syncStatus: 'synced',
  );

  @override
  Future<List<Expense>> getLocalExpenses(String userId) async => [
    _cachedExpense,
  ];

  @override
  Future<DateTime?> getLastSync(String userId) async => _stamp;

  @override
  Future<void> refreshFromServer(String userId) async {
    remoteRefreshes++;
  }
}
