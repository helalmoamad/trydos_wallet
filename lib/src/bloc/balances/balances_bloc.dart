import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/models.dart';
import '../../services/balances_api_service.dart';

/// حدث طلب رصيد عملة (عند الضغط على البطاقة).
final class BalanceLoadRequested {
  const BalanceLoadRequested(this.assetId);
  final String assetId;
}

/// Balances state: Map for storage, Set for loading IDs.
final class BalancesState {
  const BalancesState({
    this.balances = const {},
    this.loadingIds = const {},
  });

  final Map<String, Balance> balances;
  final Set<String> loadingIds;

  Balance? balance(String assetId) => balances[assetId];
  bool isLoading(String assetId) => loadingIds.contains(assetId);

  BalancesState copyWith({
    Map<String, Balance>? balances,
    Set<String>? loadingIds,
  }) =>
      BalancesState(
        balances: balances ?? this.balances,
        loadingIds: loadingIds ?? this.loadingIds,
      );
}

/// Bloc لإدارة أرصدة العملات (Map لحفظ القيم عند التنقل).
class BalancesBloc extends Bloc<BalanceLoadRequested, BalancesState> {
  BalancesBloc({BalancesApiService? api})
      : _api = api ?? BalancesApiService(),
        super(const BalancesState()) {
    on<BalanceLoadRequested>(_onBalanceLoadRequested);
  }

  final BalancesApiService _api;

  Future<void> _onBalanceLoadRequested(
    BalanceLoadRequested event,
    Emitter<BalancesState> emit,
  ) async {
    final assetId = event.assetId;
    emit(state.copyWith(
      loadingIds: {...state.loadingIds, assetId},
    ));

    final result = await _api.getBalance(assetId);

    final newLoadingIds = {...state.loadingIds}..remove(assetId);

    if (result.isSuccess && result.data != null) {
      final newBalances = Map<String, Balance>.from(state.balances)
        ..[assetId] = result.data!;
      emit(state.copyWith(
        balances: newBalances,
        loadingIds: newLoadingIds,
      ));
    } else {
      emit(state.copyWith(loadingIds: newLoadingIds));
    }
  }
}
