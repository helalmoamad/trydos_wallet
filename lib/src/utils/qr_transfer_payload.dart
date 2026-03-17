import 'dart:convert';

class QrTransferPayload {
  const QrTransferPayload({
    required this.accountNumber,
    this.accountName,
    this.currencySymbol,
    this.amount,
    this.reference,
    this.purpose,
    this.requestType,
    this.expiryTime,
    this.note,
  });

  final String accountNumber;
  final String? accountName;
  final String? currencySymbol;
  final String? amount;
  final String? reference;
  final String? purpose;
  final String? requestType;
  final DateTime? expiryTime;
  final String? note;

  bool get isRequestFlow =>
      (amount != null && amount!.trim().isNotEmpty) ||
      (reference != null && reference!.trim().isNotEmpty) ||
      (purpose != null && purpose!.trim().isNotEmpty) ||
      expiryTime != null;
}

class QrTransferPayloadCodec {
  static String buildReceivePayload({
    required String accountNumber,
    required String accountName,
    required String currencySymbol,
  }) {
    return _toQueryString(<String, String?>{
      'ana': accountName,
      'anu': accountNumber,
      'cu': currencySymbol,
    });
  }

  static String buildRequestPayload({
    required String accountNumber,
    required String accountName,
    required String currencySymbol,
    required String amount,
    required String reference,
    required String purpose,
    required String requestType,
    DateTime? expiryTime,
    String? note,
  }) {
    return _toQueryString(<String, String?>{
      'ana': accountName,
      'anu': accountNumber,
      'cu': currencySymbol,
      'am': amount,
      'rf': reference,
      'pu': purpose,
      'ty': requestType,
      'ex': expiryTime?.toUtc().toIso8601String(),
      'nt': note,
      'fl': 'request',
    });
  }

  static String buildTransferResultPayload({
    required String senderAccount,
    required String recipientAccount,
    required String amount,
    required String currencySymbol,
    required String reference,
    required String dateAndTime,
    required String transferType,
    required String purpose,
    required bool isSuccess,
  }) {
    return _toQueryString(<String, String?>{
      'sa': senderAccount,
      'ra': recipientAccount,
      'am': amount,
      'cu': currencySymbol,
      'rf': reference,
      'dt': dateAndTime,
      'ty': transferType,
      'pu': purpose,
      'st': isSuccess ? 'succeeded' : 'failed',
      'fl': 'transfer_result',
    });
  }

  static QrTransferPayload? tryParse(String raw) {
    final content = raw.trim();
    if (content.isEmpty) {
      return null;
    }

    final fromJson = _tryParseJson(content);
    if (fromJson != null) {
      return fromJson;
    }

    return _tryParseQueryString(content);
  }

  static QrTransferPayload? _tryParseJson(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map) {
        return null;
      }

      final map = decoded.map((key, value) => MapEntry(key.toString(), value));

      final accountNumber = _firstNonEmpty(map, const [
        'account_number',
        'accountNumber',
        'account_id',
        'anu',
      ]);
      if (accountNumber == null) {
        return null;
      }

      return QrTransferPayload(
        accountNumber: accountNumber,
        accountName: _firstNonEmpty(map, const [
          'account_name',
          'accountName',
          'ana',
        ]),
        currencySymbol: _firstNonEmpty(map, const [
          'currency_symbol',
          'currencySymbol',
          'currency',
          'cu',
        ]),
        amount: _firstNonEmpty(map, const ['amount', 'am']),
        reference: _firstNonEmpty(map, const ['reference', 'id', 'ref', 'rf']),
        purpose: _firstNonEmpty(map, const ['purpose', 'purpose_id', 'pu']),
        requestType: _firstNonEmpty(map, const ['type', 'flow', 'ty', 'fl']),
        expiryTime: _parseDate(
          _firstNonEmpty(map, const ['expiry_time', 'expiry', 'ex']),
        ),
        note: _firstNonEmpty(map, const ['note', 'nt']),
      );
    } catch (_) {
      return null;
    }
  }

  static QrTransferPayload? _tryParseQueryString(String content) {
    try {
      final map = _parseQueryStringLoosely(content);
      final accountNumber = _firstNonEmpty(map, const [
        'account_number',
        'accountNumber',
        'anu',
        'account_id',
      ]);
      if (accountNumber == null) {
        return null;
      }

      return QrTransferPayload(
        accountNumber: accountNumber,
        accountName: _firstNonEmpty(map, const ['account_name', 'ana']),
        currencySymbol: _firstNonEmpty(map, const ['currency_symbol', 'cu']),
        amount: _firstNonEmpty(map, const ['amount', 'am']),
        reference: _firstNonEmpty(map, const ['reference', 'id', 'ref', 'rf']),
        purpose: _firstNonEmpty(map, const ['purpose', 'pu']),
        requestType: _firstNonEmpty(map, const ['type', 'flow', 'ty', 'fl']),
        expiryTime: _parseDate(
          _firstNonEmpty(map, const ['expiry_time', 'expiry', 'ex']),
        ),
        note: _firstNonEmpty(map, const ['note', 'nt']),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value.toLowerCase() != 'null') {
        return value;
      }
    }
    return null;
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value)?.toLocal();
  }

  static String _toQueryString(Map<String, String?> values) {
    final parts = <String>[];
    values.forEach((key, value) {
      final v = value?.trim();
      if (v != null && v.isNotEmpty) {
        parts.add(
          '${Uri.encodeComponent(key)}=${_encodeValueKeepingSpaces(v)}',
        );
      }
    });
    return parts.join('&');
  }

  static String _encodeValueKeepingSpaces(String value) {
    return Uri.encodeComponent(value).replaceAll('%20', ' ');
  }

  static Map<String, String> _parseQueryStringLoosely(String query) {
    final result = <String, String>{};
    if (query.trim().isEmpty) {
      return result;
    }

    for (final part in query.split('&')) {
      if (part.isEmpty) {
        continue;
      }
      final eqIndex = part.indexOf('=');
      final rawKey = eqIndex == -1 ? part : part.substring(0, eqIndex);
      final rawValue = eqIndex == -1 ? '' : part.substring(eqIndex + 1);
      final key = Uri.decodeComponent(rawKey.replaceAll('+', ' '));
      final value = Uri.decodeComponent(rawValue.replaceAll('+', ' '));
      result[key] = value;
    }

    return result;
  }
}
