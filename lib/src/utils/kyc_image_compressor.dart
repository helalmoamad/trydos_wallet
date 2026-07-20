import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Max size (in raw JPEG bytes) for a single KYC image sent to the worker.
///
/// The integration guide asks for base64 data URLs of ~1–2 MB (AWS hard limit
/// ~5 MB); oversized uploads make the worker fail the submit pipeline with
/// `502 {"error":"Failed to upload verification documents."}`. Base64 inflates
/// bytes by ~33%, so 800 KB raw ≈ 1.07 MB on the wire — comfortably inside.
const int kKycMaxImageBytes = 800 * 1024;

/// Longest edge kept when an image has to be downscaled.
const int _kMaxDimension = 1600;

class _KycCompressArgs {
  const _KycCompressArgs(this.bytes, this.maxBytes);

  final Uint8List bytes;
  final int maxBytes;
}

/// Runs off the UI thread (see [compute]): downscale, then step JPEG quality
/// down until the encoded image fits [maxBytes].
Uint8List _compressInIsolate(_KycCompressArgs args) {
  var decoded = img.decodeImage(args.bytes);
  if (decoded == null) return args.bytes;

  if (decoded.width > _kMaxDimension || decoded.height > _kMaxDimension) {
    decoded = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: _kMaxDimension)
        : img.copyResize(decoded, height: _kMaxDimension);
  }

  for (final quality in <int>[85, 75, 65, 55, 45]) {
    final encoded = Uint8List.fromList(
      img.encodeJpg(decoded, quality: quality),
    );
    if (encoded.length <= args.maxBytes) return encoded;
  }

  // Still too large → halve the dimensions once more at low quality.
  final smaller = img.copyResize(
    decoded,
    width: (decoded.width / 2).round().clamp(1, decoded.width),
  );
  return Uint8List.fromList(img.encodeJpg(smaller, quality: 45));
}

/// Shrinks a `data:image/...;base64,...` URL so it stays under [maxBytes].
///
/// Returns the input unchanged when it is already small enough, cannot be
/// decoded, or compression wouldn't help — compression must never block a
/// submit.
Future<String> compressKycImageDataUrl(
  String dataUrl, {
  int maxBytes = kKycMaxImageBytes,
}) async {
  if (dataUrl.isEmpty) return dataUrl;
  try {
    final commaIndex = dataUrl.indexOf(',');
    final base64Part = commaIndex >= 0
        ? dataUrl.substring(commaIndex + 1)
        : dataUrl;
    if (base64Part.isEmpty) return dataUrl;

    final bytes = base64Decode(base64Part);
    if (bytes.length <= maxBytes) return dataUrl;

    final compressed = await compute(
      _compressInIsolate,
      _KycCompressArgs(bytes, maxBytes),
    );
    if (compressed.length >= bytes.length) return dataUrl;

    if (kDebugMode) {
      debugPrint(
        '[KYC] image compressed: ${bytes.length ~/ 1024}KB → '
        '${compressed.length ~/ 1024}KB',
      );
    }
    return 'data:image/jpeg;base64,${base64Encode(compressed)}';
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[KYC] image compression skipped: $e');
    }
    return dataUrl;
  }
}
