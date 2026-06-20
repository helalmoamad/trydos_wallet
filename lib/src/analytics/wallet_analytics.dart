import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Thin, crash-safe wrapper around the host-owned PostHog singleton.
///
/// IMPORTANT: the library NEVER calls `Posthog().setup()` — initialization and
/// `PostHogWidget` ownership belong to the host app. Here we only call the
/// already-initialized singleton's API. Every call is guarded so analytics can
/// never crash the wallet (e.g. if the host hasn't wired PostHog yet).
class WalletAnalytics {
  WalletAnalytics._();

  /// Record a screen view. Screen names use the `Wallet/...` namespace so they
  /// are easy to find in PostHog reports.
  static Future<void> screen(
    String name, {
    Map<String, Object>? properties,
  }) async {
    try {
      await Posthog().screen(screenName: name, properties: properties);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WalletAnalytics] screen("$name") skipped: $e');
      }
    }
  }

  /// Record a custom event (e.g. a completed transfer/deposit).
  static Future<void> capture(
    String eventName, {
    Map<String, Object>? properties,
  }) async {
    try {
      await Posthog().capture(eventName: eventName, properties: properties);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[WalletAnalytics] capture("$eventName") skipped: $e');
      }
    }
  }
}

/// Canonical screen names for the wallet, kept in one place so reports stay
/// consistent and renames are trivial.
abstract class WalletScreens {
  WalletScreens._();

  static const String home = 'Wallet/Home';
  static const String walletBalances = 'Wallet/Balances';
  static const String addresses = 'Wallet/Addresses';
  static const String settings = 'Wallet/Settings';
  static const String transactionDetails = 'Wallet/TransactionDetails';
  static const String send = 'Wallet/Send';
  static const String receive = 'Wallet/Receive';
  static const String qrScanner = 'Wallet/QrScanner';

  // KYC flow
  static const String kycStart = 'Wallet/KYC/Start';
  static const String kycMethods = 'Wallet/KYC/Methods';
  static const String kycIdentity = 'Wallet/KYC/IdentityVerification';
  static const String kycLiveness = 'Wallet/KYC/LiveFaceDetection';
  static const String kycFaceMatch = 'Wallet/KYC/IdMatching';
  static const String kycSuccess = 'Wallet/KYC/Success';

  // Custom events
  static const String eventTransferCompleted = 'wallet_transfer_completed';
  static const String eventDepositSubmitted = 'wallet_deposit_submitted';
  static const String eventKycSubmitted = 'wallet_kyc_submitted';
}
