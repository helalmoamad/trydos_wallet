/// حالات عامة لأي Bloc يستدعي API (paginated).
sealed class ApiState<T> {
  const ApiState();
}

/// الحالة الأولية - لم يُطلب التحميل بعد.
final class ApiInitial<T> extends ApiState<T> {
  const ApiInitial();
}

/// جارٍ تحميل البيانات.
final class ApiLoading<T> extends ApiState<T> {
  const ApiLoading();
}

/// تم تحميل البيانات بنجاح.
final class ApiLoaded<T> extends ApiState<T> {
  const ApiLoaded({
    required this.items,
    this.hasNext = false,
    this.isLoadingMore = false,
  });

  final List<T> items;
  final bool hasNext;
  final bool isLoadingMore;
}

/// فشل التحميل.
final class ApiError<T> extends ApiState<T> {
  const ApiError(this.message);
  final String message;
}
