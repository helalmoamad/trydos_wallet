import 'package:trydos_wallet/src/models/models.dart';

/// Status for various async operations in the wallet.
enum WalletStatus { initial, loading, success, failure }

/// Unified state for the entire wallet application.
class WalletState {
  const WalletState({
    this.languageCode = 'en',
    // Currencies
    this.currencies = const [],
    this.currenciesStatus = WalletStatus.initial,
    this.currenciesHasNext = false,
    this.currenciesErrorMessage,
    // Balances
    this.balances = const {},
    this.balancesStatus = WalletStatus.initial,
    this.loadingBalanceIds = const {},
    // Transactions
    this.transactions = const [],
    this.transactionsStatus = WalletStatus.initial,
    this.transactionsHasNext = false,
    this.transactionsNextCursor,
    this.transactionsErrorMessage,
    // Transfer Purposes
    this.transferPurposes = const [],
    this.transferPurposesStatus = WalletStatus.initial,
    this.transferPurposesErrorMessage,
    // Banks
    this.banks = const [],
    this.banksStatus = WalletStatus.initial,
    this.banksHasNext = false,
    this.banksErrorMessage,
    // Deposit Submission
    this.depositStatus = WalletStatus.initial,
    this.depositErrorMessage,
    // Media Upload
    this.uploadStatus = WalletStatus.initial,
    this.uploadUrl,
    this.uploadErrorMessage,
    // Fees
    this.depositFees,
    this.depositFeesStatus = WalletStatus.initial,
    this.depositFeesErrorMessage,
    // Deposit Requests
    this.depositRequests = const [],
    this.depositRequestsStatus = WalletStatus.initial,
    this.depositRequestsPage = 0,
    this.depositRequestsTotal = 0,
    this.depositRequestsTotalPages = 0,
    this.balanceCardIsSelected = false,
    this.selectedAssetId,
    this.selectedAssetSymbol = '',
    this.selectedAssetType = '',
    this.depositRequestsErrorMessage,
    // Payment Requests
    this.paymentRequestResponse,
    this.paymentRequestStatus = WalletStatus.initial,
    this.paymentRequestErrorMessage,
    this.firstName = 'M*****',
    this.lastName = 'A*****',
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.userSubtitle,
    this.isPhoneVerified = false,
    this.isAccountActive = true,
    this.isTwoFactorEnabled = false,
    this.memberSince,
  });

  final String languageCode;

  // Currencies (Paginated)
  final List<Currency> currencies;
  final WalletStatus currenciesStatus;
  final bool currenciesHasNext;
  final String? currenciesErrorMessage;

  // Balances (Map for caching)
  final Map<String, Balance> balances;
  final WalletStatus balancesStatus;
  final Set<String> loadingBalanceIds;
  final bool balanceCardIsSelected;
  final String? selectedAssetId;
  final String selectedAssetSymbol;
  final String selectedAssetType;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? userSubtitle;
  final bool isPhoneVerified;
  final bool isAccountActive;
  final bool isTwoFactorEnabled;
  final DateTime? memberSince;

  // Transactions (Cursor Paginated)
  final List<Transaction> transactions;
  final WalletStatus transactionsStatus;
  final bool transactionsHasNext;
  final String? transactionsNextCursor;
  final String? transactionsErrorMessage;

  // Transfer Purposes
  final List<TransferPurpose> transferPurposes;
  final WalletStatus transferPurposesStatus;
  final String? transferPurposesErrorMessage;

  // Banks (Paginated)
  final List<Bank> banks;
  final WalletStatus banksStatus;
  final bool banksHasNext;
  final String? banksErrorMessage;

  // Deposit Actions
  final WalletStatus depositStatus;
  final String? depositErrorMessage;

  // Media
  final WalletStatus uploadStatus;
  final String? uploadUrl;
  final String? uploadErrorMessage;

  // Fees
  final DepositFeesResult? depositFees;
  final WalletStatus depositFeesStatus;
  final String? depositFeesErrorMessage;

  // Deposit Requests
  final List<BankDepositRequest> depositRequests;
  final WalletStatus depositRequestsStatus;
  final int depositRequestsPage;
  final int depositRequestsTotal;
  final int depositRequestsTotalPages;
  final String? depositRequestsErrorMessage;

  // Payment Requests
  final PaymentRequestResponse? paymentRequestResponse;
  final WalletStatus paymentRequestStatus;
  final String? paymentRequestErrorMessage;

  /// RTL helper
  bool get isRtl => languageCode == 'ar' || languageCode == 'ku';

  /// Masked name helper: FirstLetter + *****
  String get maskedName {
    String mask(String text) {
      if (text.isEmpty) return '*****';
      return '${text[0]}*****';
    }

    return '${mask(firstName)} ${mask(lastName)}';
  }

  WalletState copyWith({
    String? languageCode,
    List<Currency>? currencies,
    WalletStatus? currenciesStatus,
    bool? currenciesHasNext,
    String? currenciesErrorMessage,
    Map<String, Balance>? balances,
    WalletStatus? balancesStatus,
    Set<String>? loadingBalanceIds,
    List<Transaction>? transactions,
    WalletStatus? transactionsStatus,
    bool? transactionsHasNext,
    String? transactionsNextCursor,
    String? transactionsErrorMessage,
    List<TransferPurpose>? transferPurposes,
    WalletStatus? transferPurposesStatus,
    String? transferPurposesErrorMessage,
    List<Bank>? banks,
    WalletStatus? banksStatus,
    bool? banksHasNext,
    String? banksErrorMessage,
    WalletStatus? depositStatus,
    String? depositErrorMessage,
    WalletStatus? uploadStatus,
    bool? balanceCardIsSelected,
    String? uploadUrl,
    String? uploadErrorMessage,
    DepositFeesResult? depositFees,
    WalletStatus? depositFeesStatus,
    String? depositFeesErrorMessage,
    List<BankDepositRequest>? depositRequests,
    WalletStatus? depositRequestsStatus,
    int? depositRequestsPage,
    int? depositRequestsTotal,
    int? depositRequestsTotalPages,
    String? selectedAssetId,
    String? selectedAssetSymbol,
    String? selectedAssetType,
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
    String? depositRequestsErrorMessage,
    // Payment Requests
    PaymentRequestResponse? paymentRequestResponse,
    WalletStatus? paymentRequestStatus,
    String? paymentRequestErrorMessage,
  }) {
    return WalletState(
      languageCode: languageCode ?? this.languageCode,
      currencies: currencies ?? this.currencies,
      currenciesStatus: currenciesStatus ?? this.currenciesStatus,
      currenciesHasNext: currenciesHasNext ?? this.currenciesHasNext,
      currenciesErrorMessage:
          currenciesErrorMessage ?? this.currenciesErrorMessage,
      balances: balances ?? this.balances,
      balancesStatus: balancesStatus ?? this.balancesStatus,
      loadingBalanceIds: loadingBalanceIds ?? this.loadingBalanceIds,
      transactions: transactions ?? this.transactions,
      transactionsStatus: transactionsStatus ?? this.transactionsStatus,
      transactionsHasNext: transactionsHasNext ?? this.transactionsHasNext,
      transactionsNextCursor:
          transactionsNextCursor ?? this.transactionsNextCursor,
      transactionsErrorMessage:
          transactionsErrorMessage ?? this.transactionsErrorMessage,
      transferPurposes: transferPurposes ?? this.transferPurposes,
      transferPurposesStatus:
          transferPurposesStatus ?? this.transferPurposesStatus,
      transferPurposesErrorMessage:
          transferPurposesErrorMessage ?? this.transferPurposesErrorMessage,
      banks: banks ?? this.banks,
      banksStatus: banksStatus ?? this.banksStatus,
      banksHasNext: banksHasNext ?? this.banksHasNext,
      banksErrorMessage: banksErrorMessage ?? this.banksErrorMessage,
      depositStatus: depositStatus ?? this.depositStatus,
      balanceCardIsSelected:
          balanceCardIsSelected ?? this.balanceCardIsSelected,
      depositErrorMessage: depositErrorMessage ?? this.depositErrorMessage,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadUrl: uploadUrl ?? this.uploadUrl,
      uploadErrorMessage: uploadErrorMessage ?? this.uploadErrorMessage,
      depositFees: depositFees ?? this.depositFees,
      depositFeesStatus: depositFeesStatus ?? this.depositFeesStatus,
      depositFeesErrorMessage:
          depositFeesErrorMessage ?? this.depositFeesErrorMessage,
      depositRequests: depositRequests ?? this.depositRequests,
      depositRequestsStatus:
          depositRequestsStatus ?? this.depositRequestsStatus,
      depositRequestsPage: depositRequestsPage ?? this.depositRequestsPage,
      depositRequestsTotal: depositRequestsTotal ?? this.depositRequestsTotal,
      depositRequestsTotalPages:
          depositRequestsTotalPages ?? this.depositRequestsTotalPages,
      selectedAssetId: selectedAssetId ?? this.selectedAssetId,
      selectedAssetSymbol: selectedAssetSymbol ?? this.selectedAssetSymbol,
      selectedAssetType: selectedAssetType ?? this.selectedAssetType,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      userSubtitle: userSubtitle ?? this.userSubtitle,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isAccountActive: isAccountActive ?? this.isAccountActive,
      isTwoFactorEnabled: isTwoFactorEnabled ?? this.isTwoFactorEnabled,
      memberSince: memberSince ?? this.memberSince,
      depositRequestsErrorMessage:
          depositRequestsErrorMessage ?? this.depositRequestsErrorMessage,
      paymentRequestResponse:
          paymentRequestResponse ?? this.paymentRequestResponse,
      paymentRequestStatus: paymentRequestStatus ?? this.paymentRequestStatus,
      paymentRequestErrorMessage:
          paymentRequestErrorMessage ?? this.paymentRequestErrorMessage,
    );
  }
}
