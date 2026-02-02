import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  testWidgets('صفحة البداية تعرض نص الترحيب', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TrydosWalletWelcomeScreen(),
      ),
    );

    expect(find.text('مرحبا بك في المحفظه'), findsOneWidget);
  });
}
