import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'core/theme/cashcontrol_theme.dart';
import 'models/expense.dart';
import 'repositories/expense_repository.dart';
import 'services/api_service.dart';
import 'services/local_database.dart';
import 'services/secure_storage_service.dart';
import 'services/sync_service.dart';
import 'widgets/app_button.dart';
import 'widgets/async_state_view.dart';
import 'widgets/expense_card.dart';

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:3000');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CashControlApp());
}

class CashControlApp extends StatelessWidget {
  const CashControlApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'CashControl',
        debugShowCheckedModeBanner: false,
        theme: CashControlThemeData.lightTheme,
        home: const HomeScreen(),
      );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _secureStorage = SecureStorageService();
  final _localDatabase = LocalDatabase();
  late final ExpenseRepository _repository;
  late final SyncService _syncService;
  late final ApiService _api;
  String? _userId;
  String _apiStatus = 'Sin comprobar';
  List<Expense> _expenses = const [];
  DateTime? _lastSync;
  bool _online = true;
  bool _loading = true;
  bool _syncing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = ApiService(baseUrl: apiBaseUrl, readToken: _secureStorage.getAccessToken);
    _repository = ExpenseRepository(database: _localDatabase, api: _api);
    _syncService = SyncService(repository: _repository);
    _initialize();
  }

  Future<void> _initialize() async {
    _userId = await _secureStorage.getUserId();
    final connectivity = await Connectivity().checkConnectivity();
    _online = connectivity.any((result) => result != ConnectivityResult.none);
    if (_userId != null) {
      await _loadLocal();
      _syncService.start(
        userId: _userId!,
        onChanged: _loadLocal,
        onConnectivityChanged: _setConnectivity,
      );
      if (_online) {
        await _synchronize();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadLocal() async {
    if (_userId == null) return;
    final expenses = await _repository.getLocalExpenses(_userId!);
    final lastSync = await _repository.getLastSync(_userId!);
    if (mounted) setState(() { _expenses = expenses; _lastSync = lastSync; });
  }

  Future<void> _synchronize() async {
    if (_userId == null || !_online) return;
    setState(() { _syncing = true; _error = null; });
    try {
      await _repository.refreshFromServer(_userId!);
      await _syncService.sync(_userId!);
      await _repository.refreshFromServer(_userId!);
      await _loadLocal();
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo sincronizar; se conservaron los datos locales.');
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    final online = result.any((item) => item != ConnectivityResult.none);
    await _setConnectivity(online);
    if (online) {
      await _synchronize();
    }
  }

  Future<void> _setConnectivity(bool online) async {
    if (mounted) setState(() => _online = online);
  }

  Future<void> checkApiConnection() async {
    try {
      final response = await http.get(Uri.parse('$apiBaseUrl/api/health'));
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() => _apiStatus = response.statusCode == 200
            ? '${data['message']} - Base de datos: ${data['database']}'
            : 'Error HTTP: ${response.statusCode}');
      }
    } catch (_) {
      if (mounted) setState(() => _apiStatus = 'No fue posible conectar con la API');
    }
  }

  Future<void> _startDemoSession() async {
    final now = DateTime.now().microsecondsSinceEpoch;
    await _secureStorage.saveSession(accessToken: 'access-$now', refreshToken: 'refresh-$now', userId: 'demo-user');
    setState(() => _userId = 'demo-user');
    await _loadLocal();
    _syncService.start(
      userId: 'demo-user',
      onChanged: _loadLocal,
      onConnectivityChanged: _setConnectivity,
    );
    await _checkConnectivity();
  }

  Future<void> _logout() async {
    final userId = _userId;
    if (userId != null) await _localDatabase.clearUserData(userId);
    await _secureStorage.clearCredentials();
    await _syncService.dispose();
    if (mounted) setState(() { _userId = null; _expenses = const []; _lastSync = null; });
  }

  Future<void> _addExpense() async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    final created = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Nuevo gasto'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto')),
        TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descripción')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
      ],
    ));
    if (created != true || _userId == null) return;
    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    await _repository.createOfflineExpense(userId: _userId!, amount: amount, description: descriptionController.text.trim(), date: DateTime.now().toUtc());
    await _loadLocal();
    if (_online) {
      await _synchronize();
    }
  }

  String _age(DateTime? timestamp) {
    if (timestamp == null) return 'Nunca sincronizado';
    final minutes = DateTime.now().toUtc().difference(timestamp).inMinutes;
    if (minutes < 1) return 'hace menos de un minuto';
    if (minutes < 60) return 'hace $minutes minutos';
    return 'hace ${minutes ~/ 60} horas';
  }

  @override
  void dispose() {
    _syncService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CashControlColors>()!;

    if (_loading) {
      return Scaffold(
        backgroundColor: colors.surface,
        body: AsyncStateView(
          loading: true,
          error: null,
          empty: false,
          content: const SizedBox.shrink(),
        ),
      );
    }
    if (_userId == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(title: const Text('CashControl')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(colors.spacingXl),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(colors.spacingXl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Acceso local',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: colors.spacingMd),
                    Text(
                      'Inicia una sesión local de demostración para explorar el flujo de gastos y sincronización.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                    ),
                    SizedBox(height: colors.spacingXl),
                    AppButton(
                      label: 'Iniciar sesión local de demostración',
                      icon: Icons.login,
                      onPressed: _startDemoSession,
                      fullWidth: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final stale = !_online || _lastSync == null;
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: const Text('CashControl'),
        actions: [
          Semantics(
            label: 'Cerrar sesión y borrar datos',
            button: true,
            child: IconButton(
              onPressed: _logout,
              tooltip: 'Cerrar sesión y borrar datos',
              icon: const Icon(Icons.logout),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _checkConnectivity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 600;
            final content = <Widget>[
              _StatusBanner(
                online: _online,
                stale: stale,
                syncing: _syncing,
                lastSync: _age(_lastSync),
                error: _error,
              ),
              SizedBox(height: colors.spacingLg),
              Text('Diagnóstico de API', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: colors.spacingSm),
              Text(
                _apiStatus,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
              SizedBox(height: colors.spacingSm),
              AppButton(
                label: 'Probar conexión con API',
                icon: Icons.wifi_find,
                onPressed: checkApiConnection,
                variant: AppButtonVariant.secondary,
              ),
              SizedBox(height: colors.spacingXl),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Text('Gastos locales', style: Theme.of(context).textTheme.titleLarge)),
                  AppButton(
                    label: 'Nuevo gasto',
                    icon: Icons.add,
                    onPressed: _addExpense,
                  ),
                ],
              ),
              SizedBox(height: colors.spacingMd),
              AsyncStateView(
                loading: false,
                error: _error,
                empty: _expenses.isEmpty,
                content: Column(
                  children: [
                    for (final expense in _expenses)
                      Padding(
                        padding: EdgeInsets.only(bottom: colors.spacingMd),
                        child: ExpenseCard(expense: expense),
                      ),
                  ],
                ),
              ),
            ];

            if (isWide) {
              return SingleChildScrollView(
                padding: EdgeInsets.all(colors.spacingXl),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(children: content),
                    ),
                    SizedBox(width: colors.spacingXl),
                    Expanded(
                      flex: 1,
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(colors.spacingLg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Resumen', style: Theme.of(context).textTheme.titleMedium),
                              SizedBox(height: colors.spacingMd),
                              Text('Última actualización: $_lastSync', style: Theme.of(context).textTheme.bodyMedium),
                              SizedBox(height: colors.spacingSm),
                              Text(
                                _online ? 'Modo: online' : 'Modo: offline',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _online ? colors.success : colors.warning,
                                ),
                              ),
                              SizedBox(height: colors.spacingSm),
                              Text(
                                '${_expenses.length} gasto(s) local(es)',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return ListView(
              padding: EdgeInsets.all(colors.spacingXl),
              children: content,
            );
          },
        ),
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.online, required this.stale, required this.syncing, required this.lastSync, this.error});
  final bool online;
  final bool stale;
  final bool syncing;
  final String lastSync;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CashControlColors>()!;
    final statusColor = online ? colors.success : colors.warning;
    final statusText = online ? (syncing ? 'Sincronizando datos...' : 'Conectado') : 'Sin conexión / Datos desactualizados';

    return Card(
      child: Padding(
        padding: EdgeInsets.all(colors.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 10, color: statusColor),
                SizedBox(width: colors.spacingSm),
                Text(statusText, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            SizedBox(height: colors.spacingSm),
            if (stale && online)
              Text('Datos locales disponibles; última sincronización pendiente.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
            Text('Última actualización: $lastSync', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary)),
            if (error != null) ...[
              SizedBox(height: colors.spacingSm),
              Text(error!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.error)),
            ],
          ],
        ),
      ),
    );
  }
}
