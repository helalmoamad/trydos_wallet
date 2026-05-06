import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

void main() {
  TrydosWalletConfig buildConfig({
    required String baseUrl,
    required String languageCode,
    required String firstName,
    String? token,
  }) {
    return TrydosWalletConfig(
      baseUrl: baseUrl,
      token: token,
      languageCode: languageCode,
      firstName: firstName,
      lastName: 'User',
      applicationVersion: '1.0.0',
      allowBadCertificate: true,
    );
  }

  test('repeated init reconfigures existing api client', () {
    TrydosWallet.init(
      buildConfig(
        baseUrl: 'https://first.example',
        languageCode: 'en',
        firstName: 'First',
        token: 'token-1',
      ),
    );

    final initialClient = TrydosWallet.apiClient;

    TrydosWallet.init(
      buildConfig(
        baseUrl: 'https://second.example',
        languageCode: 'ar',
        firstName: 'Second',
      ),
    );

    expect(identical(TrydosWallet.apiClient, initialClient), isTrue);
    expect(
      TrydosWallet.apiClient.dio.options.baseUrl,
      'https://second.example',
    );
    expect(
      TrydosWallet.apiClient.dio.options.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('wallet bloc syncs state after repeated init', () async {
    TrydosWallet.init(
      buildConfig(
        baseUrl: 'https://first.example',
        languageCode: 'en',
        firstName: 'First',
      ),
    );

    final bloc = WalletBloc();

    TrydosWallet.init(
      buildConfig(
        baseUrl: 'https://second.example',
        languageCode: 'ar',
        firstName: 'Second',
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(bloc.state.languageCode, 'ar');
    expect(bloc.state.firstName, 'Second');

    await bloc.close();
  });

  testWidgets('صفحة البداية تعرض نص الترحيب', (WidgetTester tester) async {
    TrydosWallet.init(
      buildConfig(
        baseUrl: 'https://example.test',
        languageCode: 'ar',
        firstName: 'Tester',
      ),
    );

    await tester.pumpWidget(
      BlocProvider<WalletBloc>(
        create: (_) => WalletBloc()..add(const WalletLanguageChanged('ar')),
        child: const MaterialApp(home: TrydosWalletWelcomeScreen()),
      ),
    );

    expect(find.text('مرحبا بك في المحفظه'), findsOneWidget);
  });
}
