/// Common events for API-backed Bloc (paginated).
sealed class ApiEvent {
  const ApiEvent();
}

/// Load data from API.
final class ApiLoadRequested extends ApiEvent {
  const ApiLoadRequested();
}

/// Refresh data (pull-to-refresh or Refresh button).
final class ApiRefreshRequested extends ApiEvent {
  const ApiRefreshRequested();
}

/// Load more when reaching scroll end (pagination).
final class ApiLoadMoreRequested extends ApiEvent {
  const ApiLoadMoreRequested();
}
