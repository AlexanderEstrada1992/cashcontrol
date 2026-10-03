import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/main.dart';
import 'package:mobile/models/expense.dart';
import 'package:mobile/models/user.dart';
import 'package:mobile/repositories/expense_repository.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/api_errors.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/local_database.dart';
import 'package:mobile/services/secure_storage_service.dart';
import 'package:mobile/state/app_controller.dart';
import 'package:mobile/state/expense_draft.dart';
import 'package:mobile/state/operation_state.dart';
import 'package:mobile/navigation/route_guard.dart';

void main() {
  Future<AppController> controller({bool signedIn = false}) async {
    final storage = _TestStorage(signedIn);
    final api = _TestApi(storage);
    final result = AppController(storage: storage, api: api, repository: _TestRepository(api),
      connectivity: () async => false, subscribe: false);
    await result.initialize();
    return result;
  }

  testWidgets('direct detail address returns to its ID after login', (tester) async {
    final app = await controller();
    await tester.pumpWidget(CashControlApp(controller: app, initialLocation: '/gastos/42'));
    await tester.pumpAndSettle();
    expect(find.text('Iniciar sesión'), findsWidgets);
    await tester.enterText(find.byType(TextFormField).last, 'test-password');
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del gasto'), findsOneWidget);
    expect((app.repository as _TestRepository).requestedId, '42');
    expect(app.authenticated, isTrue);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('creation validates on blur, preserves draft and maps backend 422 fields', (tester) async {
    final app = await controller(signedIn: true);
    await tester.pumpWidget(CashControlApp(controller: app, initialLocation: '/gastos/nuevo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '-2');
    await tester.tap(find.byType(TextFormField).last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Monto: ingrese'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, '25.50');
    await tester.enterText(find.byType(TextFormField).last, 'Transporte');
    await tester.tap(find.byTooltip('Volver y conservar borrador'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Nuevo gasto'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextFormField>(find.byType(TextFormField).first).controller!.text, '25.50');
    expect(tester.widget<TextFormField>(find.byType(TextFormField).last).controller!.text, 'Transporte');
    (app.repository as _TestRepository).creationFailure = const ValidationFailure({'amount': 'Monto rechazado por el servidor'});
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar gasto'));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Monto rechazado por el servidor'), findsOneWidget);
    expect(app.draft.description, 'Transporte');
    (app.repository as _TestRepository).creationFailure = null;
    await tester.enterText(find.byType(TextFormField).first, '30');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Guardar gasto'));
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar gasto'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del gasto'), findsOneWidget);
    expect(app.draft.amount, isEmpty);
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  testWidgets('403 retains session; 401 redirects login and preserves destination', (tester) async {
    final app = await controller(signedIn: true);
    await tester.pumpWidget(CashControlApp(controller: app, initialLocation: '/gastos/nuevo'));
    await tester.pumpAndSettle();
    app.editDraft('description', 'Borrador conservado');
    await app.handleFailure(const ForbiddenFailure());
    await tester.pumpAndSettle();
    expect(find.text('Sin permisos'), findsOneWidget);
    expect(app.authenticated, isTrue);
    await tester.tap(find.widgetWithText(FilledButton, 'Volver a gastos'));
    await tester.pumpAndSettle();
    await app.handleFailure(const AuthenticationFailure());
    await tester.pumpAndSettle();
    expect(app.authenticated, isFalse);
    expect(find.text('Iniciar sesión'), findsWidgets);
    expect(app.draft.description, 'Borrador conservado');
    await tester.pumpWidget(const SizedBox.shrink());
    app.dispose();
  });

  test(
    'private destination survives bootstrap and login without open redirects',
    () {
      final bootstrap = sessionRedirect(
        location: Uri.parse('/gastos/42'),
        ready: false,
        authenticated: false,
        forbidden: false,
      )!;
      final login = sessionRedirect(
        location: Uri.parse(bootstrap),
        ready: true,
        authenticated: false,
        forbidden: false,
      )!;
      expect(Uri.parse(login).path, '/login');
      expect(Uri.parse(login).queryParameters['from'], '/gastos/42');
      expect(
        sessionRedirect(
          location: Uri.parse(login),
          ready: true,
          authenticated: true,
          forbidden: false,
        ),
        '/gastos/42',
      );
      expect(safeDestination('https://example.com'), '/gastos');
      expect(safeDestination('//example.com/gastos'), '/gastos');
    },
  );

  test('403 is a separate route and does not require another login', () {
    final redirect = sessionRedirect(
      location: Uri.parse('/gastos/42'),
      ready: true,
      authenticated: true,
      forbidden: true,
    )!;
    expect(Uri.parse(redirect).path, '/sin-permiso');
    expect(
      sessionRedirect(
        location: Uri.parse(redirect),
        ready: true,
        authenticated: true,
        forbidden: true,
      ),
      isNull,
    );
  });

  test('draft validates the expense contract and survives screen ownership changes', () {
    final draft = ExpenseDraft();
    expect(draft.validate().keys, containsAll(['amount', 'description']));
    draft.edit('amount', '25,50');
    draft.edit('description', 'Transporte');
    expect(draft.validate(), isEmpty);
    expect(ExpenseDraft.validateAmount('1.234'), isNotNull);
    expect(ExpenseDraft.validateAmount('-2'), isNotNull);
    expect(ExpenseDraft.validateDescription('x' * 256), isNotNull);
    draft.serverErrors = {'amount': 'Error remoto'};
    draft.edit('amount', '30');
    expect(draft.serverErrors, isEmpty);
    expect(draft.description, 'Transporte');
    draft.clear();
    expect(draft.amount, isEmpty);
    draft.dispose();
  });

  test('closed operation states are mutually exclusive', () {
    OperationState<String> state = const LoadingState();
    expect(state, isNot(isA<ErrorState<String>>()));
    state = const DataState('ok');
    expect(state, isA<DataState<String>>());
    state = const ErrorState('Error');
    expect(state, isNot(isA<DataState<String>>()));
  });
}

class _TestStorage extends SecureStorageService {
  _TestStorage(bool signedIn) : id = signedIn ? 'test-user' : null, token = signedIn ? 'test-token' : null;
  String? id;
  String? token;
  @override
  Future<String?> getUserId() async => id;
  @override
  Future<String?> getAccessToken() async => token;
  @override
  Future<void> saveSession({required String accessToken, required String refreshToken, required String userId}) async {
    id = userId;
    token = accessToken;
  }
  @override
  Future<void> clearCredentials() async { id = null; token = null; }
}

class _TestApi extends ApiService {
  _TestApi(SecureStorageService storage) : super(client: ApiClient(baseUrl: 'http://127.0.0.1', storage: storage,
    client: MockClient((_) async => http.Response('{}', 200))));
  @override
  Future<AuthSession> login({required String username, required String password}) async => const AuthSession(
    user: User(id: 'test-user', username: 'demo-user'), accessToken: 'test-token', refreshToken: 'test-refresh');
}

class _TestRepository extends ExpenseRepository {
  _TestRepository(ApiService api) : super(database: LocalDatabase(), api: api);
  AppApiException? creationFailure;
  String? requestedId;
  final timestamp = DateTime.utc(2026, 10, 2);
  Expense get expense => Expense(localId: 'op-42', clientOperationId: 'op-42', userId: 'test-user', serverId: 42,
    amount: 25.5, description: 'Gasto real de prueba', date: timestamp, createdAt: timestamp, updatedAt: timestamp, syncStatus: 'synced');
  @override
  Future<List<Expense>> getLocalExpenses(String userId) async => [expense];
  @override
  Future<DateTime?> getLastSync(String userId) async => timestamp;
  @override
  Future<Expense> getExpense(String userId, String id) async { requestedId = id; return expense; }
  @override
  Future<bool> hasLocalExpense({required String userId, required double amount, required String description, required DateTime date}) async => false;
  @override
  Future<Expense> createExpense({required String userId, required String operationId, required double amount,
    required String description, required DateTime date, required bool online, String categoryId = 'general',
    String? receiptPhotoPath, double? latitude, double? longitude}) async {
    if (creationFailure != null) throw creationFailure!;
    return expense;
  }
}
