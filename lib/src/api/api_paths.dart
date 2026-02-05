/// مسارات روابط API مركزية.
abstract class ApiPaths {
  ApiPaths._();

  // ─── Currencies ───
  /// قائمة العملات مع فلترة وبحث (GET).
  /// Query: page, limit, orderDirection, search
  static const String currencies = '/currencies';
}
