/// Central API path constants.
abstract class ApiPaths {
  ApiPaths._();

  // ─── Currencies ───
  /// Currencies list with filter and search (GET).
  static const String currencies = '/currencies';

  // ─── Transactions ───
  /// Wallet transactions (cursor pagination).
  static const String myTransactions = '/financial-ledger';

  // ─── Transfer Purposes ───
  /// Purposes used in send/request UI.
  /// Query: type (ALL/SEND/REQUEST)
  static const String transferPurpose = '/transfer-purpose';

  /// Lookup recipient account by full account number.
  static String lookupAccount(String accountNumber) =>
      '/transfers/lookup-account/$accountNumber';

  /// Verify transfer before sending.
  static const String verifyTransfer = '/transfers/verify';

  /// Execute transfer.
  static const String sendTransfer = '/transfers/send';

  // ─── Balances ───
  /// Wallet accounts and balances by currency symbol.
  /// Query: currencySymbol (e.g. USD)
  static const String myAccounts = '/wallets/myAcounts';

  // ─── Banks ───
  /// Banks list (GET).
  /// Query: page (0-indexed), limit (default: 10, max: 100)
  static const String banks = '/banks';

  // ─── Bank Deposits ───
  /// Calculate deposit fees (POST).
  /// Body: bankId, currencyId, amount
  static const String bankDepositsCalculateFees =
      '/bank-deposits/calculate-fees';

  /// Bank deposits - GET (list user requests) or POST (create).
  /// GET: Query page (0-indexed), limit (default: 10, max: 100)
  /// POST Body: bankId, currencyId, amount, transferImageUrl, transactionReference?, idempotencyKey
  static const String bankDeposits = '/bank-deposits';

  // ─── Media ───
  /// Direct file upload (POST multipart).
  /// Body: file (required), type (required), metadata (optional)
  static const String mediaUploadDirect = '/media/upload/direct';
}
