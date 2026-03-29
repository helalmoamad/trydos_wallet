import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// Prefix that identifies an encrypted payment-request QR payload.
///
/// Example QR string:
///   `PAYREQ:XIO91X37S5FHsxnjgTZ5c1oec4gsM6wfoC24N9uWmRqMKCkmOQJjswQ+sv4=|0000-0030`
const String kPayreqPrefix = 'PAYREQ:';

/// Utility class for encrypting / decrypting payment-request codes.
///
/// **Algorithm** : AES-256-GCM
/// **Key**       : requester's account number, UTF-8 encoded and null-padded /
///                 truncated to exactly 32 bytes (matches JS `padEnd(32,'\0').slice(0,32)`).
/// **IV**        : 12 cryptographically-random bytes, prepended to the cipher blob.
///
/// **QR payload layout** (identical to the JS implementation):
/// ```
/// PAYREQ:{base64(iv[12] + ciphertext + tag[16])}|{accountNumber}
/// ```
///
/// ### Encrypt side (requester / receive screen)
/// ```dart
/// final qr = PaymentRequestCrypto.encrypt(requestCode, myAccountNumber);
/// ```
///
/// ### Decrypt side (payer / send screen after scan)
/// ```dart
/// final code = PaymentRequestCrypto.decrypt(scannedQrString);
/// // code is the original requestCode, or null if parsing/decryption fails.
/// ```
class PaymentRequestCrypto {
  PaymentRequestCrypto._();

  static const int _ivLength = 12;
  static const int _keyLength = 32;
  static const int _tagBits = 128; // 16-byte GCM authentication tag

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Returns `true` when [qrString] uses the encrypted PAYREQ format.
  static bool isPayreqFormat(String qrString) =>
      qrString.startsWith(kPayreqPrefix);

  /// Extracts the account number embedded in a PAYREQ QR string.
  ///
  /// Returns `null` if the string is not a valid PAYREQ payload.
  static String? extractAccountNumber(String qrString) {
    final withoutPrefix = qrString.startsWith(kPayreqPrefix)
        ? qrString.substring(kPayreqPrefix.length)
        : qrString;
    final pipeIdx = withoutPrefix.lastIndexOf('|');
    if (pipeIdx < 0) return null;
    final account = withoutPrefix.substring(pipeIdx + 1).trim();
    return account.isEmpty ? null : account;
  }

  /// Encrypts [requestCode] using AES-256-GCM.
  ///
  /// [accountNumber] is the requester's account number and acts as the key
  /// (same convention as the JS `usePaymentRequestEncryption` hook).
  ///
  /// Returns the full QR string:
  ///   `PAYREQ:{base64(iv + ciphertext + tag)}|{accountNumber}`
  static String encrypt(String requestCode, String accountNumber) {
    final keyBytes = _deriveKey(accountNumber);
    final iv = _randomIv();
    final plaintext = Uint8List.fromList(utf8.encode(requestCode));

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(KeyParameter(keyBytes), _tagBits, iv, Uint8List(0)),
      );

    final output = Uint8List(cipher.getOutputSize(plaintext.length));
    var len = cipher.processBytes(plaintext, 0, plaintext.length, output, 0);
    len += cipher.doFinal(output, len);

    // Combine: iv (12 bytes) + ciphertext+tag (n+16 bytes)
    final combined = Uint8List(_ivLength + len);
    combined.setRange(0, _ivLength, iv);
    combined.setRange(_ivLength, combined.length, output.sublist(0, len));

    final b64 = base64.encode(combined);
    return '$kPayreqPrefix$b64|$accountNumber';
  }

  /// Decrypts a `PAYREQ:{base64}|{accountNumber}` QR string.
  ///
  /// Returns the original [requestCode], or `null` if:
  /// - the string is not a valid PAYREQ payload,
  /// - the base64 is malformed,
  /// - the GCM authentication tag fails (tampered / wrong key).
  static String? decrypt(String qrString) {
    try {
      final withoutPrefix = qrString.startsWith(kPayreqPrefix)
          ? qrString.substring(kPayreqPrefix.length)
          : qrString;

      final pipeIdx = withoutPrefix.lastIndexOf('|');
      if (pipeIdx < 0) return null;

      final b64 = withoutPrefix.substring(0, pipeIdx);
      final accountNumber = withoutPrefix.substring(pipeIdx + 1).trim();
      if (accountNumber.isEmpty) return null;

      final combined = base64.decode(b64);
      if (combined.length <= _ivLength) return null;

      final iv = combined.sublist(0, _ivLength);
      final encryptedBlob = combined.sublist(_ivLength);

      final keyBytes = _deriveKey(accountNumber);
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(KeyParameter(keyBytes), _tagBits, iv, Uint8List(0)),
        );

      final output = Uint8List(cipher.getOutputSize(encryptedBlob.length));
      var len = cipher.processBytes(
        encryptedBlob,
        0,
        encryptedBlob.length,
        output,
        0,
      );
      len += cipher.doFinal(output, len);

      return utf8.decode(output.sublist(0, len));
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Derives a 32-byte AES key from [accountNumber].
  ///
  /// Mirrors the JS: `new TextEncoder().encode(secret.padEnd(32,'\0').slice(0,32))`
  static Uint8List _deriveKey(String accountNumber) {
    final padded = accountNumber
        .padRight(_keyLength, '\x00')
        .substring(0, _keyLength);
    return Uint8List.fromList(utf8.encode(padded));
  }

  /// Generates a cryptographically secure random 12-byte IV.
  static Uint8List _randomIv() {
    final rng = Random.secure();
    return Uint8List.fromList(
      List.generate(_ivLength, (_) => rng.nextInt(256)),
    );
  }
}
