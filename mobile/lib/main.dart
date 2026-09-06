import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'models/expense.dart';
import 'repositories/expense_repository.dart';
import 'services/api_service.dart';
import 'services/local_database.dart';
import 'services/secure_storage_service.dart';
import 'services/sync_service.dart';

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
        theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
        home: const HomeScreen(),
      );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  var _counter = 0;

  @override
  Widget build(BuildContext context) => MaterialApp(
        home: Scaffold(
          body: Center(child: Text('$_counter')),
          floatingActionButton: FloatingActionButton(
            onPressed: () => setState(() => _counter++),
            child: const Icon(Icons.add),
          ),
        ),
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
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_userId == null) {
      return Scaffold(appBar: AppBar(title: const Text('CashControl')), body: Center(child: FilledButton.icon(
        onPressed: _startDemoSession, icon: const Icon(Icons.login), label: const Text('Iniciar sesión local de demostración'),
      )));
    }
    final stale = !_online || _lastSync == null;
    return Scaffold(
      appBar: AppBar(title: const Text('CashControl'), actions: [IconButton(onPressed: _logout, tooltip: 'Cerrar sesión y borrar datos', icon: const Icon(Icons.logout))]),
      body: RefreshIndicator(
        onRefresh: _checkConnectivity,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _StatusBanner(online: _online, stale: stale, syncing: _syncing, lastSync: _age(_lastSync), error: _error),
          const SizedBox(height: 16),
          const Text('Diagnóstico de API', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(_apiStatus),
          TextButton.icon(onPressed: checkApiConnection, icon: const Icon(Icons.wifi_find), label: const Text('Probar conexión con API')),
          const Divider(),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Gastos locales', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            FilledButton.icon(onPressed: _addExpense, icon: const Icon(Icons.add), label: const Text('Nuevo gasto')),
          ]),
          if (_expenses.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('No hay gastos guardados localmente.')),
          ..._expenses.map((expense) => ListTile(
            leading: Icon(expense.isPending ? Icons.cloud_upload : Icons.cloud_done),
            title: Text('${expense.amount.toStringAsFixed(2)} - ${expense.description}'),
            subtitle: Text(expense.isPending ? 'Pendiente de sincronización' : 'Sincronizado'),
          )),
        ]),
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
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(online ? (syncing ? 'Sincronizando datos...' : 'Conectado') : 'Sin conexión / Datos desactualizados', style: const TextStyle(fontWeight: FontWeight.bold)),
    if (stale && online) const Text('Datos locales disponibles; última sincronización pendiente.'),
    Text('Última actualización: $lastSync'),
    if (error != null) Text(error!, style: const TextStyle(color: Colors.red)),
  ])));
}
