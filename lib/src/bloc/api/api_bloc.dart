import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/api.dart';
import '../../models/paginated_response.dart';

import 'api_event.dart';
import 'api_state.dart';

/// نوع الدالة التي تجلب بيانات من API (paginated).
typedef ApiFetcher<T> =
    Future<ApiResult<PaginatedResponse<T>>> Function(int page, int limit);

/// Bloc عام لإدارة بيانات API مع pagination.
/// يُستخدم مع أي API يرجع [PaginatedResponse].
class PaginatedApiBloc<T> extends Bloc<ApiEvent, ApiState<T>> {
  PaginatedApiBloc({
    required ApiFetcher<T> fetcher,
    this.limit = 10,
    this.defaultErrorMessage = 'فشل تحميل البيانات',
  }) : _fetcher = fetcher,
       super(const ApiInitial()) {
    on<ApiLoadRequested>(_onLoadRequested);
    on<ApiRefreshRequested>(_onRefreshRequested);
    on<ApiLoadMoreRequested>(_onLoadMoreRequested);
  }

  final ApiFetcher<T> _fetcher;
  final int limit;
  final String defaultErrorMessage;

  int _currentPage = 0;

  Future<void> _onLoadRequested(
    ApiLoadRequested event,
    Emitter<ApiState<T>> emit,
  ) async {
    emit(const ApiLoading());
    _currentPage = 0;
    await _fetch(emit, page: 0, append: false);
  }

  Future<void> _onRefreshRequested(
    ApiRefreshRequested event,
    Emitter<ApiState<T>> emit,
  ) async {
    emit(const ApiLoading());
    _currentPage = 0;
    await _fetch(emit, page: 0, append: false);
  }

  Future<void> _onLoadMoreRequested(
    ApiLoadMoreRequested event,
    Emitter<ApiState<T>> emit,
  ) async {
    final state = this.state;
    if (state is! ApiLoaded<T> || !state.hasNext || state.isLoadingMore) {
      return;
    }

    emit(
      ApiLoaded<T>(
        items: state.items,
        hasNext: state.hasNext,
        isLoadingMore: true,
      ),
    );

    await _fetch(
      emit,
      page: _currentPage + 1,
      append: true,
      previousItems: state.items,
    );
  }

  Future<void> _fetch(
    Emitter<ApiState<T>> emit, {
    required int page,
    required bool append,
    List<T> previousItems = const [],
  }) async {
    try {
      final result = await _fetcher(page, limit);
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        _currentPage = data.page;
        final items = append ? [...previousItems, ...data.items] : data.items;
        emit(
          ApiLoaded<T>(
            items: items,
            hasNext: data.hasNext,
            isLoadingMore: false,
          ),
        );
      } else {
        if (append) {
          emit(
            ApiLoaded<T>(
              items: previousItems,
              hasNext: false,
              isLoadingMore: false,
            ),
          );
        } else {
          emit(ApiError<T>(result.error?.message ?? defaultErrorMessage));
        }
      }
    } catch (e) {
      if (append) {
        final state = this.state;
        if (state is ApiLoaded<T>) {
          emit(
            ApiLoaded<T>(
              items: state.items,
              hasNext: state.hasNext,
              isLoadingMore: false,
            ),
          );
        }
      } else {
        emit(ApiError<T>(defaultErrorMessage));
      }
    }
  }
}
