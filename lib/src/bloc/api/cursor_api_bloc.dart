import 'package:flutter_bloc/flutter_bloc.dart';

import '../../api/api.dart';
import '../../models/cursor_paginated_response.dart';

import 'api_event.dart';
import 'api_state.dart';

/// نوع الدالة التي تجلب بيانات cursor-paginated.
typedef CursorApiFetcher<T> = Future<ApiResult<CursorPaginatedResponse<T>>>
    Function(String? cursor, int limit);

/// Bloc عام لـ API مع cursor-based pagination.
class CursorPaginatedApiBloc<T> extends Bloc<ApiEvent, ApiState<T>> {
  CursorPaginatedApiBloc({
    required CursorApiFetcher<T> fetcher,
    this.limit = 10,
    this.defaultErrorMessage = 'Failed to load data',
  })  : _fetcher = fetcher,
        super(const ApiInitial()) {
    on<ApiLoadRequested>(_onLoadRequested);
    on<ApiRefreshRequested>(_onRefreshRequested);
    on<ApiLoadMoreRequested>(_onLoadMoreRequested);
  }

  final CursorApiFetcher<T> _fetcher;
  final int limit;
  final String defaultErrorMessage;

  String? _nextCursor;

  Future<void> _onLoadRequested(
    ApiLoadRequested event,
    Emitter<ApiState<T>> emit,
  ) async {
    emit(const ApiLoading());
    _nextCursor = null;
    await _fetch(emit, cursor: null, append: false);
  }

  Future<void> _onRefreshRequested(
    ApiRefreshRequested event,
    Emitter<ApiState<T>> emit,
  ) async {
    emit(const ApiLoading());
    _nextCursor = null;
    await _fetch(emit, cursor: null, append: false);
  }

  Future<void> _onLoadMoreRequested(
    ApiLoadMoreRequested event,
    Emitter<ApiState<T>> emit,
  ) async {
    final state = this.state;
    if (state is! ApiLoaded<T> || !state.hasNext || state.isLoadingMore) {
      return;
    }
    if (_nextCursor == null) return;

    emit(
      ApiLoaded<T>(
        items: state.items,
        hasNext: state.hasNext,
        isLoadingMore: true,
      ),
    );

    await _fetch(
      emit,
      cursor: _nextCursor,
      append: true,
      previousItems: state.items,
    );
  }

  Future<void> _fetch(
    Emitter<ApiState<T>> emit, {
    required String? cursor,
    required bool append,
    List<T> previousItems = const [],
  }) async {
    try {
      final result = await _fetcher(cursor, limit);
      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        _nextCursor = data.hasNextPage ? data.endCursor : null;
        final items = append ? [...previousItems, ...data.items] : data.items;
        emit(
          ApiLoaded<T>(
            items: items,
            hasNext: data.hasNextPage,
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
          emit(
            ApiError<T>(result.error?.message ?? defaultErrorMessage),
          );
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
