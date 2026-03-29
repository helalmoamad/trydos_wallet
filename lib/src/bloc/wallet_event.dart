import 'dart:io';

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

/// Balances
class WalletBalanceLoadRequested extends WalletEvent {
  const WalletBalanceLoadRequested(this.assetId);
  final String assetId;
}

/// Transactions
class WalletTransactionsLoadRequested extends WalletEvent {
  const WalletTransactionsLoadRequested();
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

class BalanceCardIsSelected extends WalletEvent {
  final bool isSelected;
  final String? assetId;
  const BalanceCardIsSelected({required this.isSelected, this.assetId});
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
