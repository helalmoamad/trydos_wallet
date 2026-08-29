import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trydos_wallet/trydos_wallet.dart';
// ignore: implementation_imports
import 'package:trydos_wallet/src/services/connectivity_service.dart';

void main() {
  // TrydosWallet.init() kicks off unawaited SharedPreferences reads. Without a
  // mock store the platform channel is absent and those futures reject, which
  // used to surface as "this test failed after it had already completed" in
  // whichever test happened to be running next.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    // Keep the wallet screens off the real network.
    ConnectivityService.disabledForTesting = true;
  });

  tearDown(() {
    ConnectivityService.disabledForTesting = false;
  });

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

  testWidgets('شاشة البداية تعرض splash بلغة الإعداد', (
    WidgetTester tester,
  ) async {
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

    // The screen used to greet with 'مرحبا بك في المحفظه'; the redesign
    // replaced it with a splash overlay, so assert on what it renders now:
    // the localized "powered by" line, which also proves the configured
    // language reached the widget tree.
    expect(find.text(AppStrings.get('ar', 'powered_by')), findsOneWidget);
    expect(find.text('مدعوم من'), findsOneWidget);
  });
}
