/// أحداث عامة لأي Bloc يستدعي API (paginated).
sealed class ApiEvent {
  const ApiEvent();
}

/// تحميل البيانات من API.
final class ApiLoadRequested extends ApiEvent {
  const ApiLoadRequested();
}

/// إعادة تحميل البيانات (سحب للتحديث أو زر Refresh).
final class ApiRefreshRequested extends ApiEvent {
  const ApiRefreshRequested();
}

/// تحميل المزيد عند الوصول لنهاية السكرول (pagination).
final class ApiLoadMoreRequested extends ApiEvent {
  const ApiLoadMoreRequested();
}
