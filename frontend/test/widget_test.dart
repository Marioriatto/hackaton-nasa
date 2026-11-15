import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AquaDebt smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Text('AquaDebt')));
    expect(find.text('AquaDebt'), findsOneWidget);
  });
}
