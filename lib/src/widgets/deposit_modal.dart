import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../bloc/bloc.dart';
import '../models/models.dart';
import '../services/bank_deposits_api_service.dart';
import '../services/media_api_service.dart';
import '../styles.dart';

/// Currency deposit modal.
class DepositModal extends StatefulWidget {
  final Currency currency;

  const DepositModal({super.key, required this.currency});

  @override
  State<DepositModal> createState() => _DepositModalState();
}

class _DepositModalState extends State<DepositModal> {
  Bank? _selectedBank;
  bool _showBankList = false;
  final _amountController = TextEditingController();
  XFile? _pickedImageFile;
  String? _proofFileUrl;
  bool _isUploading = false;
  bool _uploadSuccess = false;
  final ScrollController _bankListScrollController = ScrollController();
  Timer? _debounceTimer;
  bool _isLoadingFees = false;
  bool _isSubmitting = false;
  late final String _idempotencyKey;
  late final String _transactionReference;
  DepositFeesResult? _feesResult;
  final BankDepositsApiService _bankDepositsApiService =
      BankDepositsApiService();
  final MediaApiService _mediaApiService = MediaApiService();

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
    _transactionReference = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    _bankListScrollController.addListener(_onBankListScroll);
    _amountController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _amountController.removeListener(_onAmountChanged);
    _amountController.dispose();
    _bankListScrollController.removeListener(_onBankListScroll);
    _bankListScrollController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    setState(() {
      _feesResult = null;
    });
    _debounceTimer?.cancel();
    final amountText = _amountController.text.trim();
    if (_selectedBank == null || amountText.isEmpty) {
      return;
    }
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      return;
    }
    _debounceTimer = Timer(const Duration(seconds: 1), () {
      _fetchFees();
    });
  }

  Future<void> _fetchFees() async {
    final bank = _selectedBank;
    final amountText = _amountController.text.trim();
    if (bank == null || amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    if (!mounted) return;
    setState(() {
      _isLoadingFees = true;
      _feesResult = null;
    });

    final result = await _bankDepositsApiService.calculateFees(
      bankId: bank.id,
      currencyId: widget.currency.id,
      amount: amount,
    );

    if (!mounted) return;
    setState(() {
      _isLoadingFees = false;
      if (result.isSuccess && result.data != null) {
        _feesResult = result.data;
      } else {
        _feesResult = null;
      }
    });
  }

  void _onBankListScroll() {
    final bloc = context.read<PaginatedApiBloc<Bank>>();
    final state = bloc.state;
    if (state is! ApiLoaded<Bank> || !state.hasNext || state.isLoadingMore) {
      return;
    }
    final pos = _bankListScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 50) {
      bloc.add(const ApiLoadMoreRequested());
    }
  }

  bool get _canConfirm =>
      _selectedBank != null &&
      _amountController.text.trim().isNotEmpty &&
      _proofFileUrl != null &&
      !_isSubmitting;

  Future<void> _confirmDeposit() async {
    if (!_canConfirm) return;
    final bank = _selectedBank!;
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    final proofUrl = _proofFileUrl!;
    if (amount == null || amount <= 0) return;

    if (!mounted) return;
    setState(() => _isSubmitting = true);

    final result = await _bankDepositsApiService.createDeposit(
      bankId: bank.id,
      currencyId: widget.currency.id,
      amount: amount,
      transferImageUrl: proofUrl,
      transactionReference: _transactionReference,
      idempotencyKey: _idempotencyKey,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.isSuccess && result.data != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.data!.status == 'PENDING'
                  ? 'Deposit request submitted successfully'
                  : 'Deposit completed successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error?.message ?? 'Failed to submit deposit request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final xFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile != null && mounted) {
      setState(() {
        _pickedImageFile = xFile;
        _proofFileUrl = null;
        _uploadSuccess = false;
      });
    }
  }

  Future<void> _uploadProof() async {
    final file = _pickedImageFile;
    if (file == null || file.path.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isUploading = true;
      _uploadSuccess = false;
    });

    final result = await _mediaApiService.uploadDirect(
      filePath: file.path,
      type: 'image',
      metadata: {'purpose': 'deposit_proof'},
    );

    if (!mounted) return;
    setState(() {
      _isUploading = false;
      if (result.isSuccess && result.data != null) {
        _proofFileUrl = result.data!.url;
        _uploadSuccess = true;
      } else {
        _uploadSuccess = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = widget.currency.symbol;
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Theme(
          data: Theme.of(
            context,
          ).copyWith(iconTheme: const IconThemeData(size: 24, opacity: 1.0)),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Deposit $currencySymbol',
                          style: TrydosWalletStyles.headlineMedium.copyWith(
                            color: const Color(0xff1D1D1D),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Complete the form to request a deposit.',
                          style: TrydosWalletStyles.bodySmall.copyWith(
                            color: const Color(0xff8D8D8D),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'SOURCE BANK',
                  style: TrydosWalletStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1D1D1D),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => setState(() => _showBankList = !_showBankList),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffE0E0E0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _selectedBank?.displayName ?? 'Select a bank...',
                            style: TrydosWalletStyles.bodyMedium.copyWith(
                              color: _selectedBank != null
                                  ? const Color(0xff1D1D1D)
                                  : const Color(0xff8D8D8D),
                            ),
                          ),
                        ),
                        Icon(
                          _showBankList ? Icons.expand_less : Icons.expand_more,
                          size: 24,
                          color: const Color(0xff8D8D8D),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showBankList) ...[
                  const SizedBox(height: 8),
                  BlocBuilder<PaginatedApiBloc<Bank>, ApiState<Bank>>(
                    builder: (context, state) {
                      if (state is ApiInitial<Bank> ||
                          state is ApiLoading<Bank>) {
                        return Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xffFAFAFA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xffE0E0E0)),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (state is ApiError<Bank>) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xffFAFAFA),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xffE0E0E0)),
                          ),
                          child: Center(
                            child: TextButton(
                              onPressed: () => context
                                  .read<PaginatedApiBloc<Bank>>()
                                  .add(const ApiRefreshRequested()),
                              child: const Text('Retry'),
                            ),
                          ),
                        );
                      }
                      final loadedState = state as ApiLoaded<Bank>;
                      final banks = loadedState.items;
                      final hasNext = loadedState.hasNext;
                      final isLoadingMore = loadedState.isLoadingMore;
                      return Container(
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: const Color(0xffFAFAFA),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xffE0E0E0)),
                        ),
                        child: ListView.builder(
                          controller: _bankListScrollController,
                          shrinkWrap: true,
                          itemCount: banks.length + (hasNext ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == banks.length) {
                              return Padding(
                                padding: const EdgeInsets.all(12),
                                child: Center(
                                  child: isLoadingMore
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : TextButton(
                                          onPressed: () => context
                                              .read<PaginatedApiBloc<Bank>>()
                                              .add(
                                                const ApiLoadMoreRequested(),
                                              ),
                                          child: Text(
                                            'Load more',
                                            style: TrydosWalletStyles.bodyMedium
                                                .copyWith(
                                                  color: const Color(
                                                    0xFF388CFF,
                                                  ),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                          ),
                                        ),
                                ),
                              );
                            }
                            final bank = banks[index];
                            final isSelected = _selectedBank?.id == bank.id;
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedBank = bank;
                                  _showBankList = false;
                                });
                                _onAmountChanged();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xffE8F0FE)
                                      : null,
                                ),
                                child: Text(
                                  bank.displayName,
                                  style: TrydosWalletStyles.bodyMedium.copyWith(
                                    color: const Color(0xff1D1D1D),
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : null,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'AMOUNT',
                  style: TrydosWalletStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1D1D1D),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffF5F5F5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xffE0E0E0)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            hintText: '0.00',
                            hintStyle: TrydosWalletStyles.bodyMedium.copyWith(
                              color: const Color(0xff8D8D8D),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      if (_isLoadingFees)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: const Color(0xFF388CFF),
                            ),
                          ),
                        ),
                      Text(
                        currencySymbol,
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1D1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_feesResult != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffE8F4FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffD0E3F8)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Fee:',
                              style: TrydosWalletStyles.bodySmall.copyWith(
                                color: const Color(0xff1D1D1D),
                              ),
                            ),
                            Text(
                              '${_feesResult!.feeAmount.toStringAsFixed(0)} ${_feesResult!.currencySymbol}',
                              style: TrydosWalletStyles.bodySmall.copyWith(
                                color: const Color(0xff1D1D1D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tax:',
                              style: TrydosWalletStyles.bodySmall.copyWith(
                                color: const Color(0xff1D1D1D),
                              ),
                            ),
                            Text(
                              '${_feesResult!.taxAmount.toStringAsFixed(0)} ${_feesResult!.currencySymbol}',
                              style: TrydosWalletStyles.bodySmall.copyWith(
                                color: const Color(0xff1D1D1D),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'You Receive:',
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: const Color(0xFF388CFF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_feesResult!.netAmount.toStringAsFixed(0)} ${_feesResult!.currencySymbol}',
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: const Color(0xFF388CFF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'PROOF OF TRANSFER',
                  style: TrydosWalletStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1D1D1D),
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _uploadSuccess ? null : _pickImage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xffFAFAFA),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xffE0E0E0),
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: _pickedImageFile == null && !_uploadSuccess
                        ? Center(
                            child: Text(
                              'Click to upload image',
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: const Color(0xff8D8D8D),
                              ),
                            ),
                          )
                        : _uploadSuccess
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(width: 8),
                                    Text(
                                      'Upload successful',
                                      style: TrydosWalletStyles.bodyMedium
                                          .copyWith(
                                            color: const Color(0xFF4CAF50),
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () => setState(() {
                                    _pickedImageFile = null;
                                    _proofFileUrl = null;
                                    _uploadSuccess = false;
                                  }),
                                  child: Text(
                                    'Change image',
                                    style: TrydosWalletStyles.bodySmall
                                        .copyWith(
                                          color: const Color(0xFF388CFF),
                                          fontWeight: FontWeight.w500,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_pickedImageFile != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      File(_pickedImageFile!.path),
                                      height: 80,
                                      width: 80,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: _isUploading ? null : _uploadProof,
                                  icon: _isUploading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.cloud_upload),
                                  label: Text(
                                    _isUploading
                                        ? 'Uploading...'
                                        : 'Confirm upload',
                                    style: TrydosWalletStyles.bodyMedium
                                        .copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF388CFF),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _canConfirm ? _confirmDeposit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF388CFF),
                      disabledBackgroundColor: const Color(0xffC0C0C0),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            'Confirm Deposit',
                            style: TrydosWalletStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
