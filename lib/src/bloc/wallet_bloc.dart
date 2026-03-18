import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/models/models.dart';
import 'package:trydos_wallet/src/services/balances_api_service.dart';
import 'package:trydos_wallet/src/services/bank_deposits_api_service.dart';
import 'package:trydos_wallet/src/services/banks_api_service.dart';
import 'package:trydos_wallet/src/services/currencies_api_service.dart';
import 'package:trydos_wallet/src/services/media_api_service.dart';
import 'package:trydos_wallet/src/services/transfer_purposes_api_service.dart';
import 'package:trydos_wallet/src/services/transactions_api_service.dart';

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
    String? initialLanguage,
    String? firstName,
    String? lastName,
  }) : _currenciesApi = currenciesApi ?? CurrenciesApiService(),
       _balancesApi = balancesApi ?? BalancesApiService(),
       _transactionsApi = transactionsApi ?? TransactionsApiService(),
       _banksApi = banksApi ?? BanksApiService(),
       _depositApi = depositApi ?? BankDepositsApiService(),
       _mediaApi = mediaApi ?? MediaApiService(),
       _transferPurposesApi =
           transferPurposesApi ?? TransferPurposesApiService(),
       super(
         WalletState(
           languageCode: initialLanguage ?? TrydosWallet.config.languageCode,
           firstName: firstName ?? TrydosWallet.config.firstName,
           lastName: lastName ?? TrydosWallet.config.lastName,
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
    on<WalletBanksLoadRequested>(_onBanksLoadRequested);
    on<WalletBanksLoadMoreRequested>(_onBanksLoadMoreRequested);
    on<WalletDepositSubmitted>(_onDepositSubmitted);
    on<WalletImageUploadRequested>(_onImageUploadRequested);
    on<WalletImageResetRequested>(_onImageResetRequested);
    on<BalanceCardIsSelected>(_onBalanceCardIsSelected);
    on<WalletDepositFeesRequested>(_onDepositFeesRequested);
    on<WalletDepositRequestsRequested>(_onDepositRequestsRequested);
    on<WalletTransferPurposesLoadRequested>(_onTransferPurposesLoadRequested);
  }

  final CurrenciesApiService _currenciesApi;
  final BalancesApiService _balancesApi;
  final TransactionsApiService _transactionsApi;
  final BanksApiService _banksApi;
  final BankDepositsApiService _depositApi;
  final MediaApiService _mediaApi;
  final TransferPurposesApiService _transferPurposesApi;

  int _currenciesPage = 0;
  int _banksPage = 0;
  final int _pageSize = 10;

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
    emit(
      state.copyWith(
        currenciesStatus: WalletStatus.loading,
        balancesStatus: WalletStatus.loading,
        transactionsStatus: WalletStatus.loading,
      ),
    );
    await _fetchCurrencies(emit, page: 0, append: false);
    await _fetchAllBalances(emit);
    await _fetchTransactions(emit, cursor: null, append: false);
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

  void _onBalanceCardIsSelected(
    BalanceCardIsSelected event,
    Emitter<WalletState> emit,
  ) {
    print(
      "DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD${event.isSelected} ${event.assetId}",
    );
    emit(
      state.copyWith(
        balanceCardIsSelected: event.isSelected,
        selectedAssetId: event.isSelected ? event.assetId : null,
      ),
    );
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
    // Balances are loaded in one request via _fetchAllBalances.
    // Tapping a currency should only change UI selection.
    return;
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

  /// Transactions
  Future<void> _onTransactionsLoadRequested(
    WalletTransactionsLoadRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(transactionsStatus: WalletStatus.loading));
    await _fetchTransactions(emit, cursor: null, append: false);
  }

  Future<void> _onTransactionsRefreshRequested(
    WalletTransactionsRefreshRequested event,
    Emitter<WalletState> emit,
  ) async {
    await _fetchTransactions(emit, cursor: null, append: false);
  }

  Future<void> _onTransactionsLoadMoreRequested(
    WalletTransactionsLoadMoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    if (state.transactionsStatus == WalletStatus.loading ||
        !state.transactionsHasNext ||
        state.transactionsNextCursor == null) {
      return;
    }
    await _fetchTransactions(
      emit,
      cursor: state.transactionsNextCursor,
      append: true,
    );
  }

  Future<void> _fetchTransactions(
    Emitter<WalletState> emit, {
    required String? cursor,
    required bool append,
  }) async {
    final result = await _transactionsApi.getTransactions(
      cursor: cursor,
      limit: _pageSize,
    );
    if (result.isSuccess && result.data != null) {
      emit(
        state.copyWith(
          transactions: append
              ? [...state.transactions, ...result.data!.items]
              : result.data!.items,
          transactionsStatus: WalletStatus.success,
          transactionsHasNext: result.data!.hasNextPage,
          transactionsNextCursor: result.data!.hasNextPage
              ? result.data!.endCursor
              : null,
        ),
      );
    } else {
      emit(
        state.copyWith(
          transactionsStatus: append
              ? WalletStatus.success
              : WalletStatus.failure,
          transactionsErrorMessage: result.errorMessage,
        ),
      );
    }
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
}
