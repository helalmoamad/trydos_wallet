import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/bank_deposits_api_service.dart';
import '../styles.dart';

/// جدول طلبات الإيداع مع إمكانية التقليب بين الصفحات.
class DepositRequestsTable extends StatefulWidget {
  const DepositRequestsTable({super.key});

  @override
  State<DepositRequestsTable> createState() => _DepositRequestsTableState();
}

class _DepositRequestsTableState extends State<DepositRequestsTable> {
  final BankDepositsApiService _apiService = BankDepositsApiService();
  static const int _limit = 10;

  int _page = 0;
  bool _isLoading = false;
  PaginatedResponse<BankDepositRequest>? _data;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _isLoading = true;
      _data = null;
    });

    final result = await _apiService.getDepositRequests(
      page: _page,
      limit: _limit,
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result.isSuccess && result.data != null) {
        _data = result.data;
      } else {
        _data = null;
      }
    });
  }

  void _goToPage(int page) {
    if (page < 0) return;
    if (_data != null && page >= _data!.totalPages) return;
    setState(() => _page = page);
    _fetch();
  }

  String _formatDate(String isoDate) {
    if (isoDate.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Deposit Requests',
              style: TrydosWalletStyles.headlineMedium.copyWith(
                color: const Color(0xff1D1D1D),
              ),
            ),
            if (_data != null)
              Text(
                '${_data!.total} records',
                style: TrydosWalletStyles.bodySmall.copyWith(
                  color: const Color(0xff8D8D8D),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: const Color(0xffFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE0E0E0)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          )
        else if (_data != null && _data!.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xffFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE0E0E0)),
            ),
            child: Center(
              child: Text(
                'No deposit requests yet',
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  color: const Color(0xff8D8D8D),
                ),
              ),
            ),
          )
        else if (_data != null)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE0E0E0)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 48,
                ),
                child: DataTable(
                  headingTextStyle: TrydosWalletStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1D1D1D),
                  ),
                  dataTextStyle: TrydosWalletStyles.bodySmall.copyWith(
                    color: const Color(0xff1D1D1D),
                  ),
                  columnSpacing: 24,
                  horizontalMargin: 16,
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Bank')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Amount')),
                    DataColumn(label: Text('Fees')),
                    DataColumn(label: Text('Tax')),
                  ],
                  rows: _data!.items.map((r) {
                    final symbol = r.currency.symbol;
                    return DataRow(
                      cells: [
                        DataCell(
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.id.length > 18
                                    ? '${r.id.substring(0, 18)}…'
                                    : r.id,
                                style: TrydosWalletStyles.bodySmall.copyWith(
                                  color: const Color(0xff1D1D1D),
                                ),
                              ),
                              Text(
                                r.transactionReference.isEmpty
                                    ? '—'
                                    : r.transactionReference,
                                style: TrydosWalletStyles.bodySmall.copyWith(
                                  fontSize: 9,
                                  color: const Color(0xff8D8D8D),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(Text(_formatDate(r.createdAt))),
                        DataCell(Text(r.bank.name)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: r.status.toUpperCase() == 'APPROVED'
                                  ? const Color(0xffE8F5E9)
                                  : r.status.toUpperCase() == 'PENDING'
                                      ? const Color(0xffFFF3E0)
                                      : const Color(0xffFFEBEE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              r.status,
                              style: TrydosWalletStyles.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff1D1D1D),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                            '${r.amount.toStringAsFixed(r.amount.truncateToDouble() == r.amount ? 0 : 2)} $symbol')),
                        DataCell(Text(
                            '${r.feeAmount.toStringAsFixed(r.feeAmount.truncateToDouble() == r.feeAmount ? 0 : 2)} $symbol')),
                        DataCell(Text(
                            '${r.taxAmount.toStringAsFixed(r.taxAmount.truncateToDouble() == r.taxAmount ? 0 : 2)} $symbol')),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xffFAFAFA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE0E0E0)),
            ),
            child: Center(
              child: TextButton(
                onPressed: _fetch,
                child: const Text('Retry'),
              ),
            ),
          ),
        if (_data != null && _data!.totalPages > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _data!.hasPrevious ? () => _goToPage(_page - 1) : null,
                icon: const Icon(Icons.chevron_left),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xffF5F5F5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Page ${_page + 1} of ${_data!.totalPages}',
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                  ),
                ),
              ),
              IconButton(
                onPressed: _data!.hasNext ? () => _goToPage(_page + 1) : null,
                icon: const Icon(Icons.chevron_right),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xffF5F5F5),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
