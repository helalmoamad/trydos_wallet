import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/models/models.dart';
import 'package:trydos_wallet/src/services/balances_api_service.dart';
import 'package:trydos_wallet/src/services/bank_deposits_api_service.dart';
import 'package:trydos_wallet/src/services/banks_api_service.dart';
import 'package:trydos_wallet/src/services/currencies_api_service.dart';
import 'package:trydos_wallet/src/services/media_api_service.dart';
import 'package:trydos_wallet/src/services/payment_requests_api_service.dart';
import 'package:trydos_wallet/src/services/transfer_purposes_api_service.dart';
import 'package:trydos_wallet/src/services/transactions_api_service.dart';
import 'package:trydos_wallet/src/services/wallet_websocket_service.dart';
//////////////////////////////////////////////////////////////////////////
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
    TransferPurposesApiService? transferPurposesApi,
    PaymentRequestsApiService? paymentRequestsApi,
    WalletWebSocketService? walletWebSocketService,
    String? initialLanguage,
    String? firstName,
    String? lastName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? userSubtitle,
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
       _transferPurposesApi =
           transferPurposesApi ?? TransferPurposesApiService(),
       _paymentRequestsApi = paymentRequestsApi ?? PaymentRequestsApiService(),
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
           isPhoneVerified:
               isPhoneVerified ?? TrydosWallet.config.isPhoneVerified,
           isAccountActive:
               isAccountActive ?? TrydosWallet.config.isAccountActive,
           isTwoFactorEnabled:
               isTwoFactorEnabled ?? TrydosWallet.config.isTwoFactorEnabled,
           memberSince: memberSince ?? TrydosWallet.config.memberSince,
         ),
       ) {
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
    on<BalanceCardIsSelected>(_onBalanceCardIsSelected);
    on<WalletDepositFeesRequested>(_onDepositFeesRequested);
    on<WalletDepositRequestsRequested>(_onDepositRequestsRequested);
    on<WalletTransferPurposesLoadRequested>(_onTransferPurposesLoadRequested);
    on<WalletPaymentRequestCreated>(_onPaymentRequestCreated);
    on<WalletRealtimeBalanceUpdated>(_onRealtimeBalanceUpdated);
    on<WalletRealtimeTransactionReceived>(_onRealtimeTransactionReceived);

    _walletWebSocketService ??= _createDefaultWalletWebSocketService();

    _walletWebSocketService?.connect();
  }

  final CurrenciesApiService _currenciesApi;
  final BalancesApiService _balancesApi;
  final TransactionsApiService _transactionsApi;
  final BanksApiService _banksApi;
  final BankDepositsApiService _depositApi;
  final MediaApiService _mediaApi;
  final TransferPurposesApiService _transferPurposesApi;
  final PaymentRequestsApiService _paymentRequestsApi;
  WalletWebSocketService? _walletWebSocketService;

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
      onTrackedEvent: (event, payload) {
        debugPrint('[WalletWS] Event received: $event');
        debugPrint('[WalletWS] Payload: $payload');
        if (!isClosed && event == 'balance:updated' && payload is Map) {
          add(WalletRealtimeBalanceUpdated(Map<String, dynamic>.from(payload)));
        }
        if (!isClosed && event.startsWith('ledger:') && payload is Map) {
          add(
            WalletRealtimeTransactionReceived(
              event,
              Map<String, dynamic>.from(payload),
            ),
          );
        }
      },
    );
  }

  @override
  Future<void> close() {
    _walletWebSocketService?.disconnect();
    return super.close();
  }

  void _onLanguageChanged(
    WalletLanguageChanged event,
    Emitter<WalletState> emit,
  ) {
    TrydosWallet.updateLanguage(event.languageCode);
    emit(state.copyWith(languageCode: event.languageCode));
  }

  /// Currencies
  Future<void> _onRefreshAllRequested(
    WalletRefreshAllRequested event,
    Emitter<WalletState> emit,
  ) async {
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
