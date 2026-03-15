/// Central API path constants.
abstract class ApiPaths {
  ApiPaths._();

  // ─── Currencies ───
  /// Currencies list with filter and search (GET).
  static const String currencies = '/currencies';

  // ─── Transactions ───
  /// Wallet transactions (cursor pagination).
  static const String myTransactions = '/financial-ledger';

  // ─── Balances ───
  /// Wallet balance for specific currency.
  /// Query: accountSubtype (MAIN/TRADING), assetType (CURRENCY/METAL)
  static String balance(String assetId) => '/wallets/my/balances/$assetId';

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
