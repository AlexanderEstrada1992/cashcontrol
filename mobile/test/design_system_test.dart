import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/theme/cashcontrol_theme.dart';
import 'package:mobile/models/expense.dart';
import 'package:mobile/widgets/app_button.dart';
import 'package:mobile/widgets/app_text_field.dart';
import 'package:mobile/widgets/async_state_view.dart';
import 'package:mobile/widgets/expense_card.dart';

void main() {
  test('Theme text pairs meet WCAG AA normal-text contrast', () {
    final colors = CashControlThemeData.lightTheme.extension<CashControlColors>()!;
    final pairs = <String, (Color, Color)>{
      'textPrimary/surface': (colors.textPrimary, colors.surface),
      'textSecondary/surface': (colors.textSecondary, colors.surface),
      'textPrimary/background': (colors.textPrimary, colors.background),
      'textSecondary/background': (colors.textSecondary, colors.background),
      'textPrimary/muted': (colors.textPrimary, colors.muted),
      'textSecondary/muted': (colors.textSecondary, colors.muted),
      'onPrimary/primary': (colors.onPrimary, colors.primary),
      'onPrimary/primaryHover': (colors.onPrimary, colors.primaryHover),
      'onError/error': (colors.onError, colors.error),
      'onSuccess/success': (colors.onSuccess, colors.success),
      'error/background': (colors.error, colors.background),
      'success/background': (colors.success, colors.background),
      'warning/background': (colors.warning, colors.background),
      'info/background': (colors.info, colors.background),
    };
    for (final entry in pairs.entries) {
      final first = entry.value.$1.computeLuminance();
      final second = entry.value.$2.computeLuminance();
      final ratio = ((first > second ? first : second) + 0.05) / ((first < second ? first : second) + 0.05);
      expect(ratio, greaterThanOrEqualTo(4.5), reason: entry.key);
      debugPrint('${entry.key}: ${ratio.toStringAsFixed(2)}:1');
    }
  });

  test('Catalog icon contrast meets WCAG non-text minimum', () {
    final colors = CashControlThemeData.lightTheme.extension<CashControlColors>()!;
    final ratio = (colors.muted.computeLuminance() + 0.05) / (colors.primary.computeLuminance() + 0.05);
    expect(ratio, greaterThanOrEqualTo(3));
  });

  testWidgets('Loading button remains labelled, visible and disabled', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(MaterialApp(
      theme: CashControlThemeData.lightTheme,
      home: Scaffold(body: AppButton(label: 'Guardar gasto', loading: true, onPressed: () {})),
    ));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    expect(find.bySemanticsLabel('Guardar gasto'), findsWidgets);
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final colors = CashControlThemeData.lightTheme.extension<CashControlColors>()!;
    expect(button.style!.backgroundColor!.resolve({WidgetState.disabled}), colors.primary);
    } finally {
      semantics.dispose();
    }
  });

  for (final width in [320.0, 700.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('Catalog fits width $width with text scale $scale', (tester) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final timestamp = DateTime.utc(2026, 10, 2);
        final expense = Expense(localId: 'test', clientOperationId: 'test', userId: 'test', amount: 25.5,
          description: 'Transporte para la jornada', date: timestamp, createdAt: timestamp, updatedAt: timestamp,
          syncStatus: 'pending', receiptPhotoPath: 'receipt.jpg', latitude: 0, longitude: 0);
        await tester.pumpWidget(MaterialApp(
          theme: CashControlThemeData.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
          home: Scaffold(body: ListView(padding: const EdgeInsets.all(16), children: [
            AppButton(label: 'Probar conexión con API', icon: Icons.wifi_find, fullWidth: true, onPressed: () {}),
            const AppTextField(label: 'Descripción', errorText: 'Revise los datos ingresados.'),
            ExpenseCard(expense: expense),
            const AsyncStateView(loading: false, error: 'No hay conexión con el servidor.', empty: false, content: SizedBox.shrink()),
          ])),
        ));
        expect(tester.takeException(), isNull);
        expect(tester.widget<Text>(find.text('Probar conexión con API')).maxLines, isNull);
        expect(tester.getSize(find.byType(AppButton)).height, greaterThanOrEqualTo(48));
      });
    }
  }

  testWidgets('AppButton respects minimum touch target size and semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CashControlThemeData.lightTheme,
        home: Scaffold(
          body: Center(
            child: AppButton(
              label: 'Guardar',
              onPressed: () {},
            ),
          ),
        ),
      ),
    );

    final buttonRect = tester.getRect(find.byType(AppButton));
    expect(buttonRect.width, greaterThanOrEqualTo(48));
    expect(buttonRect.height, greaterThanOrEqualTo(48));

    final semantics = tester.getSemantics(find.text('Guardar'));
    expect(semantics.label, contains('Guardar'));
  });

  testWidgets('AsyncStateView renders empty state when no content is available', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: CashControlThemeData.lightTheme,
        home: Scaffold(
          body: AsyncStateView(
            loading: false,
            error: null,
            empty: true,
            content: const SizedBox.shrink(),
          ),
        ),
      ),
    );

    expect(find.text('No hay gastos para mostrar'), findsOneWidget);
  });
}
