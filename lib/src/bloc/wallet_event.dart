import 'dart:io';

import '../config/trydos_wallet_config.dart';

class WalletDepositParams {
  const WalletDepositParams({
    required this.bankId,
    required this.currencyId,
    required this.amount,
    required this.transferImageUrl,
    this.transactionReference,
    required this.idempotencyKey,
  });

  final String bankId;
  final String currencyId;
  final double amount;
  final String transferImageUrl;
  final String? transactionReference;
  final String idempotencyKey;
}

sealed class WalletEvent {
  const WalletEvent();
}

/// Reset all state (logout)
class WalletResetRequested extends WalletEvent {
  const WalletResetRequested();
}

/// Auth - logout (success/failure only)
class WalletLogoutRequested extends WalletEvent {
  const WalletLogoutRequested();
}

/// Localization
class WalletLanguageChanged extends WalletEvent {
  const WalletLanguageChanged(this.languageCode);
  final String languageCode;
}

/// Currencies
class WalletCurrenciesLoadRequested extends WalletEvent {
  const WalletCurrenciesLoadRequested();
}

class WalletCurrenciesLoadMoreRequested extends WalletEvent {
  const WalletCurrenciesLoadMoreRequested();
}

class WalletCurrenciesRefreshRequested extends WalletEvent {
  const WalletCurrenciesRefreshRequested();
}

class WalletRefreshAllRequested extends WalletEvent {
  const WalletRefreshAllRequested();
}

class WalletReconnectWebSocketRequested extends WalletEvent {
  const WalletReconnectWebSocketRequested();
}

class WalletConfigUpdated extends WalletEvent {
  const WalletConfigUpdated(this.config);

  final TrydosWalletConfig config;
}

class WalletUserProfileRefreshRequested extends WalletEvent {
  const WalletUserProfileRefreshRequested({this.silent = true});

  final bool silent;
}

/// QR login from web wallet
class WalletQrScanRequested extends WalletEvent {
  const WalletQrScanRequested(this.qrToken);

  final String qrToken;
}

class WalletQrApproveRequested extends WalletEvent {
  const WalletQrApproveRequested(this.linkId);

  final String linkId;
}

class WalletQrRejectRequested extends WalletEvent {
  const WalletQrRejectRequested(this.linkId);

  final String linkId;
}

class WalletQrLoginResetRequested extends WalletEvent {
  const WalletQrLoginResetRequested();
}

/// Active sessions / linked devices
class WalletActiveSessionsRequested extends WalletEvent {
  const WalletActiveSessionsRequested();
}

class WalletSessionDeleteRequested extends WalletEvent {
  const WalletSessionDeleteRequested(this.sessionId, this.deleteCurrentSession);

  final String sessionId;
  final bool? deleteCurrentSession;
}

/// Session approval (push via WebSocket: session:approval_request)
class WalletSessionApprovalRequestReceived extends WalletEvent {
  const WalletSessionApprovalRequestReceived(this.payload);
  final Map<String, dynamic> payload;
}

/// User responded to a session approval request (approve/reject).
class WalletSessionApprovalResponded extends WalletEvent {
  const WalletSessionApprovalResponded({
    required this.requestId,
    required this.approve,
  });
  final String requestId;
  final bool approve;
}

/// Clear the pending session approval (dismissed or expired).
class WalletSessionApprovalResetRequested extends WalletEvent {
  const WalletSessionApprovalResetRequested();
}

/// Balances
class WalletBalanceLoadRequested extends WalletEvent {
  const WalletBalanceLoadRequested(this.assetId);
  final String assetId;
}

class WalletRealtimeBalanceUpdated extends WalletEvent {
  const WalletRealtimeBalanceUpdated(this.payload);
  final Map<String, dynamic> payload;
}

class WalletRealtimeTransactionReceived extends WalletEvent {
  const WalletRealtimeTransactionReceived(this.eventName, this.payload);

  final String eventName;
  final Map<String, dynamic> payload;
}

/// Transactions
class WalletTransactionsLoadRequested extends WalletEvent {
  const WalletTransactionsLoadRequested();
}

class WalletTransactionsAssetFilterChanged extends WalletEvent {
  const WalletTransactionsAssetFilterChanged(this.assetSymbol);

  /// Pass null to clear the filter.
  final String? assetSymbol;
}

class WalletTransactionsLoadMoreRequested extends WalletEvent {
  const WalletTransactionsLoadMoreRequested();
}

class WalletTransactionsRefreshRequested extends WalletEvent {
  const WalletTransactionsRefreshRequested();
}

/// Banks
class WalletBanksLoadRequested extends WalletEvent {
  const WalletBanksLoadRequested();
}

class WalletBanksLoadMoreRequested extends WalletEvent {
  const WalletBanksLoadMoreRequested();
}

/// Deposit Submission
class WalletDepositSubmitted extends WalletEvent {
  const WalletDepositSubmitted(this.params);
  final WalletDepositParams params;
}

class WalletDepositFeesRequested extends WalletEvent {
  const WalletDepositFeesRequested({
    required this.bankId,
    required this.currencyId,
    required this.amount,
  });
  final String bankId;
  final String currencyId;
  final double amount;
}

/// Media Upload
class WalletImageUploadRequested extends WalletEvent {
  const WalletImageUploadRequested(this.imageFile);
  final File imageFile;
}

class WalletImageResetRequested extends WalletEvent {
  const WalletImageResetRequested();
}

/// KYC Status (current verification decision from the backend).
/// Fetched on app launch and with every refresh.
class WalletKycStatusRequested extends WalletEvent {
  const WalletKycStatusRequested();
}

/// KYC Current (verified record details). Requested on entering settings,
/// only when the user is verified.
class WalletKycCurrentRequested extends WalletEvent {
  const WalletKycCurrentRequested();
}

/// KYC Session (start a single-use onboarding session → sessionId + expiresAt)
class WalletKycSessionStartRequested extends WalletEvent {
  const WalletKycSessionStartRequested();
}

class WalletKycSessionResetRequested extends WalletEvent {
  const WalletKycSessionResetRequested();
}

/// KYC ID Analyze (front/back)
class WalletKycAnalyzeIdRequested extends WalletEvent {
  const WalletKycAnalyzeIdRequested({
    required this.imagePath,
    required this.side,
    this.sessionHint,
  });

  final String imagePath;
  final String side; // front | back
  final String? sessionHint;
}

class WalletKycAnalyzeIdResetRequested extends WalletEvent {
  const WalletKycAnalyzeIdResetRequested();
}

/// KYC Liveness Detection
class WalletKycLivenessRequested extends WalletEvent {
  const WalletKycLivenessRequested({
    required this.faceImageData,
    required this.challengeStep,
  });

  final String faceImageData;
  final String challengeStep;
}

class WalletKycLivenessResetRequested extends WalletEvent {
  const WalletKycLivenessResetRequested();
}

/// KYC Compare Face (selfie vs ID)
class WalletKycCompareFaceRequested extends WalletEvent {
  const WalletKycCompareFaceRequested({
    required this.selfieImageData,
    required this.idFaceImageData,
  });

  final String selfieImageData;
  final String idFaceImageData;
}

class WalletKycCompareFaceResetRequested extends WalletEvent {
  const WalletKycCompareFaceResetRequested();
}

class BalanceCardIsSelected extends WalletEvent {
  final bool isSelected;
  final String? assetId;
  final String? assetSymbol;
  final String? assetType;
  const BalanceCardIsSelected({
    required this.isSelected,
    this.assetId,
    this.assetSymbol,
    this.assetType,
  });
}

class WalletDepositRequestsRequested extends WalletEvent {
  const WalletDepositRequestsRequested({this.page = 0, this.limit = 10});
  final int page;
  final int limit;
}

class WalletTransferPurposesLoadRequested extends WalletEvent {
  const WalletTransferPurposesLoadRequested();
}

/// Payment Requests
class WalletPaymentRequestCreated extends WalletEvent {
  const WalletPaymentRequestCreated({
    required this.accountNumber,
    required this.assetType,
    required this.assetSymbol,
    required this.amount,
    required this.purposeId,
    required this.reference,
    this.note,
    this.expiryMinutes,
    required this.isPermanent,
    required this.idempotencyKey,
  });

  final String accountNumber;
  final String assetType;
  final String assetSymbol;
  final double amount;
  final String purposeId;
  final String reference;
  final String? note;
  final int? expiryMinutes;
  final bool isPermanent;
  final String idempotencyKey;
}
