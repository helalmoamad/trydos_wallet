/// A shop-authored string that arrives in both languages: `{ en, ar }`.
///
/// Either side can be missing, so [resolve] falls back to the other language
/// rather than leaving an empty row on the confirmation screen — a customer
/// deciding whether to pay is better served by a description in the wrong
/// language than by no description at all.
///
/// The wallet also ships Kurdish and Turkish, which the shop never provides;
/// those users fall through to English and then Arabic.
class MerchantLocalizedText {
  const MerchantLocalizedText({this.en, this.ar});

  final String? en;
  final String? ar;

  static const MerchantLocalizedText empty = MerchantLocalizedText();

  bool get isEmpty => (en ?? '').trim().isEmpty && (ar ?? '').trim().isEmpty;
  bool get isNotEmpty => !isEmpty;

  factory MerchantLocalizedText.fromJson(dynamic json) {
    // Tolerate a plain string: a shop that sent one language only should not
    // blank out the description.
    if (json is String) {
      final text = json.trim();
      return text.isEmpty
          ? MerchantLocalizedText.empty
          : MerchantLocalizedText(en: text, ar: text);
    }
    if (json is! Map) return MerchantLocalizedText.empty;

    String? pick(dynamic value) {
      final text = value?.toString().trim() ?? '';
      return text.isEmpty ? null : text;
    }

    return MerchantLocalizedText(en: pick(json['en']), ar: pick(json['ar']));
  }

  /// The best available text for [languageCode].
  ///
  /// Returns an empty string only when the shop sent nothing at all.
  String resolve(String languageCode) {
    final wantsArabic = languageCode.trim().toLowerCase().startsWith('ar');
    final preferred = (wantsArabic ? ar : en)?.trim() ?? '';
    if (preferred.isNotEmpty) return preferred;
    return (wantsArabic ? en : ar)?.trim() ?? '';
  }

  Map<String, dynamic> toJson() => {'en': en, 'ar': ar};
}
