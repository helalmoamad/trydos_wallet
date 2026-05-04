/// Central API path constants.
abstract class ApiPaths {
  ApiPaths._();

  // ─── Currencies ───
  /// Currencies list with filter and search (GET).
  static const String currencies = '/assets/supported';

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

  // ─── KYC ───
  /// Analyze front/back ID image (POST).
  /// Body: imageData (data URL), side (front|back), sessionHint?
  static const String kycAnalyzeId = '/api/kyc/analyze-id';

  /// Liveness detection with selfie (POST).
  /// Body: faceImageData (data URL), challengeStep, crop
  static const String kycLiveness = '/api/kyc/liveness';

  /// Compare selfie against ID face image (POST).
  /// Body: selfieImageData (data URL), idFaceImageData (data URL)
  static const String kycCompareFace = '/api/kyc/compare-face';

  /// AWS liveness session lifecycle (POST create session, GET result by sessionId).
  static const String kycAwsLiveness = '/api/kyc/liveness-aws';

  /// AWS liveness temporary credentials (GET).
  static const String kycAwsLivenessCredentials =
      '/api/kyc/liveness-credentials';

  // ─── Payment Requests ───
  /// Create payment request (POST).
  /// Body: accountNumber, assetType, assetSymbol, amount, purposeId, reference, note?, expiryMinutes?, isPermanent, idempotencyKey
  static const String paymentRequests = '/payment-requests';

  /// Lookup payment request by request code.
  static String lookupPaymentRequest(String code) =>
      '/payment-requests/lookup/${Uri.encodeComponent(code)}';

  /// Fulfill payment request (pay).
  /// Body: accountNumber, idempotencyKey, note?
  static String fulfillPaymentRequest(String id) =>
      '/payment-requests/${Uri.encodeComponent(id)}/fulfill';
}
