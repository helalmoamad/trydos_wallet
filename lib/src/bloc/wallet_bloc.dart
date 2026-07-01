import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/models/models.dart';
import 'package:trydos_wallet/src/services/balances_api_service.dart';
import 'package:trydos_wallet/src/services/bank_deposits_api_service.dart';
import 'package:trydos_wallet/src/services/banks_api_service.dart';
import 'package:trydos_wallet/src/services/currencies_api_service.dart';
import 'package:trydos_wallet/src/services/qr_login_api_service.dart';
import 'package:trydos_wallet/src/services/sessions_api_service.dart';
import 'package:trydos_wallet/src/services/media_api_service.dart';
import 'package:trydos_wallet/src/services/kyc_api_service.dart';
import 'package:trydos_wallet/src/services/kyc_liveness_api_service.dart';
import 'package:trydos_wallet/src/services/kyc_compare_face_api_service.dart';
import 'package:trydos_wallet/src/services/payment_requests_api_service.dart';
import 'package:trydos_wallet/src/services/transfer_purposes_api_service.dart';
import 'package:trydos_wallet/src/services/transactions_api_service.dart';
import 'package:trydos_wallet/src/services/users_api_service.dart';
import 'package:trydos_wallet/src/services/auth_api_service.dart';
import 'package:trydos_wallet/src/services/wallet_websocket_service.dart';
//////////////////////////////////////////////////////////////////////////
import '../analytics/wallet_analytics.dart';
import '../api/api_interceptors.dart';
import '../config/trydos_wallet_config.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  WalletBloc({
    CurrenciesApiService? currenciesApi,
    BalancesApiService? balancesApi,
    TransactionsApiService? transactionsApi,
    BanksApiService? banksApi,
    BankDepositsApiService? depositApi,
    MediaApiService? mediaApi,
    KycApiService? kycApi,
    KycLivenessApiService? kycLivenessApi,
    KycCompareFaceApiService? kycCompareFaceApi,
    TransferPurposesApiService? transferPurposesApi,
    PaymentRequestsApiService? paymentRequestsApi,
    UsersApiService? usersApi,
    QrLoginApiService? qrLoginApiService,
    SessionsApiService? sessionsApi,
    AuthApiService? authApi,
    WalletWebSocketService? walletWebSocketService,
    String? initialLanguage,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? userSubtitle,
    bool? isVerified,
    bool? isPhoneVerified,
    bool? isAccountActive,
    bool? isTwoFactorEnabled,
    DateTime? memberSince,
  }) : _currenciesApi = currenciesApi ?? CurrenciesApiService(),
       _balancesApi = balancesApi ?? BalancesApiService(),
       _transactionsApi = transactionsApi ?? TransactionsApiService(),
       _banksApi = banksApi ?? BanksApiService(),
       _depositApi = depositApi ?? BankDepositsApiService(),
       _mediaApi = mediaApi ?? MediaApiService(),
       _kycApi = kycApi ?? KycApiService(),
       _kycLivenessApi = kycLivenessApi ?? KycLivenessApiService(),
       _kycCompareFaceApi = kycCompareFaceApi ?? KycCompareFaceApiService(),
       _transferPurposesApi =
           transferPurposesApi ?? TransferPurposesApiService(),
       _paymentRequestsApi = paymentRequestsApi ?? PaymentRequestsApiService(),
       _usersApi = usersApi ?? UsersApiService(),
       _qrLoginApi = qrLoginApiService ?? QrLoginApiService(),
       _sessionsApi = sessionsApi ?? SessionsApiService(),
       _authApi = authApi ?? AuthApiService(),
       _walletWebSocketService = walletWebSocketService,
       super(
         WalletState(
           languageCode: initialLanguage ?? TrydosWallet.config.languageCode,
           firstName: firstName ?? TrydosWallet.config.firstName,
           lastName: lastName ?? TrydosWallet.config.lastName,
           email: email ?? TrydosWallet.config.email,
           phoneNumber: phoneNumber ?? TrydosWallet.config.phoneNumber,
           profileImageUrl:
               profileImageUrl ?? TrydosWallet.config.profileImageUrl,
           userSubtitle: userSubtitle ?? TrydosWallet.config.userSubtitle,
           isVerified: isVerified ?? TrydosWallet.config.isVerified,
           isPhoneVerified:
               isPhoneVerified ?? TrydosWallet.config.isPhoneVerified,
           isAccountActive:
               isAccountActive ?? TrydosWallet.config.isAccountActive,
           isTwoFactorEnabled:
               isTwoFactorEnabled ?? TrydosWallet.config.isTwoFactorEnabled,
           memberSince: memberSince ?? TrydosWallet.config.memberSince,
         ),
       ) {
    on<WalletResetRequested>(_onResetRequested);
    on<WalletLogoutRequested>(_onLogoutRequested);
    on<WalletReconnectWebSocketRequested>(_onReconnectWebSocketRequested);
    on<WalletLanguageChanged>(_onLanguageChanged);
    on<WalletRefreshAllRequested>(_onRefreshAllRequested);
    on<WalletCurrenciesLoadRequested>(_onCurrenciesLoadRequested);
    on<WalletCurrenciesLoadMoreRequested>(_onCurrenciesLoadMoreRequested);
    on<WalletCurrenciesRefreshRequested>(_onCurrenciesRefreshRequested);
    on<WalletBalanceLoadRequested>(_onBalanceLoadRequested);
    on<WalletTransactionsLoadRequested>(_onTransactionsLoadRequested);
    on<WalletTransactionsLoadMoreRequested>(_onTransactionsLoadMoreRequested);
    on<WalletTransactionsRefreshRequested>(_onTransactionsRefreshRequested);
    on<WalletTransactionsAssetFilterChanged>(_onTransactionsAssetFilterChanged);
    on<WalletBanksLoadRequested>(_onBanksLoadRequested);
    on<WalletBanksLoadMoreRequested>(_onBanksLoadMoreRequested);
    on<WalletDepositSubmitted>(_onDepositSubmitted);
    on<WalletImageUploadRequested>(_onImageUploadRequested);
    on<WalletImageResetRequested>(_onImageResetRequested);
    on<WalletQrScanRequested>(_onQrScanRequested);
    on<WalletQrApproveRequested>(_onQrApproveRequested);
    on<WalletQrRejectRequested>(_onQrRejectRequested);
    on<WalletQrLoginResetRequested>(_onQrLoginResetRequested);
    on<WalletActiveSessionsRequested>(_onActiveSessionsRequested);
    on<WalletSessionDeleteRequested>(_onSessionDeleteRequested);
    on<WalletSessionApprovalRequestReceived>(_onSessionApprovalRequestReceived);
    on<WalletSessionApprovalResponded>(_onSessionApprovalResponded);
    on<WalletSessionApprovalResetRequested>(_onSessionApprovalResetRequested);
    on<WalletKycStatusRequested>(_onKycStatusRequested);
    on<WalletKycCurrentRequested>(_onKycCurrentRequested);
    on<WalletKycSessionStartRequested>(_onKycSessionStartRequested);
    on<WalletKycSessionResetRequested>(_onKycSessionResetRequested);
    on<WalletKycAnalyzeIdRequested>(_onKycAnalyzeIdRequested);
    on<WalletKycAnalyzeIdResetRequested>(_onKycAnalyzeIdResetRequested);
    on<WalletKycLivenessRequested>(_onKycLivenessRequested);
    on<WalletKycLivenessResetRequested>(_onKycLivenessResetRequested);
    on<WalletKycCompareFaceRequested>(_onKycCompareFaceRequested);
    on<WalletKycCompareFaceResetRequested>(_onKycCompareFaceResetRequested);
    on<BalanceCardIsSelected>(_onBalanceCardIsSelected);
    on<WalletDepositFeesRequested>(_onDepositFeesRequested);
    on<WalletDepositRequestsRequested>(_onDepositRequestsRequested);
    on<WalletTransferPurposesLoadRequested>(_onTransferPurposesLoadRequested);
    on<WalletPaymentRequestCreated>(_onPaymentRequestCreated);
    on<WalletRealtimeBalanceUpdated>(_onRealtimeBalanceUpdated);
    on<WalletRealtimeTransactionReceived>(_onRealtimeTransactionReceived);
    on<WalletConfigUpdated>(_onConfigUpdated);
    on<WalletUserProfileRefreshRequested>(_onUserProfileRefreshRequested);
    on<WalletUserNameUpdateRequested>(_onUserNameUpdateRequested);
    on<WalletUserNameUpdateResetRequested>(_onUserNameUpdateResetRequested);
    on<WalletLoginHistoryRequested>(_onLoginHistoryRequested);
    on<WalletLoginHistoryLoadMoreRequested>(_onLoginHistoryLoadMoreRequested);

    _configSubscription = TrydosWallet.configChanges.listen((config) {
      if (!isClosed) {
        add(WalletConfigUpdated(config));
      }
    });

    // Session-approval requests pushed by the host (e.g. Firebase notification).
    _sessionApprovalSubscription = TrydosWallet.sessionApprovalRequests.listen((
      payload,
    ) {
      if (!isClosed) {
        add(WalletSessionApprovalRequestReceived(payload));
      }
    });
    // Cold start: replay an approval that arrived before this bloc subscribed.
    final pendingApproval = TrydosWallet.consumePendingSessionApproval();
    if (pendingApproval != null) {
      add(WalletSessionApprovalRequestReceived(pendingApproval));
    }

    // We only own (and therefore dispose) the socket when we created it.
    // An injected one stays under the caller's control.
    _ownsWebSocketService = _walletWebSocketService == null;
    _walletWebSocketService ??= _createDefaultWalletWebSocketService();

    _walletWebSocketService?.connect();
    add(const WalletUserProfileRefreshRequested());
    add(const WalletKycStatusRequested());
  }

  final CurrenciesApiService _currenciesApi;
  final BalancesApiService _balancesApi;
  final TransactionsApiService _transactionsApi;
  final BanksApiService _banksApi;
  final BankDepositsApiService _depositApi;
  final MediaApiService _mediaApi;
  final KycApiService _kycApi;
  final KycLivenessApiService _kycLivenessApi;
  final KycCompareFaceApiService _kycCompareFaceApi;
  final TransferPurposesApiService _transferPurposesApi;
  final PaymentRequestsApiService _paymentRequestsApi;
  final UsersApiService _usersApi;
  final QrLoginApiService _qrLoginApi;
  final SessionsApiService _sessionsApi;
  final AuthApiService _authApi;
  WalletWebSocketService? _walletWebSocketService;
  bool _ownsWebSocketService = false;
  StreamSubscription<TrydosWalletConfig>? _configSubscription;
  StreamSubscription<Map<String, dynamic>>? _sessionApprovalSubscription;

  /// Last session approval requestId we've shown — dedupes the same request
  /// arriving via both the WebSocket and a Firebase push.
  String? _lastApprovalRequestId;

  int _currenciesPage = 0;
  int _banksPage = 0;
  int? _inFlightTransactionsPage;
  final int _pageSize = 10;

  WalletWebSocketService? _createDefaultWalletWebSocketService() {
    final token = TrydosWallet.config.token;
    if (token == null || token.trim().isEmpty) {
      return null;
    }

    return WalletWebSocketService(
      baseUrl: TrydosWallet.config.baseUrl,
      token: token,
      allowBadCertificate: TrydosWallet.config.allowBadCertificate,
      onLog: (message) {
        debugPrint('[WalletWS] $message');
      },
      onTrackedEvent: _onRealtimeSocketEvent,
    );
  }

  /// Single entry point for realtime socket events. Guards against a closed
  /// bloc and converts the payload safely (never throws) before dispatching.
  void _onRealtimeSocketEvent(String event, dynamic payload) {
    if (isClosed) return;

    final data = _asStringKeyedMap(payload);
    if (data == null) {
      // Debug-only: surfaces unexpected payload shapes without crashing or
      // flooding release logs on the realtime hot path.
      if (kDebugMode) {
        debugPrint(
          '[WalletWS] Dropped "$event": payload is not a string-keyed map '
          '(${payload.runtimeType}).',
        );
      }
      return;
    }

    if (event == 'balance:updated') {
      add(WalletRealtimeBalanceUpdated(data));
    } else if (event.startsWith('ledger:')) {
      add(WalletRealtimeTransactionReceived(event, data));
    } else if (event == 'session:approval_request') {
      add(WalletSessionApprovalRequestReceived(data));
    }
  }

  /// Safely converts a socket payload to `Map<String, dynamic>`, returning
  /// null (instead of throwing) when it isn't a map. Non-string keys are
  /// coerced via [Object.toString] rather than crashing on a cast.
  Map<String, dynamic>? _asStringKeyedMap(dynamic payload) {
    if (payload is! Map) return null;
    try {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> close() {
    _configSubscription?.cancel();
    _sessionApprovalSubscription?.cancel();
    // Only tear down the socket we created; an injected one is the caller's.
    if (_ownsWebSocketService) {
      _walletWebSocketService?.disconnect();
    }
    return super.close();
  }

  void _onReconnectWebSocketRequested(
    WalletReconnectWebSocketRequested event,
    Emitter<WalletState> emit,
  ) {
    final currentToken = TrydosWallet.config.token?.trim() ?? '';
    final service = _walletWebSocketService;

    // Recreate the socket with the latest token when we own it and the token
    // changed (e.g. refreshed during a long outage), so reconnection still
    // authenticates. Otherwise a clean disconnect/connect on the same socket
    // is enough. An injected socket is left to its caller.
    final tokenChanged =
        _ownsWebSocketService &&
        service != null &&
        service.token.trim() != currentToken;
    if (service == null || tokenChanged) {
      service?.disconnect();
      _walletWebSocketService = _createDefaultWalletWebSocketService();
      _ownsWebSocketService = true;
      _walletWebSocketService?.connect();
      return;
    }

    service.disconnect();
    service.connect();
  }

  void _onResetRequested(
    WalletResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(WalletState(languageCode: state.languageCode));
  }

  /// Logout - يهمنا فقط نجاح أو فشل الطلب.
  Future<void> _onLogoutRequested(
    WalletLogoutRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        logoutStatus: WalletStatus.loading,
        logoutErrorMessage: null,
      ),
    );

    // First unregister this device's FCM token (if any), then log out. Both
    // steps share the single `logoutStatus`. If unregister fails we stop and
    // surface the error — logout only runs once the device is unregistered.
    final fcmToken = TrydosWallet.fcmToken;
    if (fcmToken != null && fcmToken.isNotEmpty) {
      final unregister = await _authApi.unregisterDevice(fcmToken);
      if (unregister.isFailure) {
        emit(
          state.copyWith(
            logoutStatus: WalletStatus.failure,
            logoutErrorMessage: unregister.errorMessage,
          ),
        );
        return;
      }
    }

    final result = await _authApi.logout();
    if (result.isSuccess) {
      // Device is unregistered + logged out → drop the local FCM token.
      await TrydosWallet.setFcmToken(null);
      emit(state.copyWith(logoutStatus: WalletStatus.success));
    } else {
      emit(
        state.copyWith(
          logoutStatus: WalletStatus.failure,
          logoutErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  void _onLanguageChanged(
    WalletLanguageChanged event,
    Emitter<WalletState> emit,
  ) {
    if (state.languageCode == event.languageCode) {
      return;
    }

    TrydosWallet.updateLanguage(event.languageCode);
  }

  void _onConfigUpdated(WalletConfigUpdated event, Emitter<WalletState> emit) {
    final config = event.config;
    final languageChanged = state.languageCode != config.languageCode;

    emit(
      state.copyWith(
        languageCode: config.languageCode,
        firstName: config.firstName,
        lastName: config.lastName,
        email: config.email,
        displayId: config.displayId,
        phoneNumber: config.phoneNumber,
        profileImageUrl: config.profileImageUrl,
        userSubtitle: config.userSubtitle,
        isVerified: config.isVerified,
        isPhoneVerified: config.isPhoneVerified,
        isAccountActive: config.isAccountActive,
        isTwoFactorEnabled: config.isTwoFactorEnabled,
        memberSince: config.memberSince,
      ),
    );

    // Reapply the new config to the socket only when we own it; an injected
    // service is reconfigured by its caller.
    if (_ownsWebSocketService) {
      _walletWebSocketService?.disconnect();
      _walletWebSocketService = _createDefaultWalletWebSocketService();
      _walletWebSocketService?.connect();
    }

    if (languageChanged) {
      add(const WalletRefreshAllRequested());
      add(const WalletTransferPurposesLoadRequested());
    }
  }

  Future<void> _onUserProfileRefreshRequested(
    WalletUserProfileRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    final result = await _usersApi.getMyProfile();
    if (result.isFailure || result.data == null) {
      return;
    }

    final data = result.data!;
    final firstName = (data['firstName'] ?? '').toString().trim();
    final lastName = (data['lastName'] ?? '').toString().trim();
    final email = (data['email'] ?? '').toString().trim();
    final phoneNumber = (data['phoneNumber'] ?? '').toString().trim();
    final profilePictureUrl = (data['profilePictureURL'] ?? '')
        .toString()
        .trim();
    final displayId = (data['displayId'] ?? '').toString().trim();
    final userType = (data['userType'] ?? '').toString().trim();
    // NOTE: `isVerified` is intentionally NOT derived here. The dedicated
    // `GET /api/kyc/status` endpoint (_onKycStatusRequested) is the single
    // source of truth for the verified flag; omitting it from updateUserInfo
    // preserves whatever the status request set.
    final isPhoneVerified = data['isPhoneVerified'] == true;
    final isTwoFactorEnabled = data['isTwoFactorEnabled'] == true;
    final isBlocked = data['isBlocked'] == true;
    final createdAt = (data['createdAt'] ?? '').toString().trim();
    final memberSince = createdAt.isEmpty ? null : DateTime.tryParse(createdAt);

    TrydosWallet.updateUserInfo(
      firstName: firstName.isEmpty ? state.firstName : firstName,
      lastName: lastName.isEmpty ? state.lastName : lastName,
      displayId: displayId.isEmpty ? state.displayId : displayId,
      email: email.isEmpty ? null : email,
      phoneNumber: phoneNumber.isEmpty ? null : phoneNumber,
      profileImageUrl: profilePictureUrl,
      userSubtitle: userType.isEmpty ? null : userType,
      isPhoneVerified: isPhoneVerified,
      isAccountActive: !isBlocked,
      isTwoFactorEnabled: isTwoFactorEnabled,
      memberSince: memberSince,
    );
  }

  /// Update the user's display name (unverified users only). Sends the
  /// existing profile picture unchanged, then propagates the new name to every
  /// consumer via the central config update so all screens refresh.
  Future<void> _onUserNameUpdateRequested(
    WalletUserNameUpdateRequested event,
    Emitter<WalletState> emit,
  ) async {
    final firstName = event.firstName.trim();
    final lastName = event.lastName.trim();

    emit(
      state.copyWith(
        nameUpdateStatus: WalletStatus.loading,
        nameUpdateErrorMessage: null,
      ),
    );

    // Send the user's current profile picture unchanged.
    final result = await _usersApi.updateMyProfile(
      firstName: firstName,
      lastName: lastName,
      profilePictureURL: state.profileImageUrl?.trim() ?? '',
    );

    if (result.isFailure) {
      emit(
        state.copyWith(
          nameUpdateStatus: WalletStatus.failure,
          nameUpdateErrorMessage: result.errorMessage,
        ),
      );
      return;
    }

    // Source of truth: push the new name into config → emits WalletConfigUpdated
    // → updates state.firstName/lastName everywhere it is shown.
    TrydosWallet.updateUserInfo(firstName: firstName, lastName: lastName);

    emit(state.copyWith(nameUpdateStatus: WalletStatus.success));
  }

  void _onUserNameUpdateResetRequested(
    WalletUserNameUpdateResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        nameUpdateStatus: WalletStatus.initial,
        nameUpdateErrorMessage: null,
      ),
    );
  }

  static const int _loginHistoryLimit = 20;

  /// First page (replaces the list). Also sets the active status filter.
  Future<void> _onLoginHistoryRequested(
    WalletLoginHistoryRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        loginHistoryStatus: WalletStatus.loading,
        loginHistoryErrorMessage: null,
        loginHistoryFilter: event.status,
      ),
    );

    final result = await _usersApi.getLoginHistory(
      page: 0,
      limit: _loginHistoryLimit,
      status: event.status,
    );

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      emit(
        state.copyWith(
          loginHistoryStatus: WalletStatus.success,
          loginHistory: data.items,
          loginHistoryPage: data.page,
          loginHistoryHasNext: data.hasNext,
          loginHistoryLoadingMore: false,
        ),
      );
    } else {
      // Drop the previous list/pagination so a failed (re)load never shows stale
      // data from an earlier filter — only the failure message is shown.
      emit(
        state.copyWith(
          loginHistoryStatus: WalletStatus.failure,
          loginHistoryErrorMessage: result.errorMessage,
          loginHistory: const [],
          loginHistoryHasNext: false,
          loginHistoryPage: 0,
          loginHistoryLoadingMore: false,
        ),
      );
    }
  }

  /// Next page (appends). Keeps the current filter; no-op if already loading or
  /// there's no next page.
  Future<void> _onLoginHistoryLoadMoreRequested(
    WalletLoginHistoryLoadMoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.loginHistoryLoadingMore ||
        !state.loginHistoryHasNext ||
        state.loginHistoryStatus == WalletStatus.loading) {
      return;
    }

    emit(state.copyWith(loginHistoryLoadingMore: true));

    final result = await _usersApi.getLoginHistory(
      page: state.loginHistoryPage + 1,
      limit: _loginHistoryLimit,
      status: state.loginHistoryFilter,
    );

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      emit(
        state.copyWith(
          loginHistoryLoadingMore: false,
          loginHistory: [...state.loginHistory, ...data.items],
          loginHistoryPage: data.page,
          loginHistoryHasNext: data.hasNext,
        ),
      );
    } else {
      emit(state.copyWith(loginHistoryLoadingMore: false));
    }
  }

  /// Currencies
  Future<void> _onRefreshAllRequested(
    WalletRefreshAllRequested event,
    Emitter<WalletState> emit,
  ) async {
    add(const WalletKycStatusRequested());
    _currenciesPage = 0;
    _inFlightTransactionsPage = null;
    emit(
      state.copyWith(
        currenciesStatus: WalletStatus.loading,
        balancesStatus: WalletStatus.loading,
        transactionsStatus: WalletStatus.loading,
        transactions: const [],
        transactionsHasNext: false,
        transactionsNextCursor: null,
      ),
    );
    await _fetchCurrencies(emit, page: 0, append: false);
    await _fetchAllBalances(emit);
    await _fetchTransactions(emit, page: 0, append: false);
  }

  Future<void> _onCurrenciesLoadRequested(
    WalletCurrenciesLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(currenciesStatus: WalletStatus.loading));
    _currenciesPage = 0;
    await _fetchCurrencies(emit, page: 0, append: false);
  }

  Future<void> _onCurrenciesRefreshRequested(
    WalletCurrenciesRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    _currenciesPage = 0;
    await _fetchCurrencies(emit, page: 0, append: false);
  }

  Future<void> _onCurrenciesLoadMoreRequested(
    WalletCurrenciesLoadMoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.currenciesStatus == WalletStatus.loading ||
        !state.currenciesHasNext) {
      return;
    }
    await _fetchCurrencies(emit, page: _currenciesPage + 1, append: true);
  }

  Future<void> _onBalanceCardIsSelected(
    BalanceCardIsSelected event,
    Emitter<WalletState> emit,
  ) async {
    String resolvedSymbol = event.assetSymbol ?? '';
    String resolvedType = event.assetType ?? '';

    if (event.isSelected && event.assetId != null) {
      for (final currency in state.currencies) {
        if (currency.id == event.assetId) {
          if (resolvedSymbol.isEmpty) {
            resolvedSymbol = currency.symbol;
          }
          if (resolvedType.isEmpty) {
            resolvedType = currency.assetType;
          }
          break;
        }
      }
    }

    final filterSymbol = event.isSelected ? resolvedSymbol : null;

    _inFlightTransactionsPage = null;
    emit(
      state.copyWith(
        balanceCardIsSelected: event.isSelected,
        selectedAssetId: event.isSelected ? event.assetId : null,
        selectedAssetSymbol: event.isSelected ? resolvedSymbol : '',
        selectedAssetType: event.isSelected ? resolvedType : '',
        transactionsAssetSymbolFilter: filterSymbol,
        transactionsStatus: WalletStatus.loading,
        transactions: const [],
        transactionsHasNext: false,
        transactionsNextCursor: null,
      ),
    );
    await _fetchTransactions(emit, page: 0, append: false);
  }

  Future<void> _fetchCurrencies(
    Emitter<WalletState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _currenciesApi.getCurrencies(
      CurrenciesQueryParams(page: page, limit: _pageSize),
    );
    if (result.isSuccess && result.data != null) {
      _currenciesPage = page;
      emit(
        state.copyWith(
          currencies: append
              ? [...state.currencies, ...result.data!.items]
              : result.data!.items,
          currenciesStatus: WalletStatus.success,
          currenciesHasNext: result.data!.hasNext,
        ),
      );
    } else {
      emit(
        state.copyWith(
          currenciesStatus: append
              ? WalletStatus.success
              : WalletStatus.failure,
          currenciesErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  /// Balances
  Future<void> _onBalanceLoadRequested(
    WalletBalanceLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    final assetId = event.assetId.trim();
    if (assetId.isEmpty || state.loadingBalanceIds.contains(assetId)) {
      return;
    }

    final loadingIds = <String>{...state.loadingBalanceIds, assetId};
    emit(state.copyWith(loadingBalanceIds: loadingIds));

    final result = await _balancesApi.getBalances();
    if (result.isSuccess && result.data != null) {
      final mergedBalances = <String, Balance>{...state.balances};
      for (final balance in result.data!) {
        if (balance.assetId.isNotEmpty) {
          mergedBalances[balance.assetId] = balance;
        }
      }

      final updatedLoadingIds = <String>{...loadingIds}..remove(assetId);
      emit(
        state.copyWith(
          balances: mergedBalances,
          balancesStatus: WalletStatus.success,
          loadingBalanceIds: updatedLoadingIds,
        ),
      );
      return;
    }

    final updatedLoadingIds = <String>{...loadingIds}..remove(assetId);
    emit(
      state.copyWith(
        balancesStatus: WalletStatus.failure,
        loadingBalanceIds: updatedLoadingIds,
      ),
    );
  }

  Future<void> _fetchAllBalances(Emitter<WalletState> emit) async {
    emit(state.copyWith(balancesStatus: WalletStatus.loading));

    final result = await _balancesApi.getBalances();
    if (result.isSuccess && result.data != null) {
      final updatedBalances = <String, Balance>{};
      for (final balance in result.data!) {
        if (balance.assetId.isNotEmpty) {
          updatedBalances[balance.assetId] = balance;
        }
      }
      emit(
        state.copyWith(
          balances: updatedBalances,
          balancesStatus: WalletStatus.success,
          loadingBalanceIds: const {},
        ),
      );
    } else {
      emit(
        state.copyWith(
          balancesStatus: WalletStatus.failure,
          loadingBalanceIds: const {},
        ),
      );
    }
  }

  void _onRealtimeBalanceUpdated(
    WalletRealtimeBalanceUpdated event,
    Emitter<WalletState> emit,
  ) {
    final payload = event.payload;

    final rawSymbol = (payload['assetSymbol'] ?? '').toString().trim();
    if (rawSymbol.isEmpty) return;

    final rawType = (payload['assetType'] ?? 'CURRENCY')
        .toString()
        .trim()
        .toUpperCase();
    final normalizedSymbol = rawSymbol.toUpperCase();

    String assetId = '';
    for (final currency in state.currencies) {
      if (currency.symbol.toUpperCase() == normalizedSymbol &&
          currency.assetType.toUpperCase() == rawType) {
        assetId = currency.id;
        break;
      }
    }

    String existingKey = '';
    Balance? existing;
    for (final entry in state.balances.entries) {
      final balance = entry.value;
      if (balance.assetSymbol.toUpperCase() == normalizedSymbol &&
          balance.assetType.toUpperCase() == rawType) {
        existingKey = entry.key;
        existing = balance;
        break;
      }
    }

    if (assetId.isEmpty) {
      assetId = existingKey;
    }
    if (assetId.isEmpty) {
      return;
    }

    double toDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0;
    }

    final available = toDouble(payload['available']);
    final locked = toDouble(payload['locked']);
    final reserved = toDouble(payload['reserved']);
    final timestamp = (payload['timestamp'] ?? '').toString();

    final updatedBalance = Balance(
      id: existing?.id ?? '',
      accountId: existing?.accountId ?? '',
      assetType: rawType,
      assetId: assetId,
      assetSymbol: rawSymbol,
      available: available,
      locked: locked,
      reserved: reserved,
      createdAt: existing?.createdAt ?? timestamp,
      updatedAt: timestamp.isNotEmpty ? timestamp : (existing?.updatedAt ?? ''),
      asset: existing?.asset,
      accountNumber: existing?.accountNumber ?? '',
      accountName: existing?.accountName ?? '',
      accountSubtype: existing?.accountSubtype ?? 'MAIN',
    );

    final updatedBalances = <String, Balance>{...state.balances};
    if (existingKey.isNotEmpty && existingKey != assetId) {
      updatedBalances.remove(existingKey);
    }
    updatedBalances[assetId] = updatedBalance;

    emit(
      state.copyWith(
        balances: updatedBalances,
        balancesStatus: WalletStatus.success,
      ),
    );
  }

  void _onRealtimeTransactionReceived(
    WalletRealtimeTransactionReceived event,
    Emitter<WalletState> emit,
  ) {
    final transaction = _transactionFromRealtimePayload(event.payload);
    if (transaction == null) return;

    final incomingId = transaction.id.trim();
    final existingIndex = state.transactions.indexWhere(
      (tx) => tx.id.trim() == incomingId,
    );
    final eventName = event.eventName.trim().toLowerCase();

    if (eventName == 'ledger:completed' ||
        eventName == 'ledger:failed' ||
        eventName == 'ledger:cancelled') {
      if (existingIndex < 0) {
        return;
      }

      final current = state.transactions[existingIndex];
      final updated = Transaction(
        id: current.id,
        userId: current.userId,
        accountId: current.accountId,
        ledgerType: current.ledgerType,
        status: transaction.status,
        direction: current.direction,
        assetType: current.assetType,
        assetId: current.assetId,
        description: current.description,
        balanceId: current.balanceId,
        assetSymbol: current.assetSymbol,
        type: current.type,
        amount: current.amount,
        feeAmount: current.feeAmount,
        taxAmount: current.taxAmount,
        balanceBefore: current.balanceBefore,
        balanceAfter: current.balanceAfter,
        balanceField: current.balanceField,
        title: current.title,
        journalEntryId: current.journalEntryId,
        senderUserId: current.senderUserId,
        senderAccount: current.senderAccount,
        receiverUserId: current.receiverUserId,
        receiverAccount: current.receiverAccount,
        referenceId: current.referenceId,
        errorMessage: current.errorMessage,
        note: current.note,
        metadata: current.metadata,
        createdAt: current.createdAt,
        updatedAt: current.updatedAt,
      );

      final updatedList = List<Transaction>.from(state.transactions);
      updatedList[existingIndex] = updated;

      emit(
        state.copyWith(
          transactions: updatedList,
          transactionsStatus: WalletStatus.success,
        ),
      );
      return;
    }

    if (eventName != 'ledger:created') {
      return;
    }

    if (existingIndex >= 0) {
      return;
    }

    final activeFilter = state.transactionsAssetSymbolFilter?.trim();
    if (activeFilter != null &&
        activeFilter.isNotEmpty &&
        transaction.assetSymbol.toUpperCase() != activeFilter.toUpperCase()) {
      return;
    }

    emit(
      state.copyWith(
        transactions: _upsertTransactionAtTop(state.transactions, transaction),
        transactionsStatus: WalletStatus.success,
      ),
    );
  }

  Future<void> _onTransactionsAssetFilterChanged(
    WalletTransactionsAssetFilterChanged event,
    Emitter<WalletState> emit,
  ) async {
    _inFlightTransactionsPage = null;
    emit(
      state.copyWith(
        transactionsAssetSymbolFilter: event.assetSymbol,
        transactionsStatus: WalletStatus.loading,
        transactions: const [],
        transactionsHasNext: false,
        transactionsNextCursor: null,
      ),
    );
    await _fetchTransactions(emit, page: 0, append: false);
  }

  /// Transactions
  Future<void> _onTransactionsLoadRequested(
    WalletTransactionsLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    _inFlightTransactionsPage = null;
    emit(
      state.copyWith(
        transactionsStatus: WalletStatus.loading,
        transactions: const [],
        transactionsHasNext: false,
        transactionsNextCursor: null,
      ),
    );
    await _fetchTransactions(emit, page: 0, append: false);
  }

  Future<void> _onTransactionsRefreshRequested(
    WalletTransactionsRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    _inFlightTransactionsPage = null;
    emit(
      state.copyWith(
        transactionsStatus: WalletStatus.loading,
        transactions: const [],
        transactionsHasNext: false,
        transactionsNextCursor: null,
      ),
    );
    await _fetchTransactions(emit, page: 0, append: false);
  }

  Future<void> _onTransactionsLoadMoreRequested(
    WalletTransactionsLoadMoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.transactionsStatus == WalletStatus.loading ||
        !state.transactionsHasNext) {
      return;
    }

    final nextPage = int.tryParse(state.transactionsNextCursor ?? '');
    if (nextPage == null) {
      return;
    }

    if (_inFlightTransactionsPage == nextPage) {
      return;
    }

    _inFlightTransactionsPage = nextPage;
    try {
      emit(state.copyWith(transactionsStatus: WalletStatus.loading));
      await _fetchTransactions(emit, page: nextPage, append: true);
    } finally {
      _inFlightTransactionsPage = null;
    }
  }

  Future<void> _fetchTransactions(
    Emitter<WalletState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _transactionsApi.getTransactions(
      page: page,
      limit: _pageSize,
      assetSymbol: state.transactionsAssetSymbolFilter,
    );
    if (result.isSuccess && result.data != null) {
      final response = result.data!;
      if (append && response.items.isEmpty) {
        emit(
          state.copyWith(
            transactionsStatus: WalletStatus.success,
            transactionsHasNext: false,
            transactionsNextCursor: null,
          ),
        );
        return;
      }

      final responsePage = response.page ?? page;
      final computedHasNext = response.totalPages != null
          ? responsePage + 1 < response.totalPages!
          : response.hasNextPage;
      final nextPage = computedHasNext ? responsePage + 1 : null;

      final mergedTransactions = append
          ? _mergeTransactionsById(state.transactions, response.items)
          : response.items;

      emit(
        state.copyWith(
          transactions: mergedTransactions,
          transactionsStatus: WalletStatus.success,
          transactionsHasNext: computedHasNext,
          transactionsNextCursor: nextPage?.toString(),
        ),
      );
    } else {
      emit(
        state.copyWith(
          transactionsNextCursor: append ? state.transactionsNextCursor : null,
          transactionsHasNext: append ? state.transactionsHasNext : false,
          transactionsStatus: append
              ? WalletStatus.success
              : WalletStatus.failure,
          transactionsErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  List<Transaction> _mergeTransactionsById(
    List<Transaction> current,
    List<Transaction> incoming,
  ) {
    final seenIds = <String>{};
    final merged = <Transaction>[];

    for (final tx in current) {
      final key = tx.id.trim();
      if (key.isEmpty || seenIds.add(key)) {
        merged.add(tx);
      }
    }

    for (final tx in incoming) {
      final key = tx.id.trim();
      if (key.isEmpty || seenIds.add(key)) {
        merged.add(tx);
      }
    }

    return merged;
  }

  List<Transaction> _upsertTransactionAtTop(
    List<Transaction> current,
    Transaction incoming,
  ) {
    final incomingId = incoming.id.trim();
    final merged = <Transaction>[incoming];

    for (final tx in current) {
      final currentId = tx.id.trim();
      if (incomingId.isNotEmpty && currentId == incomingId) {
        continue;
      }
      merged.add(tx);
    }

    return merged;
  }

  Transaction? _transactionFromRealtimePayload(Map<String, dynamic> payload) {
    final id = (payload['id'] ?? '').toString().trim();
    if (id.isEmpty) return null;

    final normalized = <String, dynamic>{...payload};

    normalized['title'] = _localizedTextFromDynamic(payload['title']);
    normalized['description'] = _localizedTextFromDynamic(
      payload['description'],
    );

    final metadataRaw = payload['metadata'];
    if (metadataRaw is Map) {
      final metadata = Map<String, dynamic>.from(metadataRaw);
      metadata['purposeName'] = _localizedTextFromDynamic(
        metadata['purposeName'],
      );
      normalized['metadata'] = metadata;
    }

    normalized['type'] = (payload['type'] ?? payload['ledgerType'] ?? '')
        .toString();
    normalized['ledgerType'] = (payload['ledgerType'] ?? payload['type'] ?? '')
        .toString();
    normalized['accountId'] = (payload['accountId'] ?? '').toString();
    normalized['balanceId'] = (payload['balanceId'] ?? '').toString();
    normalized['balanceField'] = (payload['balanceField'] ?? '').toString();
    normalized['journalEntryId'] = (payload['journalEntryId'] ?? '').toString();
    normalized['referenceId'] = (payload['referenceId'] ?? '').toString();
    normalized['userId'] = (payload['userId'] ?? '').toString();
    normalized['assetType'] = (payload['assetType'] ?? 'CURRENCY')
        .toString()
        .toUpperCase();
    normalized['assetSymbol'] = (payload['assetSymbol'] ?? '').toString();
    normalized['note'] = (payload['note'] ?? '').toString();
    normalized['status'] = (payload['status'] ?? '').toString();
    normalized['direction'] = (payload['direction'] ?? '').toString();
    normalized['createdAt'] = (payload['createdAt'] ?? '').toString();
    normalized['updatedAt'] =
        (payload['updatedAt'] ?? payload['timestamp'] ?? '').toString();

    return Transaction.fromJson(normalized);
  }

  String? _localizedTextFromDynamic(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      final localized = Map<String, dynamic>.from(value);
      final preferred = state.languageCode.trim().toLowerCase();
      final preferredValue = localized[preferred]?.toString().trim();
      if (preferredValue != null && preferredValue.isNotEmpty) {
        return preferredValue;
      }
      for (final fallbackKey in const ['en', 'ar', 'ku']) {
        final fallbackValue = localized[fallbackKey]?.toString().trim();
        if (fallbackValue != null && fallbackValue.isNotEmpty) {
          return fallbackValue;
        }
      }
      for (final entry in localized.values) {
        final text = entry?.toString().trim();
        if (text != null && text.isNotEmpty) {
          return text;
        }
      }
      return null;
    }
    return value.toString();
  }

  /// Banks
  Future<void> _onBanksLoadRequested(
    WalletBanksLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(banksStatus: WalletStatus.loading));
    _banksPage = 0;
    await _fetchBanks(emit, page: 0, append: false);
  }

  Future<void> _onBanksMoreRequested(
    WalletBanksLoadMoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.banksStatus == WalletStatus.loading || !state.banksHasNext) {
      return;
    }
    await _fetchBanks(emit, page: _banksPage + 1, append: true);
  }

  Future<void> _fetchBanks(
    Emitter<WalletState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _banksApi.getBanks(page: page, limit: _pageSize);
    if (result.isSuccess && result.data != null) {
      _banksPage = page;
      emit(
        state.copyWith(
          banks: append
              ? [...state.banks, ...result.data!.items]
              : result.data!.items,
          banksStatus: WalletStatus.success,
          banksHasNext: result.data!.hasNext,
        ),
      );
    } else {
      emit(
        state.copyWith(
          banksStatus: append ? WalletStatus.success : WalletStatus.failure,
          banksErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  void _onBanksLoadMoreRequested(
    WalletBanksLoadMoreRequested event,
    Emitter<WalletState> emit,
  ) {
    _onBanksMoreRequested(event, emit);
  }

  /// Deposit
  Future<void> _onDepositSubmitted(
    WalletDepositSubmitted event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(depositStatus: WalletStatus.loading));
    final params = event.params;
    final result = await _depositApi.createDeposit(
      bankId: params.bankId,
      currencyId: params.currencyId,
      amount: params.amount,
      transferImageUrl: params.transferImageUrl,
      transactionReference: params.transactionReference,
      idempotencyKey: params.idempotencyKey,
    );
    if (result.isSuccess) {
      WalletAnalytics.capture(
        WalletScreens.eventDepositSubmitted,
        properties: {
          'amount': params.amount,
          'currency_id': params.currencyId,
          'bank_id': params.bankId,
        },
      );
      emit(state.copyWith(depositStatus: WalletStatus.success));
    } else {
      emit(
        state.copyWith(
          depositStatus: WalletStatus.failure,
          depositErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  /// Media
  Future<void> _onImageUploadRequested(
    WalletImageUploadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(uploadStatus: WalletStatus.loading));
    final result = await _mediaApi.uploadDirect(
      filePath: event.imageFile.path,
      type: 'image',
      metadata: {'purpose': 'deposit_proof'},
    );
    if (result.isSuccess && result.data != null) {
      emit(
        state.copyWith(
          uploadStatus: WalletStatus.success,
          uploadUrl: result.data!.url,
        ),
      );
    } else {
      emit(
        state.copyWith(
          uploadStatus: WalletStatus.failure,
          uploadErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  Future<void> _onQrScanRequested(
    WalletQrScanRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        qrScanStatus: WalletStatus.loading,
        qrScanErrorMessage: null,
        qrActionErrorMessage: null,
        qrActionSuccessMessage: null,
        qrLoginRequest: null,
        qrActionStatus: WalletStatus.initial,
      ),
    );

    final result = await _qrLoginApi.scanQrToken(event.qrToken);
    if (result.isFailure || result.data == null) {
      emit(
        state.copyWith(
          qrScanStatus: WalletStatus.failure,
          qrScanErrorMessage:
              result.errorMessage ?? 'Failed to read QR. Please try again.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        qrScanStatus: WalletStatus.success,
        qrLoginRequest: result.data,
        qrScanErrorMessage: null,
      ),
    );
  }

  Future<void> _onQrApproveRequested(
    WalletQrApproveRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        qrActionStatus: WalletStatus.loading,
        qrActionErrorMessage: null,
        qrActionSuccessMessage: null,
      ),
    );

    final result = await _qrLoginApi.approveQrLogin(event.linkId);
    if (result.isFailure) {
      emit(
        state.copyWith(
          qrActionStatus: WalletStatus.failure,
          qrActionErrorMessage:
              result.errorMessage ?? 'Approve failed. Please try again.',
        ),
      );
      return;
    }
    // Active sessions are no longer needed after approving a web sign-in.
    // Future.delayed(const Duration(seconds: 1), () {
    //   add(const WalletActiveSessionsRequested());
    // });
    // Web sign-in approved → notify host app to switch to the web session.
    emitSwitchEvent(SwitchEvent.switchEvent());
    emit(
      state.copyWith(
        qrScanStatus: WalletStatus.initial,
        qrActionStatus: WalletStatus.success,
        qrLoginRequest: null,
        qrScanErrorMessage: null,
        qrActionErrorMessage: null,
        qrActionSuccessMessage: 'Web signed in successfully',
      ),
    );
  }

  Future<void> _onQrRejectRequested(
    WalletQrRejectRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        qrActionStatus: WalletStatus.loading,
        qrActionErrorMessage: null,
        qrActionSuccessMessage: null,
      ),
    );

    final result = await _qrLoginApi.rejectQrLogin(event.linkId);
    if (result.isFailure) {
      emit(
        state.copyWith(
          qrActionStatus: WalletStatus.failure,
          qrActionErrorMessage:
              result.errorMessage ?? 'Reject failed. Please try again.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        qrScanStatus: WalletStatus.initial,
        qrActionStatus: WalletStatus.success,
        qrLoginRequest: null,
        qrScanErrorMessage: null,
        qrActionErrorMessage: null,
        qrActionSuccessMessage: 'Login declined',
      ),
    );
  }

  void _onQrLoginResetRequested(
    WalletQrLoginResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        qrScanStatus: WalletStatus.initial,
        qrActionStatus: WalletStatus.initial,
        qrLoginRequest: null,
        qrScanErrorMessage: null,
        qrActionErrorMessage: null,
        qrActionSuccessMessage: null,
      ),
    );
  }

  Future<void> _onActiveSessionsRequested(
    WalletActiveSessionsRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        activeSessionsStatus: WalletStatus.loading,
        activeSessionsErrorMessage: null,
        sessionActionErrorMessage: null,
        sessionActionSuccessMessage: null,
      ),
    );

    final result = await _sessionsApi.getActiveSessions();
    if (result.isFailure) {
      emit(
        state.copyWith(
          activeSessionsStatus: WalletStatus.failure,
          activeSessionsErrorMessage:
              result.errorMessage ?? 'Failed to load linked devices.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        activeSessionsStatus: WalletStatus.success,
        activeSessions: result.data ?? const [],
        activeSessionsErrorMessage: null,
      ),
    );
  }

  Future<void> _onSessionDeleteRequested(
    WalletSessionDeleteRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        sessionActionStatus: WalletStatus.loading,
        deleteSessionStatus: event.deleteCurrentSession == true
            ? WalletStatus.loading
            : WalletStatus.initial,
        sessionActionErrorMessage: null,
        sessionActionSuccessMessage: null,
      ),
    );

    final result = await _sessionsApi.deleteSession(event.sessionId);
    if (result.isFailure) {
      emit(
        state.copyWith(
          sessionActionStatus: WalletStatus.failure,
          deleteSessionStatus: event.deleteCurrentSession == true
              ? WalletStatus.failure
              : WalletStatus.initial,
          sessionActionErrorMessage:
              result.errorMessage ?? 'Failed to remove the linked device.',
        ),
      );
      return;
    }

    final updatedSessions = state.activeSessions
        .where((session) => session.id != event.sessionId)
        .toList();

    emit(
      state.copyWith(
        sessionActionStatus: WalletStatus.success,
        sessionActionSuccessMessage: 'Linked device removed successfully.',
        activeSessions: updatedSessions,
        deleteSessionStatus: event.deleteCurrentSession == true
            ? WalletStatus.success
            : WalletStatus.initial,
      ),
    );
  }

  /// Session approval (push): a web/session login wants this device to confirm.
  void _onSessionApprovalRequestReceived(
    WalletSessionApprovalRequestReceived event,
    Emitter<WalletState> emit,
  ) {
    final request = SessionApprovalRequest.fromJson(event.payload);
    if (request.requestId.isEmpty) return;

    // Dedupe by requestId: the SAME approval can arrive via BOTH the WebSocket
    // and a Firebase push (possibly at the same time). Show it only once —
    // `_lastApprovalRequestId` persists across the response so a late duplicate
    // can't reopen an already-handled prompt. (requestIds are unique per login.)
    if (request.requestId == _lastApprovalRequestId) return;
    _lastApprovalRequestId = request.requestId;

    emit(
      state.copyWith(
        sessionApprovalRequest: request,
        sessionApprovalStatus: WalletStatus.initial,
        sessionApprovalErrorMessage: null,
        sessionApprovalSuccessMessage: null,
      ),
    );
  }

  /// User approved/rejected the pending session approval → call the API.
  Future<void> _onSessionApprovalResponded(
    WalletSessionApprovalResponded event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        sessionApprovalStatus: WalletStatus.loading,
        sessionApprovalErrorMessage: null,
      ),
    );

    final result = await _sessionsApi.respondToApproval(
      requestId: event.requestId,
      approve: event.approve,
    );

    if (result.isSuccess) {
      // Approving a web/session login → tell the host app to switch.
      if (event.approve) {
        emitSwitchEvent(SwitchEvent.switchEvent());
      }
      emit(
        state.copyWith(
          sessionApprovalStatus: WalletStatus.success,
          sessionApprovalRequest: null,
          sessionApprovalSuccessMessage: event.approve
              ? 'Web signed in successfully'
              : 'Login declined',
        ),
      );
    } else {
      emit(
        state.copyWith(
          sessionApprovalStatus: WalletStatus.failure,
          sessionApprovalErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  void _onSessionApprovalResetRequested(
    WalletSessionApprovalResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        sessionApprovalRequest: null,
        sessionApprovalStatus: WalletStatus.initial,
        sessionApprovalErrorMessage: null,
        sessionApprovalSuccessMessage: null,
      ),
    );
  }

  /// Fees
  Future<void> _onDepositFeesRequested(
    WalletDepositFeesRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(depositFeesStatus: WalletStatus.loading));
    final result = await _depositApi.calculateFees(
      bankId: event.bankId,
      currencyId: event.currencyId,
      amount: event.amount,
    );
    if (result.isSuccess && result.data != null) {
      emit(
        state.copyWith(
          depositFees: result.data,
          depositFeesStatus: WalletStatus.success,
        ),
      );
    } else {
      emit(
        state.copyWith(
          depositFeesStatus: WalletStatus.failure,
          depositFeesErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  void _onImageResetRequested(
    WalletImageResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        uploadStatus: WalletStatus.initial,
        uploadUrl: null,
        uploadErrorMessage: null,
      ),
    );
  }

  /// Returns true when a DioException indicates a connectivity/timeout problem
  /// (i.e. the server was never reached), as opposed to a structured error
  /// response from the server itself.
  bool _isNetworkDioError(Object? error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout;
    }
    return false;
  }

  Future<void> _onKycStatusRequested(
    WalletKycStatusRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(kycStatusRequestStatus: WalletStatus.loading));

    try {
      final result = await _kycApi.getStatus();
      if (result.isFailure || result.data == null) {
        emit(state.copyWith(kycStatusRequestStatus: WalletStatus.failure));
        return;
      }

      final data = result.data!;
      emit(
        state.copyWith(
          kycStatusRequestStatus: WalletStatus.success,
          kycVerificationStatus: data.status,
          kycStatusLabel: data.statusLabel,
          kycRejectionReason: data.rejectionReason,
        ),
      );

      // The status endpoint is the backend source of truth for the verified
      // badge — keep the global verified flag in sync.
      if (data.isVerified != state.isVerified) {
        TrydosWallet.updateUserInfo(isVerified: data.isVerified);
      }
    } catch (_) {
      emit(state.copyWith(kycStatusRequestStatus: WalletStatus.failure));
    }
  }

  Future<void> _onKycCurrentRequested(
    WalletKycCurrentRequested event,
    Emitter<WalletState> emit,
  ) async {
    // Only meaningful for verified users (the caller already gates on this,
    // but guard here too to avoid a needless authed call).
    if (!state.isVerified) {
      return;
    }

    emit(state.copyWith(kycCurrentStatus: WalletStatus.loading));

    try {
      final result = await _kycApi.getCurrent();
      if (result.isFailure || result.data == null) {
        emit(state.copyWith(kycCurrentStatus: WalletStatus.failure));
        return;
      }

      emit(
        state.copyWith(
          kycCurrentStatus: WalletStatus.success,
          kycCurrentRecord: result.data,
        ),
      );
    } catch (_) {
      emit(state.copyWith(kycCurrentStatus: WalletStatus.failure));
    }
  }

  Future<void> _onKycSessionStartRequested(
    WalletKycSessionStartRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        kycSessionStatus: WalletStatus.loading,
        kycSessionErrorMessage: null,
      ),
    );

    try {
      final result = await _kycApi.startSession();

      if (result.isFailure ||
          result.data == null ||
          result.data!.sessionId.isEmpty) {
        emit(
          state.copyWith(
            kycSessionStatus: WalletStatus.failure,
            kycSessionErrorMessage:
                result.errorMessage ?? 'Failed to start KYC session',
          ),
        );
        return;
      }

      final data = result.data!;
      emit(
        state.copyWith(
          kycSessionStatus: WalletStatus.success,
          kycSessionId: data.sessionId,
          kycSessionExpiresAt: data.expiresAtDate,
          kycSessionErrorMessage: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          kycSessionStatus: WalletStatus.failure,
          kycSessionErrorMessage: e.toString(),
        ),
      );
    }
  }

  void _onKycSessionResetRequested(
    WalletKycSessionResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        kycSessionStatus: WalletStatus.initial,
        kycSessionId: null,
        kycSessionExpiresAt: null,
        kycSessionErrorMessage: null,
      ),
    );
  }

  Future<void> _onKycAnalyzeIdRequested(
    WalletKycAnalyzeIdRequested event,
    Emitter<WalletState> emit,
  ) async {
    final side = event.side.toLowerCase();
    final isFront = side == 'front';

    emit(
      state.copyWith(
        kycFrontAnalyzeStatus: isFront
            ? WalletStatus.loading
            : state.kycFrontAnalyzeStatus,
        kycBackAnalyzeStatus: isFront
            ? state.kycBackAnalyzeStatus
            : WalletStatus.loading,
        kycFrontAnalyzeErrorMessage: isFront
            ? null
            : state.kycFrontAnalyzeErrorMessage,
        kycBackAnalyzeErrorMessage: isFront
            ? state.kycBackAnalyzeErrorMessage
            : null,
        kycExtractedData: isFront ? null : state.kycExtractedData,
      ),
    );

    try {
      final bytes = await File(event.imagePath).readAsBytes();
      final imageData = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      final result = await _kycApi.analyzeId(
        imageData: imageData,
        side: side,
        sessionHint: event.sessionHint,
      );

      if (result.isFailure || result.data == null) {
        final isNetworkErr = _isNetworkDioError(result.error);
        emit(
          state.copyWith(
            kycFrontAnalyzeStatus: isFront
                ? WalletStatus.failure
                : state.kycFrontAnalyzeStatus,
            kycBackAnalyzeStatus: isFront
                ? state.kycBackAnalyzeStatus
                : WalletStatus.failure,
            kycFrontAnalyzeErrorMessage: isFront
                ? (result.errorMessage ?? 'Upload failed')
                : state.kycFrontAnalyzeErrorMessage,
            kycBackAnalyzeErrorMessage: isFront
                ? state.kycBackAnalyzeErrorMessage
                : (result.errorMessage ?? 'Upload failed'),
            kycFrontAnalyzeIsNetworkError: isFront
                ? isNetworkErr
                : state.kycFrontAnalyzeIsNetworkError,
            kycBackAnalyzeIsNetworkError: isFront
                ? state.kycBackAnalyzeIsNetworkError
                : isNetworkErr,
            kycExtractedData: isFront ? null : state.kycExtractedData,
          ),
        );
        return;
      }

      final data = result.data!;

      if (data.isSuccess) {
        // Write the cropped crop back to the file so the UI can preview it.
        final croppedImageData = data.croppedImageData;
        if (croppedImageData != null && croppedImageData.isNotEmpty) {
          await _writeBase64ToFile(croppedImageData, event.imagePath);
        }

        // No separate media upload: the new submit sends the cropped data URL
        // directly (the Worker uploads it server-side).
        emit(
          state.copyWith(
            kycFrontAnalyzeStatus: isFront
                ? WalletStatus.success
                : state.kycFrontAnalyzeStatus,
            kycBackAnalyzeStatus: isFront
                ? state.kycBackAnalyzeStatus
                : WalletStatus.success,
            kycFrontImagePath: isFront
                ? event.imagePath
                : state.kycFrontImagePath,
            kycBackImagePath: isFront
                ? state.kycBackImagePath
                : event.imagePath,
            kycExtractedData: isFront
                ? data.extractedData
                : state.kycExtractedData,
            kycNextStep: data.nextStep,
            kycIdFaceImageData: isFront
                ? (data.idFaceImageData ?? data.croppedImageData)
                : state.kycIdFaceImageData,
            kycFrontAnalyzeErrorMessage: isFront
                ? null
                : state.kycFrontAnalyzeErrorMessage,
            kycBackAnalyzeErrorMessage: isFront
                ? state.kycBackAnalyzeErrorMessage
                : null,
            // The cropped data URL is what gets sent at submit.
            kycFrontImageData: isFront
                ? (croppedImageData ?? state.kycFrontImageData)
                : state.kycFrontImageData,
            kycBackImageData: isFront
                ? state.kycBackImageData
                : (croppedImageData ?? state.kycBackImageData),
          ),
        );
        return;
      }

      final errorMessage = data.isError
          ? (data.message ?? data.code ?? 'Upload failed')
          : 'Document not found. Try again.';

      // data.isError / isNotFound = structured server response → always server error
      emit(
        state.copyWith(
          kycFrontAnalyzeStatus: isFront
              ? WalletStatus.failure
              : state.kycFrontAnalyzeStatus,
          kycBackAnalyzeStatus: isFront
              ? state.kycBackAnalyzeStatus
              : WalletStatus.failure,
          kycFrontAnalyzeErrorMessage: isFront
              ? errorMessage
              : state.kycFrontAnalyzeErrorMessage,
          kycBackAnalyzeErrorMessage: isFront
              ? state.kycBackAnalyzeErrorMessage
              : errorMessage,
          kycFrontAnalyzeIsNetworkError: isFront
              ? false
              : state.kycFrontAnalyzeIsNetworkError,
          kycBackAnalyzeIsNetworkError: isFront
              ? state.kycBackAnalyzeIsNetworkError
              : false,
          kycExtractedData: isFront ? null : state.kycExtractedData,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          kycFrontAnalyzeStatus: isFront
              ? WalletStatus.failure
              : state.kycFrontAnalyzeStatus,
          kycBackAnalyzeStatus: isFront
              ? state.kycBackAnalyzeStatus
              : WalletStatus.failure,
          kycFrontAnalyzeErrorMessage: isFront
              ? e.toString()
              : state.kycFrontAnalyzeErrorMessage,
          kycBackAnalyzeErrorMessage: isFront
              ? state.kycBackAnalyzeErrorMessage
              : e.toString(),
          kycFrontAnalyzeIsNetworkError: isFront
              ? _isNetworkDioError(e)
              : state.kycFrontAnalyzeIsNetworkError,
          kycBackAnalyzeIsNetworkError: isFront
              ? state.kycBackAnalyzeIsNetworkError
              : _isNetworkDioError(e),
          kycExtractedData: isFront ? null : state.kycExtractedData,
        ),
      );
    }
  }

  void _onKycAnalyzeIdResetRequested(
    WalletKycAnalyzeIdResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        kycFrontAnalyzeStatus: WalletStatus.initial,
        kycBackAnalyzeStatus: WalletStatus.initial,
        kycFrontImagePath: null,
        kycBackImagePath: null,
        kycExtractedData: null,
        kycNextStep: null,
        kycIdFaceImageData: null,
        kycFrontAnalyzeErrorMessage: null,
        kycBackAnalyzeErrorMessage: null,
        kycFrontAnalyzeIsNetworkError: false,
        kycBackAnalyzeIsNetworkError: false,
        kycFrontImageData: null,
        kycBackImageData: null,
      ),
    );
  }

  Future<void> _writeBase64ToFile(String base64Data, String outputPath) async {
    try {
      final decoded = base64Decode(base64Data);
      await File(outputPath).writeAsBytes(decoded, flush: true);
    } catch (_) {
      // If decoding fails keep original file
    }
  }

  Future<void> _onKycLivenessRequested(
    WalletKycLivenessRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(kycLivenessStatus: WalletStatus.loading));

    try {
      final result = await _kycLivenessApi.liveness(
        faceImageData: event.faceImageData,
        challengeStep: event.challengeStep,
        crop: true,
      );

      if (result.isFailure || result.data == null) {
        emit(
          state.copyWith(
            kycLivenessStatus: WalletStatus.failure,
            kycLivenessErrorMessage:
                result.errorMessage ?? 'Liveness check failed',
          ),
        );
        return;
      }

      final data = result.data!;

      if (data.isLive && data.faceImageData != null) {
        // Only the front-facing (`look_straight`) challenge image is kept as
        // the canonical selfie shown in the green frame and sent to
        // compare-face/submit. The later turn challenges still update
        // `selfieImageData` (for the per-challenge liveness gate) but must NOT
        // overwrite the front face.
        final isFrontChallenge = event.challengeStep == 'look_straight';
        emit(
          state.copyWith(
            kycLivenessStatus: WalletStatus.success,
            selfieImageData: data.faceImageData,
            kycFrontSelfieImageData: isFrontChallenge
                ? data.faceImageData
                : state.kycFrontSelfieImageData,
            kycLivenessConfidence: data.metrics?.confidence,
            kycLivenessErrorMessage: null,
          ),
        );
      } else {
        emit(
          state.copyWith(
            kycLivenessStatus: WalletStatus.failure,
            kycLivenessErrorMessage: 'Liveness verification failed',
            selfieImageData: null,
          ),
        );
      }
    } catch (e) {
      emit(
        state.copyWith(
          kycLivenessStatus: WalletStatus.failure,
          kycLivenessErrorMessage: e.toString(),
          selfieImageData: null,
        ),
      );
    }
  }

  void _onKycLivenessResetRequested(
    WalletKycLivenessResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        kycLivenessStatus: WalletStatus.initial,
        selfieImageData: null,
        kycLivenessErrorMessage: null,
      ),
    );
  }

  Future<void> _onKycCompareFaceRequested(
    WalletKycCompareFaceRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(
      state.copyWith(
        kycCompareFaceStatus: WalletStatus.loading,
        kycCompareFaceErrorMessage: null,
        kycCompareFaceErrorCode: null,
      ),
    );

    try {
      final result = await _kycCompareFaceApi.compareFace(
        selfieImageData: event.selfieImageData,
        idFaceImageData: event.idFaceImageData,
      );

      if (result.isFailure || result.data == null) {
        final msg = result.errorMessage ?? 'Face comparison failed';
        emit(
          state.copyWith(
            kycCompareFaceStatus: WalletStatus.failure,
            kycCompareFaceErrorMessage: msg,
            kycCompareFaceErrorCode: null,
          ),
        );
        emitApiErrorEvent(ApiErrorEvent(msg));
        return;
      }

      final data = result.data!;

      if (data.isSuccess) {
        // Face matched → submit is the terminal step (video interview removed).
        final extracted = state.kycExtractedData;
        final sessionId = state.kycSessionId;

        // A fresh single-use session is mandatory to submit.
        if (sessionId == null || sessionId.isEmpty) {
          const msg = 'Missing verification session. Please restart.';
          emit(
            state.copyWith(
              kycCompareFaceStatus: WalletStatus.failure,
              kycCompareFaceErrorMessage: msg,
              kycCompareFaceErrorCode: 'NO_SESSION',
            ),
          );
          emitApiErrorEvent(const ApiErrorEvent(msg));
          return;
        }

        // Guard against sending empty image payloads — the backend's document
        // upload step fails (502) on empty/missing images.
        final frontImg = state.kycFrontImageData ?? '';
        // The front-facing (look_straight) selfie — same image matched against
        // the ID and shown in the green frame. Fall back to the last liveness
        // frame only if the front one is somehow missing.
        final selfieImg =
            state.kycFrontSelfieImageData ?? state.selfieImageData ?? '';
        if (frontImg.isEmpty || selfieImg.isEmpty) {
          const msg = 'Missing verification images. Please restart.';
          emit(
            state.copyWith(
              kycCompareFaceStatus: WalletStatus.failure,
              kycCompareFaceErrorMessage: msg,
              kycCompareFaceErrorCode: 'MISSING_IMAGES',
            ),
          );
          emitApiErrorEvent(const ApiErrorEvent(msg));
          return;
        }

        final fullName = (extracted?.name?.trim().isNotEmpty ?? false)
            ? extracted!.name!.trim()
            : '${TrydosWallet.config.firstName} ${TrydosWallet.config.lastName}'
                  .trim();
        // Same value goes in both number fields so nationalIdNumber is never
        // empty on the backend. Pick the first NON-EMPTY source (?? only
        // guards null, not the empty string the OCR sometimes returns).
        final nationalId =
            [extracted?.nationalNumber, extracted?.documentNumber]
                .map((e) => e?.trim() ?? '')
                .firstWhere((e) => e.isNotEmpty, orElse: () => '');
        final backImageData = state.kycBackImageData;

        final submitPayload = <String, dynamic>{
          'kycSessionId': sessionId,
          'frontImageData': frontImg,
          // Omit for passports (no back side was captured).
          if (backImageData != null && backImageData.isNotEmpty)
            'backImageData': backImageData,
          'selfieImageData': selfieImg,
          'selfieVsIdScore': data.matchScore ?? 0,
          if (state.kycLivenessConfidence != null)
            'livenessConfidence': state.kycLivenessConfidence,
          'extracted': {
            'idType': extracted?.idType ?? '',
            'country': extracted?.country ?? '',
            'name': fullName,
            'nationalNumber': nationalId,
            'documentNumber': nationalId,
            'birthday': extracted?.birthday ?? '',
            'expiryDate': extracted?.expiryDate ?? '',
          },
        };

        final submitResult = await _kycApi.submitKyc(payload: submitPayload);
        // The single-use session is spent on a successful POST; clear it so any
        // retry starts a fresh one.
        if (submitResult.isFailure || submitResult.data == null) {
          final msg = submitResult.errorMessage ?? 'KYC submit failed';
          emit(
            state.copyWith(
              kycCompareFaceStatus: WalletStatus.failure,
              kycCompareFaceErrorMessage: msg,
              kycCompareFaceErrorCode: null,
            ),
          );
          emitApiErrorEvent(ApiErrorEvent(msg));
          return;
        }

        final body = submitResult.data!;
        final kycRequest = body['kycRequest'] is Map
            ? Map<String, dynamic>.from(body['kycRequest'] as Map)
            : const <String, dynamic>{};
        final decision = (kycRequest['status'] ?? '')
            .toString()
            .trim()
            .toLowerCase();

        // The backend is the source of truth. 'rejected' → failure (let the
        // user restart with a new session); 'approved'/'pending' → success.
        if (decision == 'rejected') {
          final reason = (kycRequest['rejectionReason'] ?? '')
              .toString()
              .trim();
          final msg = reason.isNotEmpty ? reason : 'Verification rejected';
          emit(
            state.copyWith(
              kycCompareFaceStatus: WalletStatus.failure,
              kycCompareFaceErrorMessage: msg,
              kycCompareFaceErrorCode: 'REJECTED',
              kycSessionId: null,
              kycSessionStatus: WalletStatus.initial,
            ),
          );
          emitApiErrorEvent(ApiErrorEvent(msg));
          return;
        }

        WalletAnalytics.capture(
          WalletScreens.eventKycSubmitted,
          properties: {'decision': decision.isEmpty ? 'pending' : decision},
        );
        emit(
          state.copyWith(
            kycCompareFaceStatus: WalletStatus.success,
            kycCompareFaceErrorMessage: null,
            kycCompareFaceErrorCode: null,
            kycVerificationStatus: decision.isEmpty
                ? state.kycVerificationStatus
                : decision,
            kycSessionId: null,
            kycSessionStatus: WalletStatus.initial,
          ),
        );
      } else {
        final msg = data.message ?? 'Face match failed';
        emit(
          state.copyWith(
            kycCompareFaceStatus: WalletStatus.failure,
            kycCompareFaceErrorMessage: msg,
            kycCompareFaceErrorCode: data.code,
          ),
        );
        emitApiErrorEvent(ApiErrorEvent(msg));
      }
    } catch (e) {
      emit(
        state.copyWith(
          kycCompareFaceStatus: WalletStatus.failure,
          kycCompareFaceErrorMessage: e.toString(),
          kycCompareFaceErrorCode: null,
        ),
      );
      emitApiErrorEvent(ApiErrorEvent(e.toString()));
    }
  }

  void _onKycCompareFaceResetRequested(
    WalletKycCompareFaceResetRequested event,
    Emitter<WalletState> emit,
  ) {
    emit(
      state.copyWith(
        kycCompareFaceStatus: WalletStatus.initial,
        kycCompareFaceErrorMessage: null,
        kycCompareFaceErrorCode: null,
      ),
    );
  }

  Future<void> _onDepositRequestsRequested(
    WalletDepositRequestsRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(depositRequestsStatus: WalletStatus.loading));
    final result = await _depositApi.getDepositRequests(
      page: event.page,
      limit: event.limit,
    );
    if (result.isSuccess && result.data != null) {
      emit(
        state.copyWith(
          depositRequestsStatus: WalletStatus.success,
          depositRequests: result.data!.items,
          depositRequestsPage: result.data!.page,
          depositRequestsTotal: result.data!.total,
          depositRequestsTotalPages: result.data!.totalPages,
        ),
      );
    } else {
      emit(
        state.copyWith(
          depositRequestsStatus: WalletStatus.failure,
          depositRequestsErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  Future<void> _onTransferPurposesLoadRequested(
    WalletTransferPurposesLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.transferPurposesStatus == WalletStatus.loading) {
      return;
    }
    if (state.transferPurposesStatus == WalletStatus.success &&
        state.transferPurposes.isNotEmpty) {
      return;
    }

    emit(state.copyWith(transferPurposesStatus: WalletStatus.loading));
    final result = await _transferPurposesApi.getTransferPurposes(type: 'ALL');
    if (result.isSuccess && result.data != null) {
      emit(
        state.copyWith(
          transferPurposes: result.data!,
          transferPurposesStatus: WalletStatus.success,
          transferPurposesErrorMessage: null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          transferPurposesStatus: WalletStatus.failure,
          transferPurposesErrorMessage: result.errorMessage,
        ),
      );
    }
  }

  /// Payment Requests
  Future<void> _onPaymentRequestCreated(
    WalletPaymentRequestCreated event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(paymentRequestStatus: WalletStatus.loading));
    final result = await _paymentRequestsApi.createPaymentRequest(
      accountNumber: event.accountNumber,
      assetType: event.assetType,
      assetSymbol: event.assetSymbol,
      amount: event.amount,
      purposeId: event.purposeId,
      reference: event.reference,
      note: event.note,
      expiryMinutes: event.expiryMinutes,
      isPermanent: event.isPermanent,
      idempotencyKey: event.idempotencyKey,
    );

    if (result.isSuccess && result.data != null) {
      emit(
        state.copyWith(
          paymentRequestResponse: result.data,
          paymentRequestStatus: WalletStatus.success,
          paymentRequestErrorMessage: null,
        ),
      );

      // Keep financial ledger in sync after creating a payment request.
      _inFlightTransactionsPage = null;
      emit(state.copyWith(transactionsStatus: WalletStatus.loading));
      await _fetchTransactions(emit, page: 0, append: false);
    } else {
      emit(
        state.copyWith(
          paymentRequestStatus: WalletStatus.failure,
          paymentRequestErrorMessage: result.errorMessage,
        ),
      );
    }
  }
}
