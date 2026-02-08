/// Common states for API-backed Bloc (paginated).
sealed class ApiState<T> {
  const ApiState();
}

/// Initial state - load not requested yet.
final class ApiInitial<T> extends ApiState<T> {
  const ApiInitial();
}

/// Loading data.
final class ApiLoading<T> extends ApiState<T> {
  const ApiLoading();
}

/// Data loaded successfully.
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

/// Load failed.
final class ApiError<T> extends ApiState<T> {
  const ApiError(this.message);
  final String message;
}
