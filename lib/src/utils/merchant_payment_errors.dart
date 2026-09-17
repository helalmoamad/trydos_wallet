import '../api/api_client.dart';

/// What went wrong, in terms the payment screens can act on.
enum MerchantPaymentFailure {
  /// The code does not resolve. Ask the customer to check it with the shop.
  invalidCode,

  /// Throttled: 10 failed lookups in 15 minutes. Stop retrying.
  tooManyAttempts,

  /// Already paid, expired or cancelled — the request cannot be paid.
  notPayable,

  /// The customer has not completed identity verification. Route them into
  /// verification rather than showing a failure.
  kycRequired,

  /// This request is reserved for the customer it was issued for.
  payerNotAllowed,

  /// A 403 whose reason the backend did not spell out in `code`. Show the
  /// server's own message, which is already localized.
  forbidden,

  /// Not enough money in the paying wallet.
  insufficientBalance,

  /// Someone got there first, or the request stopped being payable. Refresh and
  /// show the current state — this is not the customer's mistake.
  alreadyPaid,

  /// No response came back at all.
  ///
  /// **Not an error to display.** The payment may well have gone through, so
  /// the caller retries with the same idempotency key and reconciles with a
  /// lookup before telling the customer anything.
  noResponse,

  /// Anything else. Show the server's message if there is one.
  unknown,
}

/// Maps an [ApiResult] failure onto a [MerchantPaymentFailure].
///
/// The `code` in a `{ statusCode, code, message }` body decides, and the HTTP
/// status is the fallback. The `message` is never matched against — it is prose
/// the backend localizes per `Accept-Language`, so branching on it would break
/// the moment a customer switches language.
abstract class MerchantPaymentErrors {
  MerchantPaymentErrors._();

  static const Set<String> _kycCodes = {
    'KYC_REQUIRED',
    'KYC_NOT_VERIFIED',
    'KYC_VERIFICATION_REQUIRED',
    'USER_NOT_VERIFIED',
    'IDENTITY_NOT_VERIFIED',
  };

  static const Set<String> _payerNotAllowedCodes = {
    'PAYER_NOT_ALLOWED',
    'PAYER_MISMATCH',
    'NOT_THE_INTENDED_PAYER',
    'FORBIDDEN_PAYER',
  };

  static const Set<String> _insufficientBalanceCodes = {
    'INSUFFICIENT_BALANCE',
    'INSUFFICIENT_FUNDS',
    'BALANCE_TOO_LOW',
  };

  static const Set<String> _alreadyPaidCodes = {
    'ALREADY_PAID',
    'PAYMENT_REQUEST_ALREADY_PAID',
    'REQUEST_ALREADY_FULFILLED',
    'CONFLICT',
  };

  static const Set<String> _notPayableCodes = {
    'NOT_PAYABLE',
    'PAYMENT_REQUEST_NOT_PAYABLE',
    'REQUEST_EXPIRED',
    'REQUEST_CANCELLED',
  };

  static const Set<String> _notFoundCodes = {
    'PAYMENT_REQUEST_NOT_FOUND',
    'MERCHANT_PAYMENT_NOT_FOUND',
    'NOT_FOUND',
    'INVALID_CODE',
  };

  static const Set<String> _throttledCodes = {
    'TOO_MANY_REQUESTS',
    'RATE_LIMITED',
    'THROTTLED',
  };

  /// Classifies a failed lookup.
  static MerchantPaymentFailure classifyLookup(ApiResult<Object?> result) {
    if (result.isTimeoutOrConnectionLoss) {
      return MerchantPaymentFailure.noResponse;
    }

    final code = _normalizeCode(result.errorCode);
    if (code != null) {
      if (_throttledCodes.contains(code)) {
        return MerchantPaymentFailure.tooManyAttempts;
      }
      if (_notFoundCodes.contains(code)) {
        return MerchantPaymentFailure.invalidCode;
      }
      if (_notPayableCodes.contains(code)) {
        return MerchantPaymentFailure.notPayable;
      }
    }

    switch (result.statusCode) {
      case 404:
        return MerchantPaymentFailure.invalidCode;
      case 429:
        return MerchantPaymentFailure.tooManyAttempts;
      case 410:
        return MerchantPaymentFailure.notPayable;
      default:
        return MerchantPaymentFailure.unknown;
    }
  }

  /// Classifies a failed payment.
  static MerchantPaymentFailure classifyPayment(ApiResult<Object?> result) {
    if (result.isTimeoutOrConnectionLoss) {
      return MerchantPaymentFailure.noResponse;
    }

    final code = _normalizeCode(result.errorCode);
    if (code != null) {
      if (_kycCodes.contains(code)) return MerchantPaymentFailure.kycRequired;
      if (_payerNotAllowedCodes.contains(code)) {
        return MerchantPaymentFailure.payerNotAllowed;
      }
      if (_insufficientBalanceCodes.contains(code)) {
        return MerchantPaymentFailure.insufficientBalance;
      }
      if (_alreadyPaidCodes.contains(code)) {
        return MerchantPaymentFailure.alreadyPaid;
      }
      if (_notPayableCodes.contains(code)) {
        return MerchantPaymentFailure.notPayable;
      }
      if (_throttledCodes.contains(code)) {
        return MerchantPaymentFailure.tooManyAttempts;
      }
    }

    switch (result.statusCode) {
      case 400:
        return MerchantPaymentFailure.insufficientBalance;
      case 403:
        // Both "verify your identity" and "this is not your request" are 403,
        // and only `code` separates them. With no code, defer to the server's
        // own message instead of guessing at a KYC redirect.
        return MerchantPaymentFailure.forbidden;
      case 404:
        return MerchantPaymentFailure.invalidCode;
      case 409:
        return MerchantPaymentFailure.alreadyPaid;
      case 429:
        return MerchantPaymentFailure.tooManyAttempts;
      default:
        return MerchantPaymentFailure.unknown;
    }
  }

  static String? _normalizeCode(String? code) {
    final normalized = (code ?? '').trim().toUpperCase().replaceAll('-', '_');
    return normalized.isEmpty ? null : normalized;
  }

  /// Localization key for the copy to show, or null when the failure has no
  /// fixed wording — [MerchantPaymentFailure.forbidden] and
  /// [MerchantPaymentFailure.unknown] show the server's message instead, and
  /// [MerchantPaymentFailure.noResponse] shows nothing at all.
  static String? messageKey(MerchantPaymentFailure failure) {
    switch (failure) {
      case MerchantPaymentFailure.invalidCode:
        return 'merchant_error_invalid_code';
      case MerchantPaymentFailure.tooManyAttempts:
        return 'merchant_error_too_many_attempts';
      case MerchantPaymentFailure.notPayable:
        return 'merchant_error_not_payable';
      case MerchantPaymentFailure.kycRequired:
        return 'merchant_error_kyc_required';
      case MerchantPaymentFailure.payerNotAllowed:
        return 'merchant_error_payer_not_allowed';
      case MerchantPaymentFailure.insufficientBalance:
        return 'merchant_error_insufficient_balance';
      case MerchantPaymentFailure.alreadyPaid:
        return 'merchant_error_already_paid';
      case MerchantPaymentFailure.forbidden:
      case MerchantPaymentFailure.unknown:
      case MerchantPaymentFailure.noResponse:
        return null;
    }
  }
}
