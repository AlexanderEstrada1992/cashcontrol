import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

import '../models/expense.dart';
import '../models/user.dart';
import '../repositories/expense_repository.dart';
import '../services/api_client.dart';
import '../services/api_errors.dart';
import '../services/api_service.dart';
import '../services/local_database.dart';
import '../services/secure_storage_service.dart';
import '../services/sync_service.dart';
import 'expense_draft.dart';
import 'operation_state.dart';

class AppController extends ChangeNotifier {
  static const Duration localCacheTtl = Duration(hours: 24);

  AppController({
    SecureStorageService? storage,
    ApiService? api,
    ExpenseRepository? repository,
    this.connectivity,
    this.subscribe = true,
  }) : storage = storage ?? SecureStorageService() {
    this.api =
        api ??
        ApiService(
          client: ApiClient(
            baseUrl: const String.fromEnvironment(
              'API_BASE_URL',
              defaultValue: 'http://127.0.0.1:3000',
            ),
            storage: this.storage,
            onTokenRefreshed: () => unawaited(_tokenRefreshed()),
          ),
        );
    this.repository =
        repository ??
        ExpenseRepository(database: LocalDatabase(), api: this.api);
    sync = SyncService(repository: this.repository);
  }

  final SecureStorageService storage;
  final Future<bool> Function()? connectivity;
  final bool subscribe;
  late final ApiService api;
  late final ExpenseRepository repository;
  late final SyncService sync;
  final draft = ExpenseDraft();
  User? user;
  String? _accessToken;
  String? _draftOwner;
  bool ready = false;
  bool online = true;
  bool _disposed = false;
  int _session = 0;
  String? sessionMessage;
  String? syncMessage;
  DateTime? lastSync;
  AppApiException? lastFailure;
  Map<String, String> loginErrors = {};
  List<Expense> cachedExpenses = [];
  OperationState<User> loginState = const IdleState();
  OperationState<List<Expense>> expensesState = const IdleState();
  OperationState<Expense> creationState = const IdleState();
  OperationState<String> healthState = const IdleState();

  bool get authenticated => user != null && _accessToken != null;
  bool get forbidden => lastFailure is ForbiddenFailure;
  bool get syncing => expensesState is LoadingState<List<Expense>>;
  bool get cacheStale {
    final stamp = lastSync;
    if (stamp == null) return true;
    return DateTime.now().toUtc().difference(stamp.toUtc()) > localCacheTtl;
  }

  void _publish() {
    if (!_disposed) notifyListeners();
  }

  Future<bool> _isOnline() async {
    if (connectivity != null) return connectivity!();
    final values = await Connectivity().checkConnectivity();
    return values.any((value) => value != ConnectivityResult.none);
  }

  Future<void> initialize() async {
    try {
      final id = await storage.getUserId();
      _accessToken = await storage.getAccessToken();
      if (id != null && _accessToken != null) {
        user = User(id: id, username: id);
        _draftOwner = id;
        await _loadLocal();
      }
      online = await _isOnline();
      _startSync();
    } catch (_) {
      sessionMessage =
          'No fue posible restaurar la sesión. Inicie sesión nuevamente.';
    } finally {
      ready = true;
      _publish();
    }
    if (authenticated && online) await refresh();
  }

  void _startSync() {
    if (!subscribe || !authenticated) return;
    sync.start(
      userId: user!.id,
      onChanged: _loadLocal,
      onConnectivityChanged: (value) async {
        online = value;
        _publish();
      },
      onError: handleFailure,
    );
  }

  Future<void> _tokenRefreshed() async {
    _accessToken = await storage.getAccessToken();
    sessionMessage = 'Sesión renovada automáticamente.';
    _publish();
  }

  Future<bool> login(String username, String password) async {
    if (loginState is LoadingState<User>) return false;
    loginErrors = {};
    loginState = const LoadingState();
    _publish();
    try {
      final session = await api.login(
        username: username.trim(),
        password: password,
      );
      await storage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        userId: session.user.id,
      );
      if (_draftOwner != null && _draftOwner != session.user.id) draft.clear();
      _draftOwner = session.user.id;
      user = session.user;
      _accessToken = session.accessToken;
      _session++;
      lastFailure = null;
      sessionMessage = null;
      loginState = DataState(session.user);
      await _loadLocal();
      _startSync();
      _publish();
      unawaited(refresh());
      return true;
    } on ValidationFailure catch (error) {
      loginErrors = error.fieldErrors;
      loginState = ErrorState(error.message);
    } on AuthenticationFailure {
      loginState = const ErrorState(
        'Usuario o contraseña incorrectos. Revise sus credenciales.',
      );
    } catch (error) {
      loginState = ErrorState(_message(error));
    }
    _publish();
    return false;
  }

  Future<void> handleFailure(Object error) async {
    if (error is AppApiException) lastFailure = error;
    if (error is AuthenticationFailure) {
      _session++;
      user = null;
      _accessToken = null;
      cachedExpenses = [];
      expensesState = const IdleState();
      sessionMessage = error.message;
      await storage.clearCredentials();
      await sync.dispose();
    }
    _publish();
  }

  void clearForbidden() {
    lastFailure = null;
    _publish();
  }

  Future<void> logout() async {
    final id = user?.id;
    _session++;
    user = null;
    _accessToken = null;
    cachedExpenses = [];
    expensesState = const IdleState();
    lastSync = null;
    draft.clear();
    _draftOwner = null;
    sessionMessage = null;
    lastFailure = null;
    _publish();
    await sync.dispose();
    await storage.clearCredentials();
    if (id != null) await repository.database.clearUserData(id);
  }

  Future<void> _loadLocal() async {
    final id = user?.id;
    if (id == null) return;
    final generation = _session;
    final values = await repository.getLocalExpenses(id);
    final stamp = await repository.getLastSync(id);
    if (generation != _session || user?.id != id) return;
    cachedExpenses = values;
    lastSync = stamp;
    expensesState = DataState(values);
    if (!online && cacheStale && values.isNotEmpty) {
      syncMessage = 'Los datos locales pueden estar desactualizados; sin conexión no se puede actualizar.';
    } else if (syncMessage != null && expensesState is! ErrorState<List<Expense>>) {
      syncMessage = null;
    }
    _publish();
  }

  Future<void> refresh() async {
    if (!authenticated || syncing) return;
    final id = user!.id;
    final generation = _session;
    expensesState = const LoadingState();
    syncMessage = null;
    _publish();
    try {
      online = await _isOnline();
      if (online) {
        await repository.refreshFromServer(id);
        final report = await sync.sync(id);
        if (report.failed > 0) {
          syncMessage =
              'Hay gastos pendientes; los datos locales se conservaron.';
        } else {
          syncMessage = null;
        }
        await repository.refreshFromServer(id);
      } else if (cacheStale && cachedExpenses.isNotEmpty) {
        syncMessage =
            'Mostrando caché vencida en modo sin conexión. Conéctese para sincronizar.';
      }
      if (generation == _session) await _loadLocal();
    } catch (error) {
      if (generation != _session) return;
      expensesState = ErrorState(_message(error));
      syncMessage = _message(error);
      await handleFailure(error);
    }
    _publish();
  }

  Future<Expense> detail(String id) async {
    if (!authenticated) throw const AuthenticationFailure();
    try {
      return await repository.getExpense(user!.id, id);
    } catch (error) {
      await handleFailure(error);
      rethrow;
    }
  }

  void editDraft(String field, String value) {
    if (creationState is LoadingState<Expense>) return;
    draft.edit(field, value);
    creationState = const IdleState();
  }

  Future<Expense?> saveDraft() async {
    if (!authenticated || creationState is LoadingState<Expense>) return null;
    final errors = draft.validate();
    if (errors.isNotEmpty) {
      draft.serverErrors = errors;
      creationState = const ErrorState('Revise los campos del gasto.');
      _publish();
      return null;
    }
    final id = user!.id;
    final generation = _session;
    creationState = const LoadingState();
    draft.serverErrors = {};
    _publish();
    try {
      if (await repository.hasLocalExpense(
        userId: id,
        amount: double.parse(draft.amount.replaceAll(',', '.').trim()),
        description: draft.description.trim(),
        date: draft.date,
      )) {
        throw const HttpFailure('Ya existe un gasto igual para hoy.');
      }
      draft.operationId ??= '${id}_${DateTime.now().microsecondsSinceEpoch}';
      online = await _isOnline();
      final expense = await repository.createExpense(
        userId: id,
        operationId: draft.operationId!,
        amount: double.parse(draft.amount.trim().replaceAll(',', '.')),
        description: draft.description.trim(),
        date: draft.date,
        categoryId: draft.categoryId,
        online: online,
        receiptPhotoPath: draft.receiptPhotoPath,
        latitude: draft.latitude,
        longitude: draft.longitude,
      );
      if (generation != _session) return null;
      creationState = DataState(expense);
      draft.clear();
      await _loadLocal();
      _publish();
      return expense;
    } on ValidationFailure catch (error) {
      if (generation != _session) return null;
      draft.serverErrors = error.fieldErrors;
      creationState = ErrorState(error.message);
    } catch (error) {
      if (generation != _session) return null;
      creationState = ErrorState(_message(error));
      if (generation == _session) await handleFailure(error);
    }
    _publish();
    return null;
  }

  Future<void> checkHealth() async {
    if (healthState is LoadingState<String>) return;
    healthState = const LoadingState();
    _publish();
    try {
      final data = await api.health();
      healthState = DataState(
        '${data['message']} - Base de datos: ${data['database']}',
      );
    } catch (error) {
      healthState = ErrorState(_message(error));
    }
    _publish();
  }

  String _message(Object error) => error is AppApiException
      ? error.message
      : 'No fue posible completar la operación. Intente nuevamente.';

  @override
  void dispose() {
    _disposed = true;
    unawaited(sync.dispose());
    draft.dispose();
    super.dispose();
  }
}
