import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/main.dart';

void main() {
  testWidgets('CashControl app renders its shell', (tester) async {
    await tester.pumpWidget(const CashControlApp());
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
