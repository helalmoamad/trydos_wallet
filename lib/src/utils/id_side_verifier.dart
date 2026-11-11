/// Checks that the back of an ID belongs to the front already captured.
///
/// The server reads each side independently and has no opinion on whether the
/// two came off the same card, so a user who photographs the back of a
/// different document gets all the way to submit before anything objects.
/// This catches it on the spot.
///
/// Rules, from the integration guide §6.7, evaluated in order — **the first
/// rule that applies is final**, and if none does the back is accepted:
///
/// 1. National number, digits only: both sides ≥ 8 digits ⇒ must be equal or
///    one edit apart.
/// 2. else document number, digits only: both ≥ 6 digits ⇒ same test.
/// 3. else last name, A–Z only: both ≥ 2 characters ⇒ same test.
/// 4. else accept — there was nothing comparable.
///
/// One edit of tolerance is deliberate: OCR confuses `0`/`O` and `1`/`I` often
/// enough that demanding an exact match would reject genuine cards.
library;

import '../models/kyc/kyc_analyze_id_response.dart';

/// Which field decided the verdict.
enum IdSideField { nationalNumber, documentNumber, lastName, none }

class IdSideVerdict {
  const IdSideVerdict({required this.matched, required this.field});

  /// False only when a comparable field disagreed by more than one edit.
  final bool matched;

  /// The field the decision rested on; [IdSideField.none] when nothing on the
  /// two sides could be compared and the back was accepted by default.
  final IdSideField field;

  bool get wasComparable => field != IdSideField.none;
}

/// Whether [back] plausibly belongs to the same document as [front].
IdSideVerdict verifyBackMatchesFront({
  required KycExtractedData front,
  required KycExtractedData back,
}) {
  final frontNational = _digits(front.nationalNumber);
  final backNational = _digits(back.nationalNumber);
  if (frontNational.length >= 8 && backNational.length >= 8) {
    return IdSideVerdict(
      matched: _withinOneEdit(frontNational, backNational),
      field: IdSideField.nationalNumber,
    );
  }

  final frontDocument = _digits(front.documentNumber);
  final backDocument = _digits(back.documentNumber);
  if (frontDocument.length >= 6 && backDocument.length >= 6) {
    return IdSideVerdict(
      matched: _withinOneEdit(frontDocument, backDocument),
      field: IdSideField.documentNumber,
    );
  }

  final frontLast = _letters(front.lastName);
  final backLast = _letters(back.lastName);
  if (frontLast.length >= 2 && backLast.length >= 2) {
    return IdSideVerdict(
      matched: _withinOneEdit(frontLast, backLast),
      field: IdSideField.lastName,
    );
  }

  // The back carried nothing shared with the front — common on cards whose
  // MRZ repeats neither the number nor the name. Rejecting here would block
  // valid documents, so the server stays the authority.
  return const IdSideVerdict(matched: true, field: IdSideField.none);
}

String _digits(String? value) =>
    (value ?? '').replaceAll(RegExp(r'[^0-9]'), '');

/// Uppercase A–Z only: accents are folded, and anything else — spaces, Arabic
/// script the server did not transliterate, punctuation — is dropped.
String _letters(String? value) {
  final upper = (value ?? '').toUpperCase();
  final folded = StringBuffer();
  for (final rune in upper.runes) {
    final char = String.fromCharCode(rune);
    folded.write(_accents[char] ?? char);
  }
  return folded.toString().replaceAll(RegExp(r'[^A-Z]'), '');
}

/// The Latin accents transliterated Turkish, Kurdish and European names
/// arrive with. Folded so `ÖZTÜRK` and `OZTURK` are the same name.
const Map<String, String> _accents = {
  'Á': 'A',
  'À': 'A',
  'Â': 'A',
  'Ä': 'A',
  'Ã': 'A',
  'Å': 'A',
  'Ā': 'A',
  'Ç': 'C',
  'Ć': 'C',
  'Č': 'C',
  'Ď': 'D',
  'Đ': 'D',
  'É': 'E',
  'È': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'Ē': 'E',
  'Ė': 'E',
  'Ę': 'E',
  'Ğ': 'G',
  'Í': 'I',
  'Ì': 'I',
  'Î': 'I',
  'Ï': 'I',
  'İ': 'I',
  'Ī': 'I',
  'Į': 'I',
  'Ñ': 'N',
  'Ń': 'N',
  'Ó': 'O',
  'Ò': 'O',
  'Ô': 'O',
  'Ö': 'O',
  'Õ': 'O',
  'Ø': 'O',
  'Ō': 'O',
  'Ř': 'R',
  'Ś': 'S',
  'Š': 'S',
  'Ş': 'S',
  'Ť': 'T',
  'Ú': 'U',
  'Ù': 'U',
  'Û': 'U',
  'Ü': 'U',
  'Ū': 'U',
  'Ů': 'U',
  'Ý': 'Y',
  'Ÿ': 'Y',
  'Ź': 'Z',
  'Ż': 'Z',
  'Ž': 'Z',
};

bool _withinOneEdit(String a, String b) {
  if (a == b) return true;
  return _levenshtein(a, b) <= 1;
}

/// Levenshtein distance, capped at 2.
///
/// Only "equal, one edit, or more" matters here, so the row is abandoned as
/// soon as every cell exceeds the cap rather than finishing the matrix.
int _levenshtein(String a, String b) {
  const cap = 2;
  if ((a.length - b.length).abs() > cap) return cap;

  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final current = List<int>.filled(b.length + 1, 0);
    current[0] = i;
    var rowMin = current[0];

    for (var j = 1; j <= b.length; j++) {
      final substitution = previous[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1);
      final deletion = previous[j] + 1;
      final insertion = current[j - 1] + 1;
      final best = substitution < deletion
          ? (substitution < insertion ? substitution : insertion)
          : (deletion < insertion ? deletion : insertion);
      current[j] = best;
      if (best < rowMin) rowMin = best;
    }

    if (rowMin > cap) return cap;
    previous = current;
  }

  final distance = previous[b.length];
  return distance > cap ? cap : distance;
}
