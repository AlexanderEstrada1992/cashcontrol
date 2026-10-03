import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/cashcontrol_theme.dart';
import 'navigation/route_guard.dart';
import 'screens/expense_screens.dart';
import 'state/app_controller.dart';
import 'widgets/app_button.dart';
import 'widgets/async_state_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CashControlApp());
}

class CashControlApp extends StatefulWidget {
  const CashControlApp({
    super.key,
    this.controller,
    this.initialLocation = '/gastos',
  });
  final AppController? controller;
  final String initialLocation;
  @override
  State<CashControlApp> createState() => _CashControlAppState();
}

class _CashControlAppState extends State<CashControlApp> {
  late final AppController _controller;
  late final GoRouter _router;
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? AppController();
    _router = GoRouter(
      initialLocation: widget.initialLocation,
      refreshListenable: _controller,
      redirect: (context, state) => sessionRedirect(
        location: state.uri,
        ready: _controller.ready,
        authenticated: _controller.authenticated,
        forbidden: _controller.forbidden,
      ),
      routes: [
        GoRoute(path: '/', redirect: (context, state) => '/gastos'),
        GoRoute(
          path: '/cargando',
          builder: (context, state) => const Scaffold(
            body: AsyncStateView(
              loading: true,
              error: null,
              empty: false,
              content: SizedBox.shrink(),
            ),
          ),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => LoginScreen(controller: _controller),
        ),
        GoRoute(
          path: '/sin-permiso',
          builder: (context, state) => Scaffold(
            appBar: AppBar(title: const Text('Sin permisos')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'No tiene permisos para realizar esta operación. Su sesión sigue activa.',
                  ),
                  AppButton(
                    label: 'Volver a gastos',
                    onPressed: () {
                      _controller.clearForbidden();
                      context.go('/gastos');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/gastos',
          builder: (context, state) => ExpensesScreen(controller: _controller),
          routes: [
            GoRoute(
              path: 'nuevo',
              builder: (context, state) =>
                  NewExpenseScreen(controller: _controller),
            ),
            GoRoute(
              path: ':id',
              builder: (context, state) => ExpenseDetailScreen(
                controller: _controller,
                id: state.pathParameters['id']!,
              ),
            ),
          ],
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('Página no encontrada')),
        body: Center(
          child: AppButton(
            label: 'Volver a gastos',
            onPressed: () => context.go('/gastos'),
          ),
        ),
      ),
    );
    if (!_controller.ready) unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _router.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: 'CashControl',
    debugShowCheckedModeBanner: false,
    theme: CashControlThemeData.lightTheme,
    routerConfig: _router,
  );
}
