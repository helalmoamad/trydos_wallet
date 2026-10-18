import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'payment_code.dart';

/// Prefix that identifies a payment-request QR payload.
///
/// Example QR string:
///   `PAYREQ:pr.88DqTiedSJmUbIKA-SmSkA|0000-0038`
const String kPayreqPrefix = 'PAYREQ:';

/// Reads and writes the payment-request QR payload.
///
/// **Layout**, the same one the web wallet produces:
/// ```
/// PAYREQ:{requestCode}|{accountNumber}
/// ```
///
/// ### Write side (requester / receive screen)
/// ```dart
/// final qr = PaymentRequestCrypto.build(requestCode, myAccountNumber);
/// ```
///
/// ### Read side (payer / send screen after scan)
/// ```dart
/// final code = PaymentRequestCrypto.readCode(scannedQrString);
/// ```
///
/// ## The legacy encrypted body
///
/// This wallet used to put an AES-256-GCM blob where the code now sits —
/// `PAYREQ:{base64(iv[12] + ciphertext + tag[16])}|{accountNumber}` — while the
/// web wallet wrote the code in the clear. The two could not read each other:
/// base64-decoding `pr.…` throws, so a web QR failed the scan outright.
///
/// They are unified on the web's plain form. The encryption bought nothing to
/// begin with: its key was derived from the account number, which travels in
/// plaintext in the very same string, so anyone able to scan the QR could also
/// decrypt it.
///
/// [readCode] still accepts the old encrypted body, so QRs already printed,
/// screenshotted or shared keep working.
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

  /// Builds the QR string this wallet renders:
  ///   `PAYREQ:{requestCode}|{accountNumber}`
  ///
  /// Byte-for-byte what the web wallet produces for the same request.
  static String build(String requestCode, String accountNumber) =>
      '$kPayreqPrefix${requestCode.trim()}|${accountNumber.trim()}';

  /// Reads the request code out of a scanned PAYREQ payload.
  ///
  /// Accepts both bodies: the plain code this wallet and the web now write, and
  /// the AES-GCM blob older wallet versions wrote. Returns null when the string
  /// carries no code at all.
  static String? readCode(String qrString) {
    final withoutPrefix = qrString.startsWith(kPayreqPrefix)
        ? qrString.substring(kPayreqPrefix.length)
        : qrString;

    final pipeIdx = withoutPrefix.lastIndexOf('|');
    if (pipeIdx < 0) return null;

    final body = withoutPrefix.substring(0, pipeIdx).trim();
    final accountNumber = withoutPrefix.substring(pipeIdx + 1).trim();
    if (body.isEmpty || accountNumber.isEmpty) return null;

    // A plain code is never valid base64 (`pr.` alone makes decoding throw),
    // and a GCM tag makes a false positive on the other side implausible, so
    // trying the legacy path first tells the two apart with no ambiguity.
    final decrypted = decrypt(qrString);
    if (decrypted != null && decrypted.isNotEmpty) {
      return decrypted;
    }

    // Not the legacy blob. Hand back the body only if it is a code the lookup
    // endpoint can route; a corrupted or foreign payload must be refused here
    // rather than spend one of the ten wrong-code attempts allowed per quarter
    // hour — see [PaymentCode.isResolvable].
    return PaymentCode.isResolvable(body) ? PaymentCode.normalize(body) : null;
  }

  /// Encrypts [requestCode] using AES-256-GCM.
  ///
  /// **Legacy.** Kept to produce payloads in the old format — nothing in the
  /// app writes one any more; [build] does. See the class doc for why the
  /// encryption was dropped.
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

  /// Decrypts a legacy `PAYREQ:{base64}|{accountNumber}` QR string.
  ///
  /// Prefer [readCode], which handles this and the plain form. Returns the
  /// original request code, or `null` if:
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
