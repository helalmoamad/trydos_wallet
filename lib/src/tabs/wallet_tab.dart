import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/bloc.dart';
import '../models/models.dart';
import '../services/banks_api_service.dart';
import '../styles.dart';
import '../widgets/widgets.dart';

/// My Wallet tab (balances and deposit).
class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  String? _selectedWalletCurrencyId;
  int _depositRequestsRefreshKey = 0;
  final ScrollController _currenciesScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _currenciesScrollController.addListener(_onCurrenciesScroll);
  }

  @override
  void dispose() {
    _currenciesScrollController.removeListener(_onCurrenciesScroll);
    _currenciesScrollController.dispose();
    super.dispose();
  }

  void _onCurrenciesScroll() {
    final bloc = context.read<PaginatedApiBloc<Currency>>();
    final state = bloc.state;
    if (state is! ApiLoaded<Currency> ||
        !state.hasNext ||
        state.isLoadingMore) {
      return;
    }
    final pos = _currenciesScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 50) {
      bloc.add(const ApiLoadMoreRequested());
    }
  }

  Future<void> _showDepositModal(BuildContext context, Currency currency) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BlocProvider<PaginatedApiBloc<Bank>>(
        create: (_) => PaginatedApiBloc<Bank>(
          fetcher: (page, limit) => BanksApiService().getBanks(
            page: page,
            limit: 10,
          ),
          defaultErrorMessage: 'Failed to load banks',
        )..add(const ApiLoadRequested()),
        child: DepositModal(currency: currency),
      ),
    );
    if (result == true && mounted) {
      setState(() => _depositRequestsRefreshKey++);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const WalletHeader(),
          const Padding(
            padding: EdgeInsets.only(top: 5, left: 24, right: 24),
            child: Divider(color: Color(0xffD3D3D3)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Wallet',
                  style: TrydosWalletStyles.headlineMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your balances and transactions',
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff8D8D8D),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            child: BlocBuilder<BalancesBloc, BalancesState>(
              buildWhen: (prev, curr) =>
                  prev.balances != curr.balances ||
                  prev.loadingIds != curr.loadingIds,
              builder: (context, balancesState) {
                return BlocBuilder<
                  PaginatedApiBloc<Currency>,
                  ApiState<Currency>
                >(
                  builder: (context, state) {
                    if (state is ApiInitial<Currency> ||
                        state is ApiLoading<Currency>) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is ApiError<Currency>) {
                      return Center(
                        child: TextButton(
                          onPressed: () => context
                              .read<PaginatedApiBloc<Currency>>()
                              .add(const ApiRefreshRequested()),
                          child: const Text('Retry'),
                        ),
                      );
                    }
                    final loadedState = state is ApiLoaded<Currency>
                        ? state
                        : null;
                    final currencies = loadedState?.items ?? <Currency>[];
                    final hasNext = loadedState?.hasNext ?? false;
                    final isLoadingMore = loadedState?.isLoadingMore ?? false;
                    if (currencies.isEmpty && !isLoadingMore) {
                      return const Center(child: Text('No currencies'));
                    }
                    if (_selectedWalletCurrencyId == null &&
                        currencies.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        setState(() {
                          _selectedWalletCurrencyId = currencies.first.id;
                          context.read<BalancesBloc>().add(
                            BalanceLoadRequested(currencies.first.id),
                          );
                        });
                      });
                    }
                    return ListView.builder(
                      controller: _currenciesScrollController,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: currencies.length + (hasNext ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == currencies.length) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: SizedBox(
                              width: 40,
                              child: isLoadingMore
                                  ? const Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }
                        final currency = currencies[index];
                        final isSelected =
                            _selectedWalletCurrencyId == currency.id;
                        final balance = balancesState.balance(currency.id);
                        final isLoadingBalance = balancesState.isLoading(
                          currency.id,
                        );
                        final amountStr = balance != null
                            ? balance.available.toStringAsFixed(
                                balance.available.truncateToDouble() ==
                                        balance.available
                                    ? 0
                                    : 2,
                              )
                            : '0';
                        return Padding(
                          padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
                          child: WalletBalanceCard(
                            currencyName: currency.displayName.isNotEmpty
                                ? currency.displayName
                                : currency.name,
                            currencyCode: currency.symbol,
                            amount: amountStr,
                            isSelected: isSelected,
                            isLoadingBalance: isLoadingBalance,
                            onTap: () {
                              context.read<BalancesBloc>().add(
                                BalanceLoadRequested(currency.id),
                              );
                              setState(
                                () => _selectedWalletCurrencyId = currency.id,
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<PaginatedApiBloc<Currency>, ApiState<Currency>>(
            builder: (context, state) {
              final currencies =
                  (state is ApiLoaded<Currency> ? state : null)?.items ??
                  <Currency>[];
              Currency? selectedCurrency;
              if (_selectedWalletCurrencyId != null) {
                for (final c in currencies) {
                  if (c.id == _selectedWalletCurrencyId) {
                    selectedCurrency = c;
                    break;
                  }
                }
              }
              selectedCurrency ??= currencies.isNotEmpty
                  ? currencies.first
                  : null;
              final currencyLabel = selectedCurrency != null
                  ? (selectedCurrency.displayName.isNotEmpty
                        ? selectedCurrency.displayName
                        : selectedCurrency.name)
                  : 'Currency';
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffE0E0E0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Actions for $currencyLabel',
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1D1D1D),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (selectedCurrency != null)
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async =>
                                _showDepositModal(context, selectedCurrency!),

                            label: Text(
                              'Add Funds (Deposit)',
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF388CFF),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: DepositRequestsTable(
              key: ValueKey(_depositRequestsRefreshKey),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
