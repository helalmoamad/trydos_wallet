import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/trydos_wallet.dart';
import 'package:uuid/uuid.dart';

/// Currency deposit modal.
class DepositModal extends StatefulWidget {
  final Currency currency;
  final ScrollController? scrollController;

  const DepositModal({
    super.key,
    required this.currency,
    this.scrollController,
  });

  @override
  State<DepositModal> createState() => _DepositModalState();
}

class _DepositModalState extends State<DepositModal> {
  Bank? _selectedBank;
  bool _showBankList = false;
  final _amountController = TextEditingController();
  XFile? _pickedImageFile;
  final ScrollController _bankListScrollController = ScrollController();
  Timer? _debounceTimer;
  late final String _idempotencyKey;
  late final String _transactionReference;

  @override
  void initState() {
    super.initState();
    _idempotencyKey = const Uuid().v4();
    _transactionReference = 'TRX-${DateTime.now().millisecondsSinceEpoch}';
    _bankListScrollController.addListener(_onBankListScroll);
    _amountController.addListener(_onAmountChanged);

    // Dispatch bank load
    context.read<WalletBloc>().add(const WalletBanksLoadRequested());
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

  void _fetchFees() {
    final bank = _selectedBank;
    final amountText = _amountController.text.trim();
    if (bank == null || amountText.isEmpty) return;
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    context.read<WalletBloc>().add(
      WalletDepositFeesRequested(
        bankId: bank.id,
        currencyId: widget.currency.id,
        amount: amount,
      ),
    );
  }

  void _onBankListScroll() {
    final bloc = context.read<WalletBloc>();
    final state = bloc.state;
    if (state.banksStatus == WalletStatus.loading || !state.banksHasNext) {
      return;
    }
    final pos = _bankListScrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 50) {
      bloc.add(const WalletBanksLoadMoreRequested());
    }
  }

  bool _canConfirm(WalletState state) =>
      _selectedBank != null &&
      _amountController.text.trim().isNotEmpty &&
      state.uploadUrl != null &&
      state.depositStatus != WalletStatus.loading;

  void _confirmDeposit(String uploadUrl) {
    final bank = _selectedBank!;
    final amountText = _amountController.text.trim();
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) return;

    context.read<WalletBloc>().add(
      WalletDepositSubmitted(
        WalletDepositParams(
          bankId: bank.id,
          currencyId: widget.currency.id,
          amount: amount,
          transferImageUrl: uploadUrl,
          transactionReference: _transactionReference,
          idempotencyKey: _idempotencyKey,
        ),
      ),
    );
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
      });
    }
  }

  void _uploadProof() {
    final file = _pickedImageFile;
    if (file == null || file.path.isEmpty) return;

    context.read<WalletBloc>().add(WalletImageUploadRequested(File(file.path)));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listenWhen: (prev, curr) =>
          prev.depositStatus != curr.depositStatus ||
          prev.uploadStatus != curr.uploadStatus,
      listener: (context, state) {
        if (state.depositStatus == WalletStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppStrings.get(state.languageCode, 'deposit_request_submitted'),
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
          Navigator.of(context).pop(true);
        } else if (state.depositStatus == WalletStatus.failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.depositErrorMessage ??
                    AppStrings.get(
                      state.languageCode,
                      'failed_to_submit_deposit',
                    ),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      },
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          final currencySymbol = widget.currency.symbol;
          final uploadSuccess = state.uploadStatus == WalletStatus.success;
          final isUploading = state.uploadStatus == WalletStatus.loading;
          final isSubmitting = state.depositStatus == WalletStatus.loading;
          final isLoadingFees = state.depositFeesStatus == WalletStatus.loading;
          final feesResult = state.depositFees;

          return Directionality(
            textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    iconTheme: const IconThemeData(size: 24, opacity: 1.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SingleChildScrollView(
                      controller: widget.scrollController,
                      physics: const BouncingScrollPhysics(),
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
                                    '${AppStrings.get(state.languageCode, 'deposit_symbol')} $currencySymbol',
                                    style: TrydosWalletStyles.headlineMedium
                                        .copyWith(
                                          color: const Color(0xff1D1D1D),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppStrings.get(
                                      state.languageCode,
                                      'complete_form_deposit',
                                    ),
                                    style: TrydosWalletStyles.bodySmall
                                        .copyWith(
                                          color: const Color(0xff8D8D8D),
                                        ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            AppStrings.get(state.languageCode, 'source_bank'),
                            style: TrydosWalletStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff1D1D1D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () =>
                                setState(() => _showBankList = !_showBankList),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffF5F5F5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xffE0E0E0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedBank?.displayName ??
                                          AppStrings.get(
                                            state.languageCode,
                                            'select_bank',
                                          ),
                                      style: TrydosWalletStyles.bodyMedium
                                          .copyWith(
                                            color: _selectedBank != null
                                                ? const Color(0xff1D1D1D)
                                                : const Color(0xff8D8D8D),
                                          ),
                                    ),
                                  ),
                                  Icon(
                                    _showBankList
                                        ? Icons.expand_less
                                        : Icons.expand_more,
                                    size: 24,
                                    color: const Color(0xff8D8D8D),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_showBankList) ...[
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                if (state.banksStatus == WalletStatus.loading &&
                                    state.banks.isEmpty) {
                                  return Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFAFAFA),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xffE0E0E0),
                                      ),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (state.banksStatus == WalletStatus.failure &&
                                    state.banks.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffFAFAFA),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xffE0E0E0),
                                      ),
                                    ),
                                    child: Center(
                                      child: TextButton(
                                        onPressed: () =>
                                            context.read<WalletBloc>().add(
                                              const WalletBanksLoadRequested(),
                                            ),
                                        child: Text(
                                          AppStrings.get(
                                            state.languageCode,
                                            'retry',
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }
                                final banks = state.banks;
                                final hasNext = state.banksHasNext;
                                final isLoadingMore =
                                    state.banksStatus == WalletStatus.loading &&
                                    banks.isNotEmpty;
                                return Container(
                                  constraints: const BoxConstraints(
                                    maxHeight: 200,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFAFAFA),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xffE0E0E0),
                                    ),
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
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : TextButton(
                                                    onPressed: () => context
                                                        .read<WalletBloc>()
                                                        .add(
                                                          const WalletBanksLoadMoreRequested(),
                                                        ),
                                                    child: Text(
                                                      AppStrings.get(
                                                        state.languageCode,
                                                        'load_more',
                                                      ),
                                                      style: TrydosWalletStyles
                                                          .bodyMedium
                                                          .copyWith(
                                                            color: const Color(
                                                              0xFF388CFF,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                    ),
                                                  ),
                                          ),
                                        );
                                      }
                                      final bank = banks[index];
                                      final isSelected =
                                          _selectedBank?.id == bank.id;
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
                                            style: TrydosWalletStyles.bodyMedium
                                                .copyWith(
                                                  color: const Color(
                                                    0xff1D1D1D,
                                                  ),
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
                            AppStrings.get(state.languageCode, 'amount_label'),
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
                              border: Border.all(
                                color: const Color(0xffE0E0E0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    decoration: InputDecoration(
                                      hintText: '0.00',
                                      hintStyle: TrydosWalletStyles.bodyMedium
                                          .copyWith(
                                            color: const Color(0xff8D8D8D),
                                          ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                      isDense: true,
                                    ),
                                    onChanged: (_) => _onAmountChanged(),
                                  ),
                                ),
                                if (isLoadingFees)
                                  const Padding(
                                    padding: EdgeInsets.only(right: 8),
                                    child: SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF388CFF),
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
                          if (feesResult != null) ...[
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
                                border: Border.all(
                                  color: const Color(0xffD0E3F8),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppStrings.get(
                                          state.languageCode,
                                          'fee_label',
                                        ),
                                        style: TrydosWalletStyles.bodySmall
                                            .copyWith(
                                              color: const Color(0xff1D1D1D),
                                            ),
                                      ),
                                      Text(
                                        '${feesResult.feeAmount.toStringAsFixed(0)} ${feesResult.currencySymbol}',
                                        style: TrydosWalletStyles.bodySmall
                                            .copyWith(
                                              color: const Color(0xff1D1D1D),
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppStrings.get(
                                          state.languageCode,
                                          'tax_label',
                                        ),
                                        style: TrydosWalletStyles.bodySmall
                                            .copyWith(
                                              color: const Color(0xff1D1D1D),
                                            ),
                                      ),
                                      Text(
                                        '${feesResult.taxAmount.toStringAsFixed(0)} ${feesResult.currencySymbol}',
                                        style: TrydosWalletStyles.bodySmall
                                            .copyWith(
                                              color: const Color(0xff1D1D1D),
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        AppStrings.get(
                                          state.languageCode,
                                          'you_receive',
                                        ),
                                        style: TrydosWalletStyles.bodyMedium
                                            .copyWith(
                                              color: const Color(0xFF388CFF),
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        '${feesResult.netAmount.toStringAsFixed(0)} ${feesResult.currencySymbol}',
                                        style: TrydosWalletStyles.bodyMedium
                                            .copyWith(
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
                            AppStrings.get(
                              state.languageCode,
                              'proof_of_transfer',
                            ),
                            style: TrydosWalletStyles.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff1D1D1D),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: uploadSuccess ? null : _pickImage,
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
                              child: _pickedImageFile == null && !uploadSuccess
                                  ? Center(
                                      child: Text(
                                        AppStrings.get(
                                          state.languageCode,
                                          'click_to_upload',
                                        ),
                                        style: TrydosWalletStyles.bodyMedium
                                            .copyWith(
                                              color: const Color(0xff8D8D8D),
                                            ),
                                      ),
                                    )
                                  : uploadSuccess
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(width: 8),
                                              Text(
                                                AppStrings.get(
                                                  state.languageCode,
                                                  'upload_success_msg',
                                                ),
                                                style: TrydosWalletStyles
                                                    .bodyMedium
                                                    .copyWith(
                                                      color: const Color(
                                                        0xFF4CAF50,
                                                      ),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            onPressed: () => setState(() {
                                              _pickedImageFile = null;
                                              context.read<WalletBloc>().add(
                                                const WalletImageResetRequested(),
                                              );
                                            }),
                                            child: Text(
                                              AppStrings.get(
                                                state.languageCode,
                                                'change_image',
                                              ),
                                              style: TrydosWalletStyles
                                                  .bodySmall
                                                  .copyWith(
                                                    color: const Color(
                                                      0xFF388CFF,
                                                    ),
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
                                            padding: const EdgeInsets.only(
                                              bottom: 12,
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
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
                                            onPressed: isUploading
                                                ? null
                                                : _uploadProof,
                                            icon: isUploading
                                                ? const SizedBox(
                                                    width: 18,
                                                    height: 18,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          color: Colors.white,
                                                        ),
                                                  )
                                                : const Icon(
                                                    Icons.cloud_upload,
                                                  ),
                                            label: Text(
                                              isUploading
                                                  ? AppStrings.get(
                                                      state.languageCode,
                                                      'uploading_msg',
                                                    )
                                                  : AppStrings.get(
                                                      state.languageCode,
                                                      'confirm_upload',
                                                    ),
                                              style: TrydosWalletStyles
                                                  .bodyMedium
                                                  .copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(
                                                0xFF388CFF,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
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
                              onPressed: _canConfirm(state)
                                  ? () => _confirmDeposit(state.uploadUrl!)
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF388CFF),
                                disabledBackgroundColor: const Color(
                                  0xffC0C0C0,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: isSubmitting
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Text(
                                      AppStrings.get(
                                        state.languageCode,
                                        'confirm_deposit_label',
                                      ),
                                      style: TrydosWalletStyles.bodyMedium
                                          .copyWith(
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
              ),
            ),
          );
        },
      ),
    );
  }
}
