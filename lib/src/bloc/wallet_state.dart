import 'package:trydos_wallet/src/models/models.dart';

/// Status for various async operations in the wallet.
enum WalletStatus { initial, loading, success, failure }

/// Unified state for the entire wallet application.
class WalletState {
  static const Object _unset = Object();

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
    this.transactionsAssetSymbolFilter,
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
    // KYC Status (backend verification decision)
    this.kycStatusRequestStatus = WalletStatus.initial,
    this.kycVerificationStatus,
    this.kycStatusLabel,
    this.kycRejectionReason,
    // KYC Current (verified record details)
    this.kycCurrentStatus = WalletStatus.initial,
    this.kycCurrentRecord,
    // KYC Session
    this.kycSessionStatus = WalletStatus.initial,
    this.kycSessionId,
    this.kycSessionExpiresAt,
    this.kycSessionErrorMessage,
    // KYC Analyze ID
    this.kycFrontAnalyzeStatus = WalletStatus.initial,
    this.kycBackAnalyzeStatus = WalletStatus.initial,
    this.kycFrontImagePath,
    this.kycBackImagePath,
    this.kycExtractedData,
    this.kycNextStep,
    this.kycIdFaceImageData,
    this.kycFrontAnalyzeErrorMessage,
    this.kycBackAnalyzeErrorMessage,
    this.kycFrontAnalyzeIsNetworkError = false,
    this.kycBackAnalyzeIsNetworkError = false,
    // KYC Cropped image data URLs (sent directly at submit)
    this.kycFrontImageData,
    this.kycBackImageData,
    // KYC Selfie Upload
    // KYC Liveness
    this.kycLivenessStatus = WalletStatus.initial,
    this.selfieImageData,
    this.kycLivenessConfidence,
    this.kycLivenessErrorMessage,
    // KYC Compare Face
    this.kycCompareFaceStatus = WalletStatus.initial,
    this.kycCompareFaceErrorMessage,
    this.kycCompareFaceErrorCode,
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
    this.isVerified = false,
    this.isPhoneVerified = false,
    this.isAccountActive = true,
    this.isTwoFactorEnabled = false,
    this.memberSince,
    // QR login
    this.qrScanStatus = WalletStatus.initial,
    this.qrActionStatus = WalletStatus.initial,
    this.qrLoginRequest,
    this.qrScanErrorMessage,
    this.qrActionErrorMessage,
    this.displayId,
    this.qrActionSuccessMessage,
    this.deleteSessionStatus = WalletStatus.initial,
    this.activeSessions = const [],
    this.activeSessionsStatus = WalletStatus.initial,
    this.activeSessionsErrorMessage,
    this.sessionActionStatus = WalletStatus.initial,
    this.sessionActionErrorMessage,
    this.sessionActionSuccessMessage,
    // Logout
    this.logoutStatus = WalletStatus.initial,
    this.logoutErrorMessage,
    // Session approval (push)
    this.sessionApprovalRequest,
    this.sessionApprovalStatus = WalletStatus.initial,
    this.sessionApprovalErrorMessage,
    this.sessionApprovalSuccessMessage,
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
  final String? displayId;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? userSubtitle;
  final bool isVerified;
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
  final String? transactionsAssetSymbolFilter;

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
  final WalletStatus deleteSessionStatus;
  final String? uploadUrl;
  final String? uploadErrorMessage;

  // KYC Status (backend verification decision)
  final WalletStatus kycStatusRequestStatus;
  final String? kycVerificationStatus; // verified|pending|rejected|not_submitted
  final String? kycStatusLabel;
  final String? kycRejectionReason;

  // KYC Current (verified record details)
  final WalletStatus kycCurrentStatus;
  final KycCurrentResponse? kycCurrentRecord;

  // KYC Session
  final WalletStatus kycSessionStatus;
  final String? kycSessionId;
  final DateTime? kycSessionExpiresAt;
  final String? kycSessionErrorMessage;

  // KYC Analyze ID
  final WalletStatus kycFrontAnalyzeStatus;
  final WalletStatus kycBackAnalyzeStatus;
  final String? kycFrontImagePath;
  final String? kycBackImagePath;
  final KycExtractedData? kycExtractedData;
  final String? kycNextStep;
  final String? kycIdFaceImageData;
  final String? kycFrontAnalyzeErrorMessage;
  final String? kycBackAnalyzeErrorMessage;
  final bool kycFrontAnalyzeIsNetworkError;
  final bool kycBackAnalyzeIsNetworkError;

  // KYC Cropped image data URLs (sent directly at submit)
  final String? kycFrontImageData;
  final String? kycBackImageData;

  // KYC Selfie Upload
  // KYC Liveness
  final WalletStatus kycLivenessStatus;
  final String? selfieImageData;
  final double? kycLivenessConfidence;
  final String? kycLivenessErrorMessage;

  // KYC Compare Face
  final WalletStatus kycCompareFaceStatus;
  final String? kycCompareFaceErrorMessage;
  final String? kycCompareFaceErrorCode;

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

  // QR login
  final WalletStatus qrScanStatus;
  final WalletStatus qrActionStatus;
  final WalletQrLoginRequest? qrLoginRequest;
  final String? qrScanErrorMessage;
  final String? qrActionErrorMessage;
  final String? qrActionSuccessMessage;

  // Active sessions
  final List<WalletSession> activeSessions;
  final WalletStatus activeSessionsStatus;
  final String? activeSessionsErrorMessage;
  final WalletStatus sessionActionStatus;
  final String? sessionActionErrorMessage;
  final String? sessionActionSuccessMessage;

  // Logout
  final WalletStatus logoutStatus;
  final String? logoutErrorMessage;

  // Session approval (push via WebSocket)
  final SessionApprovalRequest? sessionApprovalRequest;
  final WalletStatus sessionApprovalStatus;
  final String? sessionApprovalErrorMessage;
  final String? sessionApprovalSuccessMessage;

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
    String? displayId,
    WalletStatus? deleteSessionStatus,
    Object? transactionsNextCursor = _unset,
    String? transactionsErrorMessage,
    Object? transactionsAssetSymbolFilter = _unset,
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
    WalletStatus? kycStatusRequestStatus,
    Object? kycVerificationStatus = _unset,
    Object? kycStatusLabel = _unset,
    Object? kycRejectionReason = _unset,
    WalletStatus? kycCurrentStatus,
    Object? kycCurrentRecord = _unset,
    WalletStatus? kycSessionStatus,
    Object? kycSessionId = _unset,
    Object? kycSessionExpiresAt = _unset,
    Object? kycSessionErrorMessage = _unset,
    WalletStatus? kycFrontAnalyzeStatus,
    WalletStatus? kycBackAnalyzeStatus,
    Object? kycFrontImagePath = _unset,
    Object? kycBackImagePath = _unset,
    Object? kycExtractedData = _unset,
    Object? kycNextStep = _unset,
    Object? kycIdFaceImageData = _unset,
    Object? kycFrontAnalyzeErrorMessage = _unset,
    Object? kycBackAnalyzeErrorMessage = _unset,
    bool? kycFrontAnalyzeIsNetworkError,
    bool? kycBackAnalyzeIsNetworkError,
    Object? kycFrontImageData = _unset,
    Object? kycBackImageData = _unset,
    WalletStatus? kycLivenessStatus,
    Object? selfieImageData = _unset,
    Object? kycLivenessConfidence = _unset,
    Object? kycLivenessErrorMessage = _unset,
    WalletStatus? kycCompareFaceStatus,
    Object? kycCompareFaceErrorMessage = _unset,
    Object? kycCompareFaceErrorCode = _unset,
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
    bool? isVerified,
    bool? isPhoneVerified,
    bool? isAccountActive,
    bool? isTwoFactorEnabled,
    DateTime? memberSince,
    String? depositRequestsErrorMessage,
    // Payment Requests
    PaymentRequestResponse? paymentRequestResponse,
    WalletStatus? paymentRequestStatus,
    String? paymentRequestErrorMessage,
    WalletStatus? qrScanStatus,
    WalletStatus? qrActionStatus,
    Object? qrLoginRequest = _unset,
    Object? qrScanErrorMessage = _unset,
    Object? qrActionErrorMessage = _unset,
    Object? qrActionSuccessMessage = _unset,
    List<WalletSession>? activeSessions,
    WalletStatus? activeSessionsStatus,
    Object? activeSessionsErrorMessage = _unset,
    WalletStatus? sessionActionStatus,
    Object? sessionActionErrorMessage = _unset,
    Object? sessionActionSuccessMessage = _unset,
    WalletStatus? logoutStatus,
    Object? logoutErrorMessage = _unset,
    Object? sessionApprovalRequest = _unset,
    WalletStatus? sessionApprovalStatus,
    Object? sessionApprovalErrorMessage = _unset,
    Object? sessionApprovalSuccessMessage = _unset,
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
      displayId: displayId ?? this.displayId,
      transactionsStatus: transactionsStatus ?? this.transactionsStatus,
      transactionsHasNext: transactionsHasNext ?? this.transactionsHasNext,
      transactionsNextCursor: transactionsNextCursor == _unset
          ? this.transactionsNextCursor
          : transactionsNextCursor as String?,
      deleteSessionStatus: deleteSessionStatus ?? this.deleteSessionStatus,
      transactionsErrorMessage:
          transactionsErrorMessage ?? this.transactionsErrorMessage,
      transactionsAssetSymbolFilter: transactionsAssetSymbolFilter == _unset
          ? this.transactionsAssetSymbolFilter
          : transactionsAssetSymbolFilter as String?,
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
      kycStatusRequestStatus:
          kycStatusRequestStatus ?? this.kycStatusRequestStatus,
      kycVerificationStatus: kycVerificationStatus == _unset
          ? this.kycVerificationStatus
          : kycVerificationStatus as String?,
      kycStatusLabel: kycStatusLabel == _unset
          ? this.kycStatusLabel
          : kycStatusLabel as String?,
      kycRejectionReason: kycRejectionReason == _unset
          ? this.kycRejectionReason
          : kycRejectionReason as String?,
      kycCurrentStatus: kycCurrentStatus ?? this.kycCurrentStatus,
      kycCurrentRecord: kycCurrentRecord == _unset
          ? this.kycCurrentRecord
          : kycCurrentRecord as KycCurrentResponse?,
      kycSessionStatus: kycSessionStatus ?? this.kycSessionStatus,
      kycSessionId: kycSessionId == _unset
          ? this.kycSessionId
          : kycSessionId as String?,
      kycSessionExpiresAt: kycSessionExpiresAt == _unset
          ? this.kycSessionExpiresAt
          : kycSessionExpiresAt as DateTime?,
      kycSessionErrorMessage: kycSessionErrorMessage == _unset
          ? this.kycSessionErrorMessage
          : kycSessionErrorMessage as String?,
      kycFrontAnalyzeStatus:
          kycFrontAnalyzeStatus ?? this.kycFrontAnalyzeStatus,
      kycBackAnalyzeStatus: kycBackAnalyzeStatus ?? this.kycBackAnalyzeStatus,
      kycFrontImagePath: kycFrontImagePath == _unset
          ? this.kycFrontImagePath
          : kycFrontImagePath as String?,
      kycBackImagePath: kycBackImagePath == _unset
          ? this.kycBackImagePath
          : kycBackImagePath as String?,
      kycExtractedData: kycExtractedData == _unset
          ? this.kycExtractedData
          : kycExtractedData as KycExtractedData?,
      kycNextStep: kycNextStep == _unset
          ? this.kycNextStep
          : kycNextStep as String?,
      kycIdFaceImageData: kycIdFaceImageData == _unset
          ? this.kycIdFaceImageData
          : kycIdFaceImageData as String?,
      kycFrontAnalyzeErrorMessage: kycFrontAnalyzeErrorMessage == _unset
          ? this.kycFrontAnalyzeErrorMessage
          : kycFrontAnalyzeErrorMessage as String?,
      kycBackAnalyzeErrorMessage: kycBackAnalyzeErrorMessage == _unset
          ? this.kycBackAnalyzeErrorMessage
          : kycBackAnalyzeErrorMessage as String?,
      kycFrontAnalyzeIsNetworkError:
          kycFrontAnalyzeIsNetworkError ?? this.kycFrontAnalyzeIsNetworkError,
      kycBackAnalyzeIsNetworkError:
          kycBackAnalyzeIsNetworkError ?? this.kycBackAnalyzeIsNetworkError,
      kycFrontImageData: kycFrontImageData == _unset
          ? this.kycFrontImageData
          : kycFrontImageData as String?,
      kycBackImageData: kycBackImageData == _unset
          ? this.kycBackImageData
          : kycBackImageData as String?,
      kycLivenessStatus: kycLivenessStatus ?? this.kycLivenessStatus,
      selfieImageData: selfieImageData == _unset
          ? this.selfieImageData
          : selfieImageData as String?,
      kycLivenessConfidence: kycLivenessConfidence == _unset
          ? this.kycLivenessConfidence
          : kycLivenessConfidence as double?,
      kycLivenessErrorMessage: kycLivenessErrorMessage == _unset
          ? this.kycLivenessErrorMessage
          : kycLivenessErrorMessage as String?,
      kycCompareFaceStatus: kycCompareFaceStatus ?? this.kycCompareFaceStatus,
      kycCompareFaceErrorMessage: kycCompareFaceErrorMessage == _unset
          ? this.kycCompareFaceErrorMessage
          : kycCompareFaceErrorMessage as String?,
      kycCompareFaceErrorCode: kycCompareFaceErrorCode == _unset
          ? this.kycCompareFaceErrorCode
          : kycCompareFaceErrorCode as String?,
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
      isVerified: isVerified ?? this.isVerified,
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
      qrScanStatus: qrScanStatus ?? this.qrScanStatus,
      qrActionStatus: qrActionStatus ?? this.qrActionStatus,
      qrLoginRequest: qrLoginRequest == _unset
          ? this.qrLoginRequest
          : qrLoginRequest as WalletQrLoginRequest?,
      qrScanErrorMessage: qrScanErrorMessage == _unset
          ? this.qrScanErrorMessage
          : qrScanErrorMessage as String?,
      qrActionErrorMessage: qrActionErrorMessage == _unset
          ? this.qrActionErrorMessage
          : qrActionErrorMessage as String?,
      qrActionSuccessMessage: qrActionSuccessMessage == _unset
          ? this.qrActionSuccessMessage
          : qrActionSuccessMessage as String?,
      activeSessions: activeSessions ?? this.activeSessions,
      activeSessionsStatus: activeSessionsStatus ?? this.activeSessionsStatus,
      activeSessionsErrorMessage: activeSessionsErrorMessage == _unset
          ? this.activeSessionsErrorMessage
          : activeSessionsErrorMessage as String?,
      sessionActionStatus: sessionActionStatus ?? this.sessionActionStatus,
      sessionActionErrorMessage: sessionActionErrorMessage == _unset
          ? this.sessionActionErrorMessage
          : sessionActionErrorMessage as String?,
      sessionActionSuccessMessage: sessionActionSuccessMessage == _unset
          ? this.sessionActionSuccessMessage
          : sessionActionSuccessMessage as String?,
      logoutStatus: logoutStatus ?? this.logoutStatus,
      logoutErrorMessage: logoutErrorMessage == _unset
          ? this.logoutErrorMessage
          : logoutErrorMessage as String?,
      sessionApprovalRequest: sessionApprovalRequest == _unset
          ? this.sessionApprovalRequest
          : sessionApprovalRequest as SessionApprovalRequest?,
      sessionApprovalStatus:
          sessionApprovalStatus ?? this.sessionApprovalStatus,
      sessionApprovalErrorMessage: sessionApprovalErrorMessage == _unset
          ? this.sessionApprovalErrorMessage
          : sessionApprovalErrorMessage as String?,
      sessionApprovalSuccessMessage: sessionApprovalSuccessMessage == _unset
          ? this.sessionApprovalSuccessMessage
          : sessionApprovalSuccessMessage as String?,
    );
  }
}
