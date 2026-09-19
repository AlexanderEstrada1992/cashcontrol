import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'core/theme/cashcontrol_theme.dart';
import 'models/expense.dart';
import 'repositories/expense_repository.dart';
import 'services/api_service.dart';
import 'services/api_client.dart';
import 'services/api_errors.dart';
import 'services/camera_capture_service.dart';
import 'services/local_database.dart';
import 'services/location_capture_service.dart';
import 'services/secure_storage_service.dart';
import 'services/sync_service.dart';
import 'widgets/app_button.dart';
import 'widgets/app_text_field.dart';
import 'widgets/async_state_view.dart';
import 'widgets/expense_card.dart';

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://127.0.0.1:3000');

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
  final _cameraService = CameraCaptureService();
  final _locationService = LocationCaptureService();
  late final ExpenseRepository _repository;
  late final SyncService _syncService;
  late final ApiService _api;
  late final ApiClient _apiClient;
  String? _userId;
  String _apiStatus = 'Sin comprobar';
  List<Expense> _expenses = const [];
  DateTime? _lastSync;
  bool _online = true;
  bool _loading = true;
  bool _syncing = false;
  bool _checkingApi = false;
  String? _authStatus;
  bool _loggingIn = false;
  final _usernameController = TextEditingController(text: 'demo-user');
  final _passwordController = TextEditingController(text: 'demo-password');
  Map<String, String> _loginFieldErrors = const {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(
      baseUrl: apiBaseUrl,
      storage: _secureStorage,
      onTokenRefreshed: () {
        if (mounted) setState(() => _authStatus = 'Sesión renovada automáticamente.');
      },
    );
    _api = ApiService(client: _apiClient);
    _repository = ExpenseRepository(database: _localDatabase, api: _api);
    _syncService = SyncService(repository: _repository);
    _initialize();
  }

  Future<void> _initialize() async {
    _userId = await _secureStorage.getUserId();
    if (_userId != null && await _secureStorage.getAccessToken() == null) {
      _userId = null;
    }
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
    } catch (error) {
      if (mounted) {
        setState(() => _error = error is AppApiException
            ? error.message
            : 'No se pudo sincronizar; se conservaron los datos locales.');
      }
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
    if (_checkingApi) return;
    setState(() {
      _checkingApi = true;
      _apiStatus = 'Comprobando conexión...';
    });
    try {
      final data = await _api.health();
      if (mounted) {
        setState(() => _apiStatus = '${data['message']} - Base de datos: ${data['database']}');
      }
    } catch (_) {
      if (mounted) setState(() => _apiStatus = 'No fue posible conectar con la API');
    } finally {
      if (mounted) setState(() => _checkingApi = false);
    }
  }

  Future<void> _login() async {
    if (_loggingIn) return;
    setState(() {
      _loggingIn = true;
      _loginFieldErrors = const {};
    });
    try {
      final session = await _api.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      await _secureStorage.saveSession(
        accessToken: session.accessToken,
        refreshToken: session.refreshToken,
        userId: session.user.id,
      );
      if (mounted) setState(() => _userId = session.user.id);
    } on ValidationFailure catch (error) {
      if (mounted) setState(() => _loginFieldErrors = error.fieldErrors);
      return;
    } on AuthenticationFailure catch (error) {
      if (mounted) setState(() => _loginFieldErrors = {'form': error.message});
      return;
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error is AppApiException ? error.message : 'No fue posible iniciar sesión con el servidor.'),
        ));
      }
      return;
    } finally {
      if (mounted) setState(() => _loggingIn = false);
    }
    await _loadLocal();
    _syncService.start(
      userId: _userId!,
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

  Future<bool> _confirmRationale(String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permiso necesario'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Ahora no')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Continuar')),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _addExpense() async {
    final amountController = TextEditingController();
    final descriptionController = TextEditingController();
    String? photoPath;
    double? latitude;
    double? longitude;
    String? captureStatus;
    VoidCallback? settingsAction;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo gasto'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monto')),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Descripción')),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text(photoPath == null ? 'Adjuntar foto del recibo (opcional)' : 'Foto del recibo adjuntada'),
                  onPressed: () async {
                    final accepted = await _confirmRationale(
                      'CashControl utilizará la cámara únicamente para fotografiar el recibo de este gasto.',
                    );
                    if (!accepted) return;
                    final result = await _cameraService.captureReceiptPhoto();
                    setDialogState(() {
                      settingsAction = null;
                      switch (result.state) {
                        case CameraPermissionState.granted:
                          photoPath = result.filePath;
                          captureStatus = result.filePath == null ? 'Captura de foto cancelada.' : 'Foto del recibo adjuntada.';
                          break;
                        case CameraPermissionState.denied:
                          captureStatus = 'Permiso de cámara denegado. Puedes intentarlo nuevamente.';
                          break;
                        case CameraPermissionState.permanentlyDenied:
                          captureStatus = 'Permiso de cámara bloqueado permanentemente. Actívalo desde los ajustes del sistema.';
                          settingsAction = () => _cameraService.openSettings();
                          break;
                        case CameraPermissionState.restricted:
                          captureStatus = 'La cámara está restringida en este dispositivo.';
                          break;
                      }
                    });
                  },
                ),
                if (photoPath != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(File(photoPath!), height: 120, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(latitude == null ? 'Adjuntar ubicación (opcional)' : 'Ubicación adjuntada (${latitude!.toStringAsFixed(4)}, ${longitude!.toStringAsFixed(4)})'),
                  onPressed: () async {
                    final accepted = await _confirmRationale(
                      'CashControl utilizará tu ubicación únicamente para registrar el lugar de este gasto.',
                    );
                    if (!accepted) return;
                    final result = await _locationService.captureCurrentLocation();
                    setDialogState(() {
                      settingsAction = null;
                      switch (result.state) {
                        case LocationAvailability.granted:
                          latitude = result.latitude;
                          longitude = result.longitude;
                          captureStatus = 'Ubicación adjuntada.';
                          break;
                        case LocationAvailability.denied:
                          captureStatus = 'Permiso de ubicación denegado. Puedes intentarlo nuevamente.';
                          break;
                        case LocationAvailability.permanentlyDenied:
                          captureStatus = 'Permiso de ubicación bloqueado permanentemente. Actívalo desde los ajustes del sistema.';
                          settingsAction = () => _locationService.openAppSettings();
                          break;
                        case LocationAvailability.restricted:
                          captureStatus = 'La ubicación está restringida en este dispositivo.';
                          break;
                        case LocationAvailability.serviceDisabled:
                          captureStatus = 'El GPS del dispositivo está desactivado.';
                          settingsAction = () => _locationService.openLocationSettings();
                          break;
                      }
                    });
                  },
                ),
                if (captureStatus != null) ...[
                  const SizedBox(height: 8),
                  Text(captureStatus!),
                ],
                if (settingsAction != null)
                  TextButton(onPressed: settingsAction, child: const Text('Abrir ajustes')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Guardar')),
          ],
        ),
      ),
    );
    if (created != true || _userId == null) return;
    final amount = double.tryParse(amountController.text.replaceAll(',', '.'));
    final description = descriptionController.text.trim();
    if (amount == null || amount <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El monto debe ser mayor que 0.')));
      return;
    }
    if (description.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La descripción es obligatoria.')));
      return;
    }
    final date = DateTime.now().toUtc();
    if (await _repository.hasLocalExpense(userId: _userId!, amount: amount, description: description, date: date)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe un gasto igual para hoy.')),
        );
      }
      return;
    }
    await _repository.createOfflineExpense(
      userId: _userId!,
      amount: amount,
      description: description,
      date: date,
      receiptPhotoPath: photoPath,
      latitude: latitude,
      longitude: longitude,
    );
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
    _usernameController.dispose();
    _passwordController.dispose();
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
                      'Iniciar sesión',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: colors.spacingMd),
                    Text(
                      'Accede al backend de CashControl para consultar tus gastos y sincronizarlos.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                    ),
                    SizedBox(height: colors.spacingLg),
                    AppTextField(
                      controller: _usernameController,
                      label: 'Usuario',
                      prefixIcon: Icons.person_outline,
                      errorText: _loginFieldErrors['username'],
                    ),
                    SizedBox(height: colors.spacingMd),
                    AppTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      prefixIcon: Icons.lock_outline,
                      obscureText: true,
                      errorText: _loginFieldErrors['password'],
                    ),
                    if (_loginFieldErrors['form'] != null) ...[
                      SizedBox(height: colors.spacingSm),
                      Text(_loginFieldErrors['form']!, style: TextStyle(color: colors.error)),
                    ],
                    SizedBox(height: colors.spacingXl),
                    AppButton(
                      label: 'Iniciar sesión',
                      icon: Icons.login,
                      loading: _loggingIn,
                      onPressed: _loggingIn ? null : _login,
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
                authStatus: _authStatus,
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
                loading: _checkingApi,
                onPressed: _checkingApi ? null : checkApiConnection,
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
  const _StatusBanner({required this.online, required this.stale, required this.syncing, required this.lastSync, this.error, this.authStatus});
  final bool online;
  final bool stale;
  final bool syncing;
  final String lastSync;
  final String? error;
  final String? authStatus;

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
            if (authStatus != null) ...[
              SizedBox(height: colors.spacingSm),
              Text(authStatus!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.success)),
            ],
          ],
        ),
      ),
    );
  }
}
