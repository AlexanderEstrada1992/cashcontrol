import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/cashcontrol_theme.dart';
import '../models/expense.dart';
import '../models/user.dart';
import '../services/api_errors.dart';
import '../services/camera_capture_service.dart';
import '../services/location_capture_service.dart';
import '../state/app_controller.dart';
import '../state/expense_draft.dart';
import '../state/operation_state.dart';
import '../widgets/app_button.dart';
import '../widgets/app_text_field.dart';
import '../widgets/async_state_view.dart';
import '../widgets/expense_card.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _username = TextEditingController(text: 'demo-user');
  final _password = TextEditingController();
  String? _validateUsername(String? value) =>
      RegExp(r'^[a-zA-Z0-9._-]{3,100}$').hasMatch(value?.trim() ?? '')
      ? null
      : 'Usuario: use entre 3 y 100 letras, números, puntos o guiones.';
  String? _validatePassword(String? value) =>
      value == null || value.isEmpty || value.length > 128
      ? 'Contraseña: ingrese entre 1 y 128 caracteres.'
      : null;
  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final state = widget.controller.loginState;
      final busy = state is LoadingState<User>;
      final colors = Theme.of(context).extension<CashControlColors>()!;
      return Scaffold(
        appBar: AppBar(title: const Text('CashControl')),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(colors.spacingXl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Iniciar sesión',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: colors.spacingLg),
                    if (widget.controller.sessionMessage != null)
                      Text(widget.controller.sessionMessage!),
                    Focus(
                      onFocusChange: (focused) {
                        if (!focused) _form.currentState?.validate();
                      },
                      child: AppTextField(
                        controller: _username,
                        enabled: !busy,
                        label: 'Usuario',
                        prefixIcon: Icons.person_outline,
                        validator: _validateUsername,
                        errorText: widget.controller.loginErrors['username'],
                      ),
                    ),
                    SizedBox(height: colors.spacingMd),
                    Focus(
                      onFocusChange: (focused) {
                        if (!focused) _form.currentState?.validate();
                      },
                      child: AppTextField(
                        controller: _password,
                        enabled: !busy,
                        label: 'Contraseña',
                        obscureText: true,
                        prefixIcon: Icons.lock_outline,
                        validator: _validatePassword,
                        errorText: widget.controller.loginErrors['password'],
                      ),
                    ),
                    if (state is ErrorState<User>) ...[
                      SizedBox(height: colors.spacingMd),
                      Text(
                        state.message,
                        style: TextStyle(color: colors.error),
                      ),
                    ],
                    SizedBox(height: colors.spacingLg),
                    AppButton(
                      label: 'Iniciar sesión',
                      icon: Icons.login,
                      fullWidth: true,
                      loading: busy,
                      onPressed: busy
                          ? null
                          : () async {
                              if (_form.currentState!.validate()) {
                                await widget.controller.login(
                                  _username.text,
                                  _password.text,
                                );
                              }
                            },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key, required this.controller});
  final AppController controller;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final colors = Theme.of(context).extension<CashControlColors>()!;
      final state = controller.expensesState;
      final values = controller.cachedExpenses;
      final health = switch (controller.healthState) {
        IdleState<String>() => 'Sin comprobar',
        LoadingState<String>() => 'Comprobando conexión...',
        DataState<String>(:final data) => data,
        ErrorState<String>(:final message) => message,
      };
      return Scaffold(
        appBar: AppBar(
          title: const Text('CashControl'),
          actions: [
            IconButton(
              tooltip: 'Cerrar sesión y borrar datos locales',
              icon: const Icon(Icons.logout),
              onPressed: controller.logout,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: controller.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(colors.spacingXl),
            children: [
              Text(
                controller.online ? 'Conectado' : 'Sin conexión',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                controller.lastSync == null
                    ? 'Nunca sincronizado'
                    : 'Última actualización: ${controller.lastSync!.toLocal()}',
              ),
              if (controller.syncing)
                const LinearProgressIndicator(
                  semanticsLabel: 'Sincronizando gastos',
                ),
              if (controller.sessionMessage != null)
                Text(controller.sessionMessage!),
              if (controller.syncMessage != null)
                Text(
                  controller.syncMessage!,
                  style: TextStyle(color: colors.error),
                ),
              SizedBox(height: colors.spacingLg),
              Text(
                'Diagnóstico de API',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(health),
              AppButton(
                label: 'Probar conexión con API',
                icon: Icons.wifi_find,
                variant: AppButtonVariant.secondary,
                loading: controller.healthState is LoadingState<String>,
                onPressed: controller.checkHealth,
              ),
              SizedBox(height: colors.spacingXl),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: colors.spacingMd,
                runSpacing: colors.spacingMd,
                children: [
                  Text(
                    'Gastos locales',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  AppButton(
                    label: 'Nuevo gasto',
                    icon: Icons.add,
                    onPressed: () => context.push('/gastos/nuevo'),
                  ),
                ],
              ),
              SizedBox(height: colors.spacingMd),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: AsyncStateView(
                    loading:
                        values.isEmpty && state is LoadingState<List<Expense>>,
                    error: values.isEmpty && state is ErrorState<List<Expense>>
                        ? state.message
                        : null,
                    empty: values.isEmpty,
                    content: Column(
                      children: [
                        for (final expense in values)
                          Padding(
                            padding: EdgeInsets.only(bottom: colors.spacingMd),
                            child: ExpenseCard(
                              expense: expense,
                              onTap: () => context.push(
                                '/gastos/${Uri.encodeComponent(expense.serverId?.toString() ?? expense.localId)}',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ExpenseDetailScreen extends StatefulWidget {
  const ExpenseDetailScreen({
    super.key,
    required this.controller,
    required this.id,
  });
  final AppController controller;
  final String id;
  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  OperationState<Expense> _state = const LoadingState();
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ExpenseDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      _load();
    }
  }

  Future<void> _load() async {
    final request = ++_request;
    setState(() => _state = const LoadingState());
    try {
      final expense = await widget.controller.detail(widget.id);
      if (mounted && request == _request) {
        setState(() => _state = DataState(expense));
      }
    } catch (error) {
      if (mounted && request == _request) {
        setState(
          () => _state = ErrorState(
            error is AppApiException
                ? error.message
                : 'No fue posible cargar el gasto. Intente nuevamente.',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final colors = Theme.of(context).extension<CashControlColors>()!;
    final expense = state is DataState<Expense> ? state.data : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del gasto'),
        leading: IconButton(
          tooltip: 'Volver a gastos',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/gastos'),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(colors.spacingXl),
        children: [
          AsyncStateView(
            loading: state is LoadingState<Expense>,
            error: state is ErrorState<Expense> ? state.message : null,
            empty: false,
            content: expense == null
                ? const SizedBox.shrink()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExpenseCard(expense: expense),
                      Text('Fecha: ${expense.date.toLocal()}'),
                      Text('Categoría: ${expense.categoryId}'),
                      if (expense.hasLocation)
                        Text(
                          'Ubicación: ${expense.latitude}, ${expense.longitude}',
                        ),
                      if (expense.receiptPhotoPath != null)
                        Image.file(
                          File(expense.receiptPhotoPath!),
                          height: 200,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stack) =>
                              const Text('La foto local no está disponible.'),
                        ),
                    ],
                  ),
          ),
          if (state is ErrorState<Expense>)
            AppButton(
              label: 'Reintentar',
              icon: Icons.refresh,
              onPressed: _load,
            ),
        ],
      ),
    );
  }
}

class NewExpenseScreen extends StatefulWidget {
  const NewExpenseScreen({super.key, required this.controller});
  final AppController controller;
  @override
  State<NewExpenseScreen> createState() => _NewExpenseScreenState();
}

class _NewExpenseScreenState extends State<NewExpenseScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  final _camera = CameraCaptureService();
  final _location = LocationCaptureService();
  bool _capturing = false;
  String? _captureMessage;
  VoidCallback? _settings;
  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.controller.draft.amount);
    _description = TextEditingController(
      text: widget.controller.draft.description,
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<bool> _explain(String purpose) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Permiso necesario'),
          content: Text(purpose),
          actions: [
            AppButton(
              label: 'Ahora no',
              variant: AppButtonVariant.secondary,
              onPressed: () => Navigator.pop(context, false),
            ),
            AppButton(
              label: 'Continuar',
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> _capture(bool camera) async {
    if (_capturing) return;
    setState(() {
      _capturing = true;
      _settings = null;
    });
    try {
      final accepted = await _explain(
        camera
            ? 'CashControl utilizará la cámara únicamente para fotografiar el recibo de este gasto.'
            : 'CashControl utilizará tu ubicación únicamente para registrar el lugar de este gasto.',
      );
      if (!accepted || !mounted) return;
      if (camera) {
        final result = await _camera.captureReceiptPhoto();
        if (!mounted) return;
        switch (result.state) {
          case CameraPermissionState.granted:
            if (result.filePath != null) {
              widget.controller.draft.receiptPhotoPath = result.filePath;
            }
            _captureMessage = result.filePath == null
                ? 'Captura cancelada.'
                : 'Foto adjuntada.';
          case CameraPermissionState.denied:
            _captureMessage = 'Permiso de cámara denegado. Puedes guardar sin foto o reintentar.';
          case CameraPermissionState.permanentlyDenied:
            _captureMessage =
                'Permiso de cámara bloqueado. Actívalo desde ajustes.';
            _settings = () => _camera.openSettings();
          case CameraPermissionState.restricted:
            _captureMessage =
                'La cámara está restringida. Puedes guardar sin foto.';
        }
      } else {
        final result = await _location.captureCurrentLocation();
        if (!mounted) return;
        switch (result.state) {
          case LocationAvailability.granted:
            widget.controller.draft.latitude = result.latitude;
            widget.controller.draft.longitude = result.longitude;
            _captureMessage = 'Ubicación adjuntada.';
          case LocationAvailability.denied:
            _captureMessage = 'Permiso de ubicación denegado. Puedes guardar sin ubicación o reintentar.';
          case LocationAvailability.permanentlyDenied:
            _captureMessage =
                'Permiso de ubicación bloqueado. Actívalo desde ajustes.';
            _settings = () => _location.openAppSettings();
          case LocationAvailability.restricted:
            _captureMessage =
                'La ubicación está restringida. Puedes guardar sin ella.';
          case LocationAvailability.serviceDisabled:
            _captureMessage =
                'El GPS está desactivado. Puedes guardar sin ubicación.';
            _settings = () => _location.openLocationSettings();
        }
      }
    } catch (_) {
      if (mounted) _captureMessage = 'No fue posible capturar el adjunto. Puedes guardar sin él o reintentar.';
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final draft = widget.controller.draft;
      final state = widget.controller.creationState;
      final busy = state is LoadingState<Expense>;
      final colors = Theme.of(context).extension<CashControlColors>()!;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nuevo gasto'),
          leading: IconButton(
            tooltip: 'Volver y conservar borrador',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/gastos'),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(colors.spacingXl),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Focus(
                      onFocusChange: (focused) {
                        if (!focused) _form.currentState?.validate();
                      },
                      child: AppTextField(
                        controller: _amount,
                        enabled: !busy,
                        label: 'Monto',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: ExpenseDraft.validateAmount,
                        errorText: draft.serverErrors['amount'],
                        onChanged: (value) => setState(
                          () => widget.controller.editDraft('amount', value),
                        ),
                      ),
                    ),
                    SizedBox(height: colors.spacingMd),
                    Focus(
                      onFocusChange: (focused) {
                        if (!focused) _form.currentState?.validate();
                      },
                      child: AppTextField(
                        controller: _description,
                        enabled: !busy,
                        label: 'Descripción',
                        validator: ExpenseDraft.validateDescription,
                        errorText: draft.serverErrors['description'],
                        onChanged: (value) => setState(
                          () =>
                              widget.controller.editDraft('description', value),
                        ),
                      ),
                    ),
                    SizedBox(height: colors.spacingLg),
                    AppButton(
                      label: draft.receiptPhotoPath == null
                          ? 'Adjuntar foto del recibo'
                          : 'Foto adjuntada',
                      icon: Icons.camera_alt_outlined,
                      variant: AppButtonVariant.secondary,
                      enabled: !_capturing && !busy,
                      onPressed: () => _capture(true),
                    ),
                    if (draft.receiptPhotoPath != null)
                      Image.file(
                        File(draft.receiptPhotoPath!),
                        height: 140,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stack) =>
                            const Text('La foto local no está disponible.'),
                      ),
                    SizedBox(height: colors.spacingMd),
                    AppButton(
                      label: draft.latitude == null
                          ? 'Adjuntar ubicación'
                          : 'Ubicación: ${draft.latitude!.toStringAsFixed(4)}, ${draft.longitude!.toStringAsFixed(4)}',
                      icon: Icons.location_on_outlined,
                      variant: AppButtonVariant.secondary,
                      enabled: !_capturing && !busy,
                      onPressed: () => _capture(false),
                    ),
                    if (_capturing)
                      const LinearProgressIndicator(
                        semanticsLabel: 'Capturando adjunto',
                      ),
                    if (_captureMessage != null) Text(_captureMessage!),
                    if (_settings != null)
                      AppButton(
                        label: 'Abrir ajustes',
                        variant: AppButtonVariant.secondary,
                        onPressed: _settings,
                      ),
                    if (state is ErrorState<Expense>)
                      Text(
                        state.message,
                        style: TextStyle(color: colors.error),
                      ),
                    for (final error in draft.serverErrors.entries.where(
                      (entry) => !['amount', 'description'].contains(entry.key),
                    ))
                      Text(
                        '${error.key}: ${error.value}',
                        style: TextStyle(color: colors.error),
                      ),
                    SizedBox(height: colors.spacingLg),
                    AppButton(
                      label: 'Guardar gasto',
                      icon: Icons.save_outlined,
                      loading: busy,
                      enabled: !_capturing,
                      onPressed: () async {
                        if (!_form.currentState!.validate()) return;
                        final saved = await widget.controller.saveDraft();
                        if (context.mounted && saved != null) {
                          context.go(
                            '/gastos/${Uri.encodeComponent(saved.serverId?.toString() ?? saved.localId)}',
                          );
                        }
                      },
                    ),
                    SizedBox(height: colors.spacingMd),
                    AppButton(
                      label: 'Ver listado y conservar borrador',
                      variant: AppButtonVariant.secondary,
                      icon: Icons.list,
                      onPressed: () => context.go('/gastos'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
