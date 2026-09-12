import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/core/theme/cashcontrol_theme.dart';
import 'package:mobile/widgets/app_button.dart';
import 'package:mobile/widgets/async_state_view.dart';

void main() {
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
