import 'package:flutter/material.dart';

import '../core/theme/cashcontrol_theme.dart';

class AsyncStateView extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.loading,
    required this.error,
    required this.empty,
    required this.content,
    this.loadingMessage = 'Cargando datos...',
    this.errorTitle = 'No se pudo cargar la información',
    this.emptyTitle = 'No hay gastos para mostrar',
    this.emptyMessage = 'Registra tu primer gasto para comenzar a controlar tus finanzas.',
  });

  final bool loading;
  final Object? error;
  final bool empty;
  final Widget content;
  final String loadingMessage;
  final String errorTitle;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<CashControlColors>()!;

    if (loading) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(colors.spacingXl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                ),
              ),
              SizedBox(height: colors.spacingMd),
              Text(
                loadingMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return Semantics(
        label: 'Error al cargar los datos',
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: colors.spacingLg, vertical: colors.spacingXl),
          child: Card(
            color: colors.background,
            child: Padding(
              padding: EdgeInsets.all(colors.spacingXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.error_outline_rounded, color: colors.error),
                      SizedBox(width: colors.spacingSm),
                      Expanded(
                        child: Text(
                          errorTitle,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: colors.error),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: colors.spacingSm),
                  Text(
                    error.toString(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (empty) {
      return Semantics(
        label: emptyTitle,
        child: Padding(
          padding: EdgeInsets.all(colors.spacingXl),
          child: Card(
            color: colors.background,
            child: Padding(
              padding: EdgeInsets.all(colors.spacingXl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: colors.info, size: 28),
                  SizedBox(height: colors.spacingSm),
                  Text(
                    emptyTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: colors.spacingSm),
                  Text(
                    emptyMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return content;
  }
}
