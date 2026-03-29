import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/services/payment_requests_api_service.dart';
import 'package:trydos_wallet/trydos_wallet.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/successful_page.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/qr_scanner_page.dart';
import 'package:trydos_wallet/src/utils/payment_request_crypto.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';

class TransferSendModal extends StatefulWidget {
  final QrTransferPayload? initialPayload;
  final String? initialScanRaw;

  const TransferSendModal({
    super.key,
    this.initialPayload,
    this.initialScanRaw,
  });

  @override
  State<TransferSendModal> createState() => _TransferSendModalState();
}

enum TransferState { input, sending, success }

enum RecipientInputType { account, phone }

class _TransferSendModalState extends State<TransferSendModal>
    with WidgetsBindingObserver {
  TransferState currentTransferState = TransferState.input;
  RecipientInputType currentInputType = RecipientInputType.account;
  final TransfersApiService _transfersApi = TransfersApiService();
  final PaymentRequestsApiService _paymentRequestsApi =
      PaymentRequestsApiService();
  final ScrollController _formScrollController = ScrollController();
  final GlobalKey _noteRowKey = GlobalKey();
  String? selectedPurpose;
  final FocusNode recipientFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final FocusNode idFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();
  final FocusNode noteFocus = FocusNode();
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool isRecipientVerified = false;
  bool isRecipientLookupLoading = false;
  String? recipientAccountName;
  String? recipientErrorMessage;
  String? nameErrorMessage;
  String? idErrorMessage;
  String? amountErrorMessage;
  bool isEditingRecipient = true;
  String? _phoneForEdit;
  bool?
  isPhoneRegistered; // null=not checked, true=registered, false=not registered

  bool isNameVerified = false;
  bool isEditingName = true;

  bool isIdVerified = false;
  bool isEditingId = true;

  bool isAmountVerified = false;
  bool isEditingAmount = true;
  bool isTransferVerifyLoading = false;
  bool isRequestLookupLoading = false;

  bool isFromQr = false;
  bool isRequestFlow = false;
  bool isBalanceHidden = false;
  TransferSendResult? _lastSendResult;
  PaymentRequestFulfillResponse? _lastFulfilledRequest;
  bool isPermanentRequest = false;
  DateTime? expiryTime;
  String? referenceId;
  String? paymentRequestId;
  String? requestType;
  String? requestStatus;
  String? maskedAccountName;
  String? qrPurpose;
  Timer? _expiryTicker;

  bool get isExpired =>
      isRequestFlow &&
      expiryTime != null &&
      !DateTime.now().isBefore(expiryTime!);

  void _restartExpiryWatcher() {
    _expiryTicker?.cancel();
    if (!isRequestFlow || expiryTime == null) return;

    _expiryTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      setState(() {});

      if (isExpired) {
        _expiryTicker?.cancel();
        return;
      }
    });
  }

  bool get isRequestStatusNotActive {
    if (!isRequestFlow) return false;
    final status = (requestStatus ?? '').trim().toUpperCase();
    if (status.isEmpty) return false;
    return status != 'ACTIVE';
  }

  void _scrollNoteFieldIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 180), () {
        if (!mounted || !noteFocus.hasFocus) {
          return;
        }

        final targetContext = _noteRowKey.currentContext;
        if (targetContext == null) return;

        Scrollable.ensureVisible(
          // ignore: use_build_context_synchronously
          targetContext,
          alignment: 0.2,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    });
  }

  Future<void> _applyScannedPayload(QrTransferPayload payload) async {
    setState(() {
      isFromQr = true;
      currentInputType = RecipientInputType.account;
      recipientController.text = payload.accountNumber;
      maskedAccountName = payload.accountName;
      recipientErrorMessage = null;
      recipientAccountName = payload.accountName;
    });

    if (payload.isRequestFlow) {
      setState(() {
        isRequestFlow = true;
        isPermanentRequest = payload.expiryTime == null;
        amountController.text = payload.amount ?? '';
        referenceId = payload.reference;
        paymentRequestId = (payload.reference ?? '').trim().isEmpty
            ? null
            : payload.reference!.trim();
        qrPurpose = payload.purpose;
        requestType = payload.requestType;
        requestStatus = null;
        expiryTime = payload.expiryTime;
        if ((payload.note ?? '').isNotEmpty) {
          noteController.text = payload.note!;
        }
        isRecipientVerified = true;
        isAmountVerified = true;
        isEditingRecipient = false;
        isEditingAmount = false;
      });
      _restartExpiryWatcher();
      return;
    }

    setState(() {
      isRequestFlow = false;
      isPermanentRequest = false;
      referenceId = null;
      paymentRequestId = null;
      qrPurpose = null;
      requestType = null;
      requestStatus = null;
      expiryTime = null;
      isEditingRecipient = true;
      isEditingAmount = true;
      isAmountVerified = false;
      amountErrorMessage = null;
    });
    _expiryTicker?.cancel();

    await _verifyRecipient();
  }

  String _displayPurposeName(WalletState state, String? rawPurpose) {
    final value = (rawPurpose ?? '').trim();
    if (value.isEmpty) {
      return AppStrings.get(state.languageCode, 'work_partnership');
    }

    for (final purpose in _purposeOptions(state)) {
      if (purpose.id == value) return purpose.name;
      if (purpose.name.toLowerCase() == value.toLowerCase()) {
        return purpose.name;
      }
    }

    final localized = AppStrings.get(state.languageCode, value);
    return localized == value ? value : localized;
  }

  String _formatAmountFromLookup(double amount) {
    if (amount.truncateToDouble() == amount) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }

  Future<void> _applyScannedRaw(String raw) async {
    // ── الطريقة 1: PAYREQ (طلب إيداع مشفر) ──────────────────────────────
    // الشكل: PAYREQ:{base64}|{accountNumber}
    if (PaymentRequestCrypto.isPayreqFormat(raw)) {
      final decrypted = PaymentRequestCrypto.decrypt(raw);
      if (decrypted == null || decrypted.isEmpty) {
        showMessage(
          AppStrings.get(
            context.read<WalletBloc>().state.languageCode,
            'account_lookup_failed_msg',
          ),
          context: context,
          type: MessageType.error,
        );
        return;
      }
      // decrypted = كود طلب الإيداع → نرسله مباشرة لـ lookup
      await _lookupRequestCode(decrypted);
      return;
    }

    // ── الطريقة 2: صيغة QrTransferPayloadCodec القديمة (query-string) ────
    // تحتوي على anu= وغيرها — قد تكون receive أو request قديم
    final payload = QrTransferPayloadCodec.tryParse(raw);
    if (payload != null) {
      await _applyScannedPayload(payload);
      return;
    }

    // ── الطريقة 3: رقم الحساب العادي ─────────────────────────────────────
    // أي نص لا ينتمي للصيغتين أعلاه يُعامل كرقم حساب مباشر
    final accountNumber = raw.trim();
    if (accountNumber.isEmpty) return;

    setState(() {
      isFromQr = true;
      currentInputType = RecipientInputType.account;
      recipientController.text = accountNumber;
      recipientAccountName = null;
      recipientErrorMessage = null;
      isEditingRecipient = true;
      isRequestFlow = false;
      isPermanentRequest = false;
      referenceId = null;
      paymentRequestId = null;
      qrPurpose = null;
      requestType = null;
      requestStatus = null;
      expiryTime = null;
      isEditingAmount = true;
      isAmountVerified = false;
      amountErrorMessage = null;
    });
    _expiryTicker?.cancel();
    await _verifyRecipient();
  }

  /// يرسل [requestCode] لـ API lookup ويملأ حقول صفحة الإرسال بنتيجة طلب الإيداع.
  Future<void> _lookupRequestCode(String requestCode) async {
    final state = context.read<WalletBloc>().state;
    setState(() {
      isRequestLookupLoading = true;
    });

    final result = await _paymentRequestsApi.lookupPaymentRequest(
      requestCode: requestCode,
      languageCode: state.languageCode,
    );

    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      final purposeValue = data.purpose?.id ?? data.purpose?.name ?? '';
      final referenceValue = (data.reference ?? '').trim().isNotEmpty
          ? data.reference!
          : data.requestCode;

      setState(() {
        isRequestLookupLoading = false;
        isFromQr = true;
        isRequestFlow = true;
        currentInputType = RecipientInputType.account;

        recipientController.text = data.requesterAccountNumber;
        recipientAccountName = data.requesterAccountName;
        maskedAccountName = data.requesterAccountName;

        amountController.text = _formatAmountFromLookup(data.amount);
        paymentRequestId = data.id;
        referenceId = referenceValue;
        qrPurpose = purposeValue;
        requestType = AppStrings.get(state.languageCode, 'deposit_request');
        requestStatus = data.status;
        isPermanentRequest = data.isPermanent;
        expiryTime = data.isPermanent ? null : data.expiresAt;

        isRecipientVerified = true;
        isEditingRecipient = false;
        recipientErrorMessage = null;
        isAmountVerified = true;
        isEditingAmount = false;
        amountErrorMessage = null;
      });
      _restartExpiryWatcher();
      return;
    }

    setState(() {
      isRequestLookupLoading = false;
    });

    showMessage(
      result.errorMessage ??
          AppStrings.get(state.languageCode, 'account_lookup_failed_msg'),
      context: context,
      type: MessageType.error,
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<WalletBloc>().add(const WalletTransferPurposesLoadRequested());
    recipientFocus.addListener(() {
      if (!recipientFocus.hasFocus && isEditingRecipient) {
        _verifyRecipient();
      }
      setState(() {});
    });
    nameFocus.addListener(() {
      if (!nameFocus.hasFocus &&
          isEditingName &&
          nameController.text.isNotEmpty) {
        setState(() {
          isNameVerified = true;
          isEditingName = false;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          idFocus.requestFocus();
        });
      }
      setState(() {});
    });
    idFocus.addListener(() {
      if (!idFocus.hasFocus && isEditingId && idController.text.isNotEmpty) {
        setState(() {
          isIdVerified = true;
          isEditingId = false;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          amountFocus.requestFocus();
        });
      }
      setState(() {});
    });
    amountFocus.addListener(() {
      if (!amountFocus.hasFocus &&
          isEditingAmount &&
          amountController.text.isNotEmpty) {
        _verifyTransferByAmount();
      }
      setState(() {});
    });
    noteFocus.addListener(() {
      if (noteFocus.hasFocus) {
        _scrollNoteFieldIntoView();
        Future.delayed(const Duration(milliseconds: 260), () {
          if (!mounted || !noteFocus.hasFocus) return;
          _scrollNoteFieldIntoView();
        });
      }
      setState(() {});
    });
    recipientController.addListener(() => setState(() {}));
    nameController.addListener(() => setState(() {}));
    idController.addListener(() => setState(() {}));
    amountController.addListener(() => setState(() {}));
    noteController.addListener(() => setState(() {}));
    final initialPayload = widget.initialPayload;
    final initialScanRaw = widget.initialScanRaw;
    if (initialPayload != null ||
        (initialScanRaw != null && initialScanRaw.trim().isNotEmpty)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (initialScanRaw != null && initialScanRaw.trim().isNotEmpty) {
          _applyScannedRaw(initialScanRaw);
        } else if (initialPayload != null) {
          _applyScannedPayload(initialPayload);
        }
      });
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    if (!mounted || !noteFocus.hasFocus) {
      return;
    }
    _scrollNoteFieldIntoView();
  }

  void _resetRecipientLookupState() {
    isRecipientVerified = false;
    isEditingRecipient = true;
    isRecipientLookupLoading = false;
    recipientAccountName = null;
    recipientErrorMessage = null;
    isEditingAmount = true;
    isAmountVerified = false;
    isTransferVerifyLoading = false;
    amountErrorMessage = null;
  }

  void _resetPhoneRecipientState() {
    _phoneForEdit = null;
    isPhoneRegistered = null;
    isNameVerified = false;
    isEditingName = true;
    isIdVerified = false;
    isEditingId = true;
    nameErrorMessage = null;
    idErrorMessage = null;
    nameController.clear();
    idController.clear();
  }

  void _switchRecipientInputType(RecipientInputType inputType) {
    if (currentInputType == inputType) {
      return;
    }

    setState(() {
      currentInputType = inputType;
      recipientController.clear();
      amountErrorMessage = null;
      isEditingAmount = true;
      isAmountVerified = false;
      _resetRecipientLookupState();
      _resetPhoneRecipientState();
    });
  }

  double? _parseAmountValue() {
    final normalized = amountController.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(normalized);
    if (parsed == null || parsed <= 0) {
      return null;
    }
    return parsed;
  }

  double _selectedAvailableBalance(WalletState state) {
    return state.balances[state.selectedAssetId ?? '']?.available ?? 0;
  }

  bool _isAmountWithinSelectedBalance(double amount, WalletState state) {
    final available = _selectedAvailableBalance(state);
    return amount > 0 && amount <= available;
  }

  bool _isSelectedBalanceLoading(WalletState state) {
    final selectedId = state.selectedAssetId ?? '';
    if (selectedId.isEmpty) {
      return false;
    }
    return state.loadingBalanceIds.contains(selectedId);
  }

  void _refreshSelectedBalance() {
    final selectedId = context.read<WalletBloc>().state.selectedAssetId ?? '';
    if (selectedId.isEmpty) {
      return;
    }
    context.read<WalletBloc>().add(WalletBalanceLoadRequested(selectedId));
  }

  Future<void> _verifyTransferByAmount() async {
    if (isRequestFlow) {
      setState(() {
        isAmountVerified = true;
        isEditingAmount = false;
        amountErrorMessage = null;
      });
      return;
    }

    final state = context.read<WalletBloc>().state;
    final lang = state.languageCode;
    final amount = _parseAmountValue();

    if (amount == null) {
      setState(() {
        isAmountVerified = false;
        isEditingAmount = true;
        amountErrorMessage = AppStrings.get(lang, 'invalid_amount');
      });
      return;
    }

    if (!_isAmountWithinSelectedBalance(amount, state)) {
      setState(() {
        isAmountVerified = false;
        isEditingAmount = true;
        amountErrorMessage = AppStrings.get(lang, 'insufficient_balance');
      });
      return;
    }

    final shouldVerifyWithApi =
        currentInputType == RecipientInputType.account ||
        (currentInputType == RecipientInputType.phone &&
            isPhoneRegistered == true);

    if (!shouldVerifyWithApi) {
      setState(() {
        isAmountVerified = true;
        isEditingAmount = false;
        amountErrorMessage = null;
      });
      return;
    }

    final toAccount = recipientController.text.trim();
    if (toAccount.isEmpty || !toAccount.contains('-')) {
      setState(() {
        isAmountVerified = false;
        isEditingAmount = true;
        amountErrorMessage = AppStrings.get(lang, 'incorrect_account_msg');
      });
      return;
    }
    Currency? currency;
    final selectedId = state.selectedAssetId ?? '';
    for (final c in state.currencies) {
      if (c.id == selectedId) {
        currency = c;
        break;
      }
    }
    final selectedBalance = state.balances[selectedId];
    final selectedAssetSymbol = selectedBalance?.assetSymbol.isNotEmpty == true
        ? selectedBalance!.assetSymbol
        : (currency?.symbol ?? r'$');
    final selectedAssetType = (selectedBalance?.assetType ?? 'CURRENCY')
        .toUpperCase();

    setState(() {
      isTransferVerifyLoading = true;
      isAmountVerified = false;
      amountErrorMessage = null;
    });

    final result = await _transfersApi.verifyTransfer(
      toAccountNumber: toAccount,
      assetSymbol: selectedAssetSymbol,
      assetType: selectedAssetType,
      amount: amount,
    );
    if (!mounted) return;

    if (result.isSuccess && result.data != null && result.data!.valid) {
      setState(() {
        isTransferVerifyLoading = false;
        isAmountVerified = true;
        isEditingAmount = false;
        amountErrorMessage = null;
        if (result.data!.receiver.name.isNotEmpty) {
          recipientAccountName = result.data!.receiver.name;
        }
      });
      return;
    }

    setState(() {
      isTransferVerifyLoading = false;
      isAmountVerified = false;
      isEditingAmount = true;
      amountErrorMessage = AppStrings.get(lang, 'invalid_amount');
    });

    showMessage(
      result.isSuccess
          ? AppStrings.get(lang, 'invalid_amount')
          : AppStrings.get(lang, 'account_lookup_failed_msg'),
      context: context,
      type: MessageType.error,
    );
  }

  Future<void> _verifyRecipient() async {
    final state = context.read<WalletBloc>().state;
    final rawText = recipientController.text.trim();
    final text = rawText.replaceAll(' ', '');
    final lang = context.read<WalletBloc>().state.languageCode;

    if (text.isEmpty) return;

    if (currentInputType != RecipientInputType.account) {
      setState(() {
        // Phone Number processing
        final phoneText = text.replaceAll('+', '');
        if (phoneText.length >= 7) {
          isRecipientVerified = true;
          recipientErrorMessage = null;
          isEditingRecipient = false;
          _phoneForEdit = recipientController.text;

          // Mock lookup: if phone starts with '90' → registered (has account)
          final registered = phoneText.startsWith('90');
          isPhoneRegistered = registered;

          if (registered) {
            // Show account number — same as method 2
            recipientController.text = '100-708';
            Future.delayed(const Duration(milliseconds: 100), () {
              amountFocus.requestFocus();
            });
          } else {
            // Unregistered → ask for name and ID
            Future.delayed(const Duration(milliseconds: 100), () {
              nameFocus.requestFocus();
            });
          }
        } else {
          isRecipientVerified = false;
          recipientErrorMessage = AppStrings.get(lang, 'phone_min_digits_msg');
          isEditingRecipient = true;
        }
      });
      return;
    }

    if (text.length <= 7 || !text.contains('-')) {
      setState(() {
        _resetRecipientLookupState();
        recipientErrorMessage = AppStrings.get(lang, 'incorrect_account_msg');
      });
      return;
    }

    setState(() {
      _resetRecipientLookupState();
      isRecipientLookupLoading = true;
    });

    final result = await _transfersApi.lookupAccount(text);
    if (!mounted) return;

    if (result.isSuccess && result.data != null && result.data!.found) {
      setState(() {
        isRecipientLookupLoading = false;
        isRecipientVerified = true;
        isEditingRecipient = false;
        recipientErrorMessage = null;
        recipientController.text = result.data!.accountNumber;
        recipientAccountName = result.data!.name;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          amountFocus.requestFocus();
        }
      });
      return;
    }

    setState(() {
      _resetRecipientLookupState();
      recipientErrorMessage = result.isSuccess
          ? AppStrings.get(state.languageCode, 'account_not_found_msg')
          : AppStrings.get(state.languageCode, 'account_lookup_failed_msg');
    });

    showMessage(
      result.isSuccess
          ? AppStrings.get(state.languageCode, 'account_not_found_msg')
          : AppStrings.get(state.languageCode, 'account_lookup_failed_msg'),
      context: context,
      type: MessageType.error,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _expiryTicker?.cancel();
    _formScrollController.dispose();
    recipientFocus.dispose();
    nameFocus.dispose();
    idFocus.dispose();
    amountFocus.dispose();
    noteFocus.dispose();
    recipientController.dispose();
    nameController.dispose();
    idController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  static const List<String> months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

  List<TransferPurpose> _purposeOptions(WalletState state) {
    return state.transferPurposes;
  }

  String? _resolvePurposeIdForSend(WalletState state) {
    final candidate = selectedPurpose ?? qrPurpose;
    if (candidate == null || candidate.isEmpty) {
      return null;
    }

    for (final purpose in _purposeOptions(state)) {
      if (purpose.id == candidate) {
        return purpose.id;
      }
      if (purpose.name.toLowerCase() == candidate.toLowerCase()) {
        return purpose.id;
      }
    }

    return null;
  }

  String _generateIdempotencyKey() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final suffix = List.generate(
      9,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
    return 'transfer-${DateTime.now().millisecondsSinceEpoch}-$suffix';
  }

  String _formatAmount(double value) {
    if (value.truncateToDouble() == value) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(2);
  }

  String _formatDateTimeForReceipt(String createdAt, String languageCode) {
    final dt = DateTime.tryParse(createdAt)?.toLocal();
    if (dt == null) {
      return '';
    }
    return '${dt.day.toString().padLeft(2, '0')}.${AppStrings.get(languageCode, months[dt.month - 1])} | ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _requestValidUntilText(WalletState state) {
    if (isPermanentRequest && expiryTime == null) {
      return AppStrings.get(state.languageCode, 'always');
    }

    final expiry = expiryTime;
    if (expiry == null) {
      return '-';
    }

    final remainingSeconds = expiry.difference(DateTime.now()).inSeconds;
    final safeSeconds = remainingSeconds < 0 ? 0 : remainingSeconds;
    final mins = safeSeconds ~/ 60;
    final secs = safeSeconds % 60;
    final mmss =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final timeStr =
        '${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')}';
    final dateStr =
        '${expiry.day} ${AppStrings.get(state.languageCode, months[expiry.month - 1])} ${expiry.year}';

    return '$mmss ${AppStrings.get(state.languageCode, 'minutes_until')}$timeStr | $dateStr';
  }

  String _requestStatusMessage(WalletState state) {
    final status = (requestStatus ?? '').trim().toUpperCase();
    switch (status) {
      case 'EXPIRED':
        return AppStrings.get(state.languageCode, 'expired_code');
      case 'CANCELLED':
        return AppStrings.get(state.languageCode, 'request_cancelled');
      case 'FULFILLED':
        return AppStrings.get(state.languageCode, 'request_fulfilled');
      default:
        return AppStrings.get(state.languageCode, 'request_inactive');
    }
  }

  String _maskNameIfNeeded(String fullName) {
    final name = fullName.trim();
    if (name.isEmpty) {
      return '';
    }

    return name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          if (part.contains('*')) {
            return part;
          }
          return '${part[0]}*****';
        })
        .join(' ');
  }

  bool _isFulfilledStatus(String status) {
    return status.trim().toUpperCase() == 'FULFILLED';
  }

  String? _dynamicAsNonEmptyString(dynamic value) {
    if (value == null) {
      return null;
    }
    final text = value.toString().trim();
    if (text.isEmpty || text == '{}' || text == 'null') {
      return null;
    }
    return text;
  }

  String _requestReferenceFromFulfill(PaymentRequestFulfillResponse response) {
    return _dynamicAsNonEmptyString(response.accountTransferId) ??
        _dynamicAsNonEmptyString(response.journalEntryId) ??
        _dynamicAsNonEmptyString(response.financialLedgerInId) ??
        response.id;
  }

  String _requestDateFromFulfill(PaymentRequestFulfillResponse response) {
    return _dynamicAsNonEmptyString(response.fulfilledAt) ?? response.updatedAt;
  }

  Future<void> _submitTransfer(WalletState state) async {
    final lang = state.languageCode;

    if (isRequestFlow && isExpired) {
      showMessage(
        AppStrings.get(state.languageCode, 'expired_code'),
        context: context,
        type: MessageType.error,
      );
      return;
    }

    if (isRequestFlow && isRequestStatusNotActive) {
      showMessage(
        _requestStatusMessage(state),
        context: context,
        type: MessageType.error,
      );
      return;
    }

    final amount = _parseAmountValue();
    final toAccountNumber = recipientController.text.trim();
    final purposeId = _resolvePurposeIdForSend(state);
    Currency? currency;
    final selectedId = state.selectedAssetId ?? '';
    for (final c in state.currencies) {
      if (c.id == selectedId) {
        currency = c;
        break;
      }
    }
    final selectedBalance = state.balances[selectedId];
    final selectedAssetSymbol = selectedBalance?.assetSymbol.isNotEmpty == true
        ? selectedBalance!.assetSymbol
        : (currency?.symbol ?? r'$');
    final selectedAssetType = (selectedBalance?.assetType ?? 'CURRENCY')
        .toUpperCase();

    if (amount == null || amount <= 0) {
      showMessage(
        AppStrings.get(lang, 'invalid_amount'),
        context: context,
        type: MessageType.error,
      );
      return;
    }

    if (!_isAmountWithinSelectedBalance(amount, state)) {
      showMessage(
        AppStrings.get(lang, 'insufficient_balance'),
        context: context,
        type: MessageType.error,
      );
      return;
    }
    if (toAccountNumber.isEmpty) {
      showMessage(
        AppStrings.get(lang, 'incorrect_account_msg'),
        context: context,
        type: MessageType.error,
      );
      return;
    }
    if (!isRequestFlow && purposeId == null) {
      showMessage(
        AppStrings.get(lang, 'select_purpose_send'),
        context: context,
        type: MessageType.error,
      );
      return;
    }

    setState(() {
      currentTransferState = TransferState.sending;
    });

    if (isRequestFlow) {
      final selectedBalance = state.balances[selectedId];
      final senderAccountNumber = selectedBalance?.accountNumber.trim() ?? '';

      if (senderAccountNumber.isEmpty) {
        setState(() {
          currentTransferState = TransferState.input;
        });
        showMessage(
          AppStrings.get(lang, 'transaction_failed'),
          context: context,
          type: MessageType.error,
        );
        return;
      }

      var requestId = (paymentRequestId ?? '').trim();
      if (requestId.isEmpty) {
        final fallbackCode = (referenceId ?? '').trim();
        if (fallbackCode.isNotEmpty) {
          final lookupResult = await _paymentRequestsApi.lookupPaymentRequest(
            requestCode: fallbackCode,
            languageCode: lang,
          );
          if (!mounted) return;

          if (lookupResult.isSuccess && lookupResult.data != null) {
            requestId = lookupResult.data!.id;
            setState(() {
              paymentRequestId = lookupResult.data!.id;
              requestStatus = lookupResult.data!.status;
            });
          }
        }
      }

      if (requestId.isEmpty) {
        setState(() {
          currentTransferState = TransferState.input;
        });
        showMessage(
          AppStrings.get(lang, 'transaction_failed'),
          context: context,
          type: MessageType.error,
        );
        return;
      }

      final fulfillResult = await _paymentRequestsApi.fulfillPaymentRequest(
        requestId: requestId,
        accountNumber: senderAccountNumber,
        idempotencyKey: _generateIdempotencyKey(),
        note: noteController.text.trim().isEmpty ? null : noteController.text,
        languageCode: lang,
      );

      if (!mounted) return;

      if (fulfillResult.isSuccess &&
          fulfillResult.data != null &&
          _isFulfilledStatus(fulfillResult.data!.status)) {
        setState(() {
          _lastSendResult = null;
          _lastFulfilledRequest = fulfillResult.data;
          requestStatus = fulfillResult.data!.status;
          currentTransferState = TransferState.success;
        });
        context.read<WalletBloc>().add(const WalletRefreshAllRequested());
        return;
      }

      setState(() {
        currentTransferState = TransferState.input;
      });
      showMessage(
        fulfillResult.errorMessage ??
            AppStrings.get(lang, 'transaction_failed'),
        context: context,
        type: MessageType.error,
      );
      return;
    }

    final result = await _transfersApi.sendTransfer(
      toAccountNumber: toAccountNumber,
      assetSymbol: selectedAssetSymbol,
      assetType: selectedAssetType,
      amount: amount,
      purposeId: purposeId!,
      note: noteController.text,
      idempotencyKey: _generateIdempotencyKey(),
      inputMethod: 'MANUAL',
    );

    if (!mounted) return;

    if (result.isSuccess && result.data != null && result.data!.isCompleted) {
      setState(() {
        _lastFulfilledRequest = null;
        _lastSendResult = result.data;
        currentTransferState = TransferState.success;
      });
      context.read<WalletBloc>().add(const WalletRefreshAllRequested());
      return;
    }

    setState(() {
      currentTransferState = TransferState.input;
    });
    showMessage(
      result.errorMessage ?? AppStrings.get(lang, 'transaction_failed'),
      context: context,
      type: MessageType.error,
    );
  }

  void _syncSuccessBackButton(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackButton(context, visible: false);
    });
  }

  void _syncModalBackgroundColor() {
    final modalColor = currentTransferState == TransferState.success
        ? const Color(0xffF4FFFA)
        : (isRequestFlow && (isExpired || isRequestStatusNotActive))
        ? const Color(0xffFDF3F3)
        : Colors.white;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackground(context, modalColor);
    });
  }

  @override
  Widget build(BuildContext context) {
    _syncModalBackgroundColor();

    if (currentTransferState == TransferState.success) {
      _syncSuccessBackButton(context);
      final state = context.read<WalletBloc>().state;
      final sendResult = _lastSendResult;
      final fulfilledRequest = _lastFulfilledRequest;

      if (sendResult != null) {
        final maskedSenderName = _maskNameIfNeeded(sendResult.sender.name);
        final receiverNameSource = sendResult.receiver.name.trim().isNotEmpty
            ? sendResult.receiver.name
            : (recipientAccountName ?? '');
        final maskedReceiverName = _maskNameIfNeeded(receiverNameSource);

        final senderAccount =
            '${sendResult.sender.accountNumber} $maskedSenderName'.trim();
        final recipientAccount = maskedReceiverName.isNotEmpty
            ? '${sendResult.receiver.accountNumber} $maskedReceiverName'.trim()
            : sendResult.receiver.accountNumber;
        final amount = _formatAmount(sendResult.amount);
        final currencySymbol = sendResult.currency.symbol;
        final reference = sendResult.transferId;
        final dateAndTimeString = _formatDateTimeForReceipt(
          sendResult.createdAt,
          state.languageCode,
        );
        final purpose = sendResult.purpose;
        final isCompleted = sendResult.isCompleted;

        return SuccessfulPage(
          senderAccount: senderAccount,
          recipientAccount: recipientAccount,
          amount: amount,
          currencySymbol: currencySymbol,
          reference: reference,
          dateAndTimeString: dateAndTimeString,
          type: AppStrings.get(state.languageCode, 'transfer_send'),
          purpose: purpose,
          isSuccess: isCompleted,
          onDone: () => Navigator.pop(context),
          onDownload: () {},
          onShare: () {},
          isFromQr: isFromQr,
          // Only pass phone fields when phone is unregistered
          recipientPhoneNumber:
              (currentInputType == RecipientInputType.phone &&
                  isPhoneRegistered == false)
              ? '+ ${_phoneForEdit ?? recipientController.text}'
              : null,
          recipientName:
              (currentInputType == RecipientInputType.phone &&
                  isPhoneRegistered == false)
              ? nameController.text
              : null,
          recipientId:
              (currentInputType == RecipientInputType.phone &&
                  isPhoneRegistered == false)
              ? idController.text
              : null,
        );
      }

      if (fulfilledRequest != null) {
        final selectedBalance = state.balances[state.selectedAssetId ?? ''];
        final senderAccount =
            selectedBalance?.accountNumber.trim().isNotEmpty == true
            ? '${selectedBalance!.accountNumber} ${state.maskedName}'.trim()
            : _getSenderAccountDisplay(state);

        final receiverNameSource =
            (maskedAccountName ?? recipientAccountName ?? '').trim();
        final maskedReceiverName = _maskNameIfNeeded(receiverNameSource);
        final recipientAccount = maskedReceiverName.isNotEmpty
            ? '${fulfilledRequest.requesterAccountNumber} $maskedReceiverName'
                  .trim()
            : fulfilledRequest.requesterAccountNumber;

        final amount = _formatAmount(fulfilledRequest.amount);
        final currencySymbol = fulfilledRequest.assetSymbol;
        final reference = _requestReferenceFromFulfill(fulfilledRequest);
        final dateAndTimeString = _formatDateTimeForReceipt(
          _requestDateFromFulfill(fulfilledRequest),
          state.languageCode,
        );
        final purpose = _displayPurposeName(
          state,
          qrPurpose ?? fulfilledRequest.purposeId,
        );
        final isCompleted = _isFulfilledStatus(fulfilledRequest.status);

        return SuccessfulPage(
          senderAccount: senderAccount,
          recipientAccount: recipientAccount,
          amount: amount,
          currencySymbol: currencySymbol,
          reference: reference,
          dateAndTimeString: dateAndTimeString,
          type: AppStrings.get(state.languageCode, 'send_deposits'),
          purpose: purpose,
          isSuccess: isCompleted,
          onDone: () => Navigator.pop(context),
          onDownload: () {},
          onShare: () {},
          isFromQr: true,
        );
      }

      return const SizedBox.shrink();
    }

    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final hasInactiveRequestBackground =
            isRequestFlow && (isExpired || isRequestStatusNotActive);
        Currency? currency;
        final selectedId = state.selectedAssetId ?? '';
        for (final c in state.currencies) {
          if (c.id == selectedId) {
            currency = c;
            break;
          }
        }
        final currencySymbol = currency?.symbol ?? r'$';
        return SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Directionality(
            textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              child: Container(
                color: hasInactiveRequestBackground
                    ? const Color(0xffFDF3F3)
                    : Colors.transparent,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back Button & Icon
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Column(
                            children: [
                              SvgPicture.asset(
                                TrydosWalletAssets.transferSend,
                                height: 40,
                                package: TrydosWalletStyles.packageName,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    AppStrings.get(
                                      state.languageCode,
                                      'transfer_send',
                                    ).toUpperCase(),
                                    style: TrydosWalletStyles.bodyMedium
                                        .copyWith(
                                          color: const Color(0xff1D1D1D),
                                          fontSize: 13,
                                        ),
                                  ),
                                  isRequestFlow
                                      ? Text(
                                          ' ${AppStrings.get(state.languageCode, 'request').toUpperCase()}',
                                          style: TrydosWalletStyles.bodyMedium
                                              .copyWith(
                                                color: const Color(0xff1D1D1D),
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        )
                                      : const SizedBox.shrink(),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Sender Account Card
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xff3C3C3C),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Color(0xffD3D3D3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildBalanceSection(state),
                                GestureDetector(
                                  onTap: _isSelectedBalanceLoading(state)
                                      ? null
                                      : _refreshSelectedBalance,
                                  child: Opacity(
                                    opacity: _isSelectedBalanceLoading(state)
                                        ? 0.6
                                        : 1,
                                    child: SvgPicture.asset(
                                      TrydosWalletAssets.reload,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                      height: 20,
                                      package: TrydosWalletStyles.packageName,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              AppStrings.get(
                                state.languageCode,
                                'sender_account',
                              ),
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _getSenderAccountDisplay(state),
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildAmountRow(state),
                          ],
                        ),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        AppStrings.get(state.languageCode, 'send_to'),
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 10),

                      SizedBox(
                        height:
                            (isRequestFlow &&
                                (isExpired || isRequestStatusNotActive))
                            ? (MediaQuery.of(context).size.height * 0.9 - 302)
                            : (MediaQuery.of(context).size.height * 0.9) - 380,
                        child: SingleChildScrollView(
                          controller: _formScrollController,
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(context).viewInsets.bottom,
                          ),
                          child: Column(
                            children: [
                              _buildRecipientInputSection(state),
                              const SizedBox(height: 5),

                              if (currentInputType ==
                                      RecipientInputType.phone &&
                                  isPhoneRegistered == false &&
                                  isRecipientVerified) ...[
                                _buildInputField(
                                  state: state,
                                  label: AppStrings.get(
                                    state.languageCode,
                                    'recipient_name_id',
                                  ),
                                  controller: nameController,
                                  hint: AppStrings.get(
                                    state.languageCode,
                                    'recipient_name_hint',
                                  ),
                                  focusNode: nameFocus,
                                  isVerified: isNameVerified,
                                  errorMessage: nameErrorMessage,
                                  onEdit: () =>
                                      setState(() => isNameVerified = false),
                                ),
                                const SizedBox(height: 5),
                                _buildInputField(
                                  state: state,
                                  label: AppStrings.get(
                                    state.languageCode,
                                    'recipient_id_num',
                                  ),
                                  controller: idController,
                                  hint: AppStrings.get(
                                    state.languageCode,
                                    'recipient_id_hint',
                                  ),
                                  focusNode: idFocus,
                                  isVerified: isIdVerified,
                                  errorMessage: idErrorMessage,
                                  onEdit: () =>
                                      setState(() => isIdVerified = false),
                                ),
                                const SizedBox(height: 5),
                              ],

                              _buildInputField(
                                state: state,
                                label:
                                    "${AppStrings.get(state.languageCode, 'enter')}${AppStrings.get(state.languageCode, 'amount_to_be_sent')}",
                                controller: amountController,
                                hint: '000,000',
                                focusNode: amountFocus,
                                isVerified: isAmountVerified,
                                isFromQr: false,
                                errorMessage: amountErrorMessage,
                                keyboardType: TextInputType.number,
                                enabled: isRequestFlow
                                    ? false
                                    : (currentInputType ==
                                              RecipientInputType.account
                                          ? isRecipientVerified
                                          : (isPhoneRegistered == true
                                                ? isRecipientVerified
                                                : (isRecipientVerified &&
                                                      isNameVerified &&
                                                      isIdVerified))),
                                onEdit: isRequestFlow
                                    ? null
                                    : () => setState(() {
                                        isAmountVerified = false;
                                        isEditingAmount = true;
                                        amountErrorMessage = null;
                                      }),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    if (isTransferVerifyLoading)
                                      const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                  ],
                                ),
                                suffixFollowsText: true,
                                suffix: Text(
                                  ' $currencySymbol',
                                  style: TrydosWalletStyles.bodyMedium.copyWith(
                                    color: const Color(0xff1D1D1D),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),

                              // Purpose Section
                              if (!isRequestFlow) ...[
                                AbsorbPointer(
                                  absorbing:
                                      currentInputType ==
                                          RecipientInputType.phone
                                      ? (isPhoneRegistered == false
                                            ? !(isIdVerified &&
                                                  isAmountVerified)
                                            : !(isRecipientVerified &&
                                                  isAmountVerified))
                                      : !(isRecipientVerified &&
                                            isAmountVerified),
                                  child: _buildPurposeSection(state),
                                ),
                              ],

                              if (isRequestFlow) ...[
                                _buildInputField(
                                  state: state,
                                  label: AppStrings.get(
                                    state.languageCode,
                                    'reference_id',
                                  ),
                                  controller: TextEditingController(
                                    text: referenceId,
                                  ),
                                  hint: '',
                                  focusNode: FocusNode(),
                                  isVerified: true,
                                  showMaskedName: false,
                                  enabled: false,
                                ),
                                const SizedBox(height: 5),
                                _buildInputField(
                                  state: state,
                                  label: AppStrings.get(
                                    state.languageCode,
                                    'purpose_of_request',
                                  ),
                                  controller: TextEditingController(
                                    text: _displayPurposeName(state, qrPurpose),
                                  ),
                                  hint: '',
                                  focusNode: FocusNode(),
                                  isVerified: true,
                                  showMaskedName: false,
                                  enabled: false,
                                ),
                                const SizedBox(height: 5),
                                _buildInputField(
                                  state: state,
                                  label: AppStrings.get(
                                    state.languageCode,
                                    'type',
                                  ),
                                  controller: TextEditingController(
                                    text: requestType,
                                  ),
                                  hint: '',
                                  focusNode: FocusNode(),
                                  isVerified: true,
                                  showMaskedName: false,
                                  enabled: false,
                                ),
                                const SizedBox(height: 5),
                                _buildInputField(
                                  state: state,
                                  label: AppStrings.get(
                                    state.languageCode,
                                    'valid_until',
                                  ),
                                  controller: TextEditingController(text: ''),
                                  customValueWidget: Text(
                                    _requestValidUntilText(state),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xff1D1D1D),
                                    ),
                                  ),
                                  hint: '',
                                  focusNode: FocusNode(),
                                  isVerified: true,
                                  showMaskedName: false,
                                  isExpired:
                                      (isRequestFlow &&
                                      (isExpired || isRequestStatusNotActive)),
                                  enabled: false,
                                  showTimeNote: true,
                                ),
                              ],

                              isRequestFlow
                                  ? const SizedBox(height: 10)
                                  : const SizedBox(height: 30),

                              if (isRequestFlow &&
                                  (isExpired || isRequestStatusNotActive))
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFF5F60),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    isExpired
                                        ? AppStrings.get(
                                            state.languageCode,
                                            'expired_code',
                                          )
                                        : _requestStatusMessage(state),
                                    style: TrydosWalletStyles.bodyMedium
                                        .copyWith(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                )
                              else
                                ...[],
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      (isRequestLookupLoading)
                          ? const Padding(
                              padding: EdgeInsets.only(bottom: 12),
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : (isRequestFlow &&
                                (isExpired || isRequestStatusNotActive))
                          ? SizedBox.shrink()
                          : Padding(
                              padding: const EdgeInsets.all(10),
                              child: _buildSendButton(state),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(WalletState state) {
    return Builder(
      builder: (context) {
        final isReadyToSend =
            (isRequestFlow || selectedPurpose != null) &&
            isAmountVerified &&
            !isRecipientLookupLoading &&
            !isTransferVerifyLoading &&
            (currentInputType == RecipientInputType.account
                ? isRecipientVerified
                : (isPhoneRegistered == true
                      ? isRecipientVerified
                      : (isNameVerified && isIdVerified)));

        return InkWell(
          onTap: isReadyToSend && currentTransferState != TransferState.sending
              ? () {
                  FocusScope.of(context).unfocus();
                  _submitTransfer(state);
                }
              : null,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset(
                  isRequestFlow
                      ? (!isReadyToSend
                            ? TrydosWalletAssets.sendDisable
                            : TrydosWalletAssets.transferSend)
                      : (!isReadyToSend
                            ? TrydosWalletAssets.sendDisable
                            : TrydosWalletAssets.transferSend),
                  height: 25,
                  package: TrydosWalletStyles.packageName,
                ),
                const SizedBox(height: 5),
                Text(
                  currentTransferState == TransferState.sending
                      ? AppStrings.get(state.languageCode, 'sending')
                      : (isRequestFlow
                            ? AppStrings.get(
                                state.languageCode,
                                'send_deposits',
                              )
                            : AppStrings.get(state.languageCode, 'send_label')),
                  style: TrydosWalletStyles.bodyLarge.copyWith(
                    color: isReadyToSend
                        ? const Color(0xff388CFF)
                        : const Color(0xff8D8D8D),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPurposeSection(WalletState state) {
    final purposeOptions = _purposeOptions(state);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffD3D3D3)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get(state.languageCode, 'select_purpose_send'),
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: purposeOptions.length,
              itemBuilder: (context, index) {
                return _buildChip(purposeOptions[index], state);
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            key: _noteRowKey,
            children: [
              SvgPicture.asset(
                TrydosWalletAssets.edit,
                height: 14,
                package: TrydosWalletStyles.packageName,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: noteController,
                  focusNode: noteFocus,
                  decoration: InputDecoration(
                    hintText: AppStrings.get(
                      state.languageCode,
                      'enter_note_receiver',
                    ),
                    hintStyle: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xffD3D3D3),
                      fontSize: 11,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 11,
                  ),
                ),
              ),
              if (noteController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    noteController.clear();
                    setState(() {});
                  },
                  child: SvgPicture.asset(
                    TrydosWalletAssets.close,
                    height: 16,
                    package: TrydosWalletStyles.packageName,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    Key? key,
    required WalletState state,
    required String label,
    String? inlineLabel,
    Widget? customTopLabelWidget,
    required String hint,
    String? prefixText,
    Widget? trailing,
    Widget? suffix,
    bool suffixFollowsText = false,
    bool isFromAccount = false,
    bool isVerified = false,
    bool isFromQr = false,
    bool isExpired = false,
    bool showTimeNote = false,
    Widget? customValueWidget,
    String? errorMessage,
    VoidCallback? onEdit,
    bool showQuestionIcon = false,
    bool showMaskedName = false,
    bool enabled = true,
    required FocusNode focusNode,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    bool isFocused = focusNode.hasFocus;
    Color borderColor = isFocused
        ? const Color(0xff388CFF)
        : const Color(0xffD3D3D3);

    final hasInactiveRequestStyle =
        isRequestFlow && (this.isExpired || isRequestStatusNotActive);

    if (errorMessage != null) {
      borderColor = const Color(0xffFF5F61);
    }

    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isVerified
            ? isRequestFlow
                  ? hasInactiveRequestStyle
                        ? const Color(0xffFDF3F3)
                        : const Color(0xffFCFCFC)
                  : const Color(0xffF7F7F7)
            : Colors.white,
        border: isVerified ? null : Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isVerified && onEdit != null)
                      GestureDetector(
                        onTap: onEdit,
                        child: Text(
                          AppStrings.get(state.languageCode, 'edit'),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xff388CFF),
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xff388CFF),
                          ),
                        ),
                      ),
                    if (isVerified && onEdit != null) const SizedBox(width: 4),
                    if (customTopLabelWidget != null && !isVerified)
                      Expanded(child: customTopLabelWidget)
                    else ...[
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          color: isRequestFlow
                              ? const Color(0xff8D8D8D)
                              : const Color(0xff1D1D1D),
                        ),
                      ),
                      if (showQuestionIcon && inlineLabel == null) ...[
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          TrydosWalletAssets.question,
                          package: TrydosWalletStyles.packageName,
                        ),
                      ],
                      if (inlineLabel != null) ...[
                        const SizedBox(width: 10),
                        const Text(
                          'inline label',
                          style: TextStyle(
                            fontSize: 10,
                            decoration: TextDecoration.underline,
                            decorationColor: Color(0xffD3D3D3),
                            color: Color(0xffD3D3D3),
                          ),
                        ),
                        const SizedBox(width: 4),
                        SvgPicture.asset(
                          TrydosWalletAssets.question,
                          package: TrydosWalletStyles.packageName,
                        ),
                      ],
                    ],
                  ],
                ),
                !isFromAccount || isVerified
                    ? SizedBox.shrink()
                    : const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Stack(
                        alignment: AlignmentDirectional.centerStart,
                        children: [
                          if (suffixFollowsText &&
                              suffix != null &&
                              !isVerified)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Opacity(
                                    opacity: 0,
                                    child: Text(
                                      controller?.text.isEmpty ?? true
                                          ? hint
                                          : controller!.text,
                                      style: TrydosWalletStyles.bodyMedium
                                          .copyWith(
                                            color: const Color(0xff1D1D1D),
                                            fontSize:
                                                (controller?.text.isEmpty ??
                                                    true)
                                                ? 13
                                                : 14,
                                            fontWeight:
                                                (controller?.text.isEmpty ??
                                                    true)
                                                ? FontWeight.normal
                                                : FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  suffix,
                                ],
                              ),
                            ),
                          if (isVerified)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child:
                                  customValueWidget ??
                                  Row(
                                    children: [
                                      if (isFromQr) ...[
                                        SvgPicture.asset(
                                          TrydosWalletAssets.realQr,
                                          height: 16,
                                          width: 16,
                                          package:
                                              TrydosWalletStyles.packageName,
                                        ),
                                        const SizedBox(width: 10),
                                      ],
                                      Text(
                                        controller?.text ?? '',
                                        style: TrydosWalletStyles.bodyMedium
                                            .copyWith(
                                              color: const Color(0xff1D1D1D),
                                              fontSize: 14,
                                              fontWeight:
                                                  ((int.tryParse(
                                                            controller!.text
                                                                .replaceAll(
                                                                  ',',
                                                                  '',
                                                                ),
                                                          ) ??
                                                          0) >
                                                      0)
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                      ),
                                      if (suffixFollowsText &&
                                          suffix != null) ...[
                                        const SizedBox(width: 4),
                                        suffix,
                                      ],
                                      if (!suffixFollowsText &&
                                          showMaskedName) ...[
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            isRequestFlow
                                                ? (maskedAccountName ?? '')
                                                : (recipientAccountName ?? ''),
                                            style: TrydosWalletStyles.bodyMedium
                                                .copyWith(
                                                  color: const Color(
                                                    0xff8D8D8D,
                                                  ),
                                                  fontSize: 11,
                                                ),
                                            overflow: TextOverflow.visible,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                            )
                          else
                            TextField(
                              controller: controller,
                              focusNode: focusNode,
                              enabled: enabled,
                              maxLines: 1,
                              keyboardType: keyboardType,
                              inputFormatters: inputFormatters,
                              cursorColor: const Color(0xff388CFF),
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: const Color(0xff1D1D1D),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                hintText: hint,
                                prefixText: prefixText,
                                prefixStyle: TrydosWalletStyles.bodyMedium
                                    .copyWith(
                                      color: const Color(0xff1D1D1D),
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                suffix: suffixFollowsText ? null : suffix,
                                hintStyle: TrydosWalletStyles.bodyMedium
                                    .copyWith(
                                      color: const Color(0xffD3D3D3),
                                      fontSize: 13,
                                    ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFF4F4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: TrydosWalletStyles.bodyMedium.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (isRequestFlow &&
                    !isExpired &&
                    showTimeNote &&
                    !isPermanentRequest)
                  const SizedBox(height: 5),
                if (isRequestFlow &&
                    !isExpired &&
                    showTimeNote &&
                    !isPermanentRequest)
                  Center(
                    child: Text(
                      AppStrings.get(
                        state.languageCode,
                        'cannot_use_after_expiry',
                      ),
                      style: TrydosWalletStyles.bodyMedium.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null && !isVerified) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceSection(WalletState state) {
    final selectedId = state.selectedAssetId ?? '';
    Currency? currency;
    for (final c in state.currencies) {
      if (c.id == selectedId) {
        currency = c;
        break;
      }
    }
    final symbol = currency?.displayName ?? r'$';
    final symbolImageUrl = currency?.symbolImageUrl;

    if (symbolImageUrl != null && symbolImageUrl.isNotEmpty) {
      final isSvg = symbolImageUrl.toLowerCase().endsWith('.svg');
      return Padding(
        padding: const EdgeInsetsDirectional.only(start: 5, top: 5),
        child: isSvg
            ? SvgPicture.network(
                symbolImageUrl,
                height: 20,
                fit: BoxFit.cover,
                placeholderBuilder: (_) => _buildFallbackSymbol(symbol),
              )
            : Image.network(
                symbolImageUrl,
                height: 20,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildFallbackSymbol(symbol),
              ),
      );
    }

    return Text(
      symbol,
      style: TrydosWalletStyles.bodyMedium.copyWith(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFallbackSymbol(String symbol) {
    return Text(
      symbol,
      style: TrydosWalletStyles.bodyMedium.copyWith(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getSenderAccountDisplay(WalletState state) {
    final balance = state.balances[state.selectedAssetId ?? ''];
    final accountId = balance?.accountId ?? '----';
    final subtypeRaw = balance?.accountSubtype ?? 'MAIN';
    final subtype = subtypeRaw.toUpperCase() == 'MAIN'
        ? AppStrings.get(state.languageCode, 'main_sub_account')
        : subtypeRaw;
    return '$subtype | $accountId | ${state.maskedName}';
  }

  Widget _buildAmountRow(WalletState state) {
    final balance = state.balances[state.selectedAssetId ?? ''];
    final isBalanceRefreshing = _isSelectedBalanceLoading(state);
    final amountStr = balance != null
        ? balance.available.toStringAsFixed(
            balance.available.truncateToDouble() == balance.available ? 0 : 2,
          )
        : '0';

    final selectedId = state.selectedAssetId ?? '';
    Currency? currency;
    for (final c in state.currencies) {
      if (c.id == selectedId) {
        currency = c;
        break;
      }
    }
    final symbol = currency?.symbol ?? r'$';
    final assetName = (currency != null)
        ? currency.localizedName(state.languageCode)
        : currency?.name ?? balance?.asset?.name ?? '';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        isBalanceRefreshing
            ? Padding(
                padding: const EdgeInsets.only(top: 20, right: 20, left: 20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                  constraints: BoxConstraints.tightFor(width: 16, height: 16),
                ),
              )
            : Text(
                (isBalanceHidden ? '****' : amountStr),
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  color: Colors.white,
                  fontSize: isBalanceRefreshing ? 16 : 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
        const SizedBox(width: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            isBalanceRefreshing
                ? SizedBox.shrink()
                : Text(
                    '$symbol | $assetName',
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  ),
            const SizedBox(width: 15),
            isBalanceRefreshing
                ? SizedBox.shrink()
                : GestureDetector(
                    onTap: () =>
                        setState(() => isBalanceHidden = !isBalanceHidden),
                    child: SvgPicture.asset(
                      TrydosWalletAssets.hide,
                      colorFilter: const ColorFilter.mode(
                        Color(0xffD3D3D3),
                        BlendMode.srcIn,
                      ),
                      height: 11,
                      package: TrydosWalletStyles.packageName,
                    ),
                  ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecipientInputSection(WalletState state) {
    return _buildInputField(
      isFromAccount: true,
      state: state,
      customTopLabelWidget: Row(
        children: [
          GestureDetector(
            onTap: () => _switchRecipientInputType(RecipientInputType.account),
            child: Text(
              '${AppStrings.get(state.languageCode, 'enter')}${AppStrings.get(state.languageCode, 'recipient_account')}${AppStrings.get(state.languageCode, 'or')}',
              style: TrydosWalletStyles.bodyMedium.copyWith(
                fontSize: 10,

                color: currentInputType == RecipientInputType.account
                    ? const Color(0xff1D1D1D)
                    : const Color(0xffD3D3D3),
              ),
            ),
          ),

          GestureDetector(
            onTap: () => _switchRecipientInputType(RecipientInputType.phone),
            child: Text(
              AppStrings.get(state.languageCode, 'phone_number'),
              style: TrydosWalletStyles.bodyMedium.copyWith(
                fontSize: 10,
                decoration: TextDecoration.underline,
                decorationColor: currentInputType == RecipientInputType.phone
                    ? const Color(0xff1D1D1D)
                    : const Color(0xffD3D3D3),
                color: currentInputType == RecipientInputType.phone
                    ? const Color(0xff1D1D1D)
                    : const Color(0xffD3D3D3),
              ),
            ),
          ),
          SizedBox(width: 5),
          SvgPicture.asset(
            TrydosWalletAssets.question,

            package: TrydosWalletStyles.packageName,
          ),
        ],
      ),
      label: currentInputType == RecipientInputType.account
          ? AppStrings.get(state.languageCode, 'recipient_account_num')
          : AppStrings.get(state.languageCode, 'recipient_phone_num'),
      controller: recipientController,
      hint: currentInputType == RecipientInputType.account
          ? AppStrings.get(state.languageCode, 'enter_recipient_acc')
          : AppStrings.get(state.languageCode, 'enter_recipient_phone'),
      focusNode: recipientFocus,
      isVerified: isRecipientVerified,
      isFromQr: isFromQr,
      showMaskedName: true,
      errorMessage: recipientErrorMessage,
      keyboardType: currentInputType == RecipientInputType.phone
          ? TextInputType.phone
          : TextInputType.number,
      onEdit: isFromQr
          ? null
          : () => setState(() {
              _resetRecipientLookupState();
            }),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (currentInputType == RecipientInputType.account &&
              isRecipientLookupLoading) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
          ],
          if (recipientController.text.isEmpty) ...[
            GestureDetector(
              onTap: () async {
                ClipboardData? data = await Clipboard.getData(
                  Clipboard.kTextPlain,
                );
                if (data != null && data.text != null) {
                  recipientController.text = data.text!;
                }
              },
              child: Text(
                AppStrings.get(state.languageCode, 'paste'),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff388CFF),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xff388CFF),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                final result = await showWalletModal<String>(
                  context: context,
                  builder: (context, sc) =>
                      QRScannerPage(fromQR: true, appairBack: true),
                );
                if (result == null) {
                  return;
                }

                await _applyScannedRaw(result);
              },
              child: SvgPicture.asset(
                TrydosWalletAssets.qr,
                height: 14,
                package: TrydosWalletStyles.packageName,
              ),
            ),
          ] else
            GestureDetector(
              onTap: () => setState(() {
                recipientController.clear();
                _resetRecipientLookupState();
              }),
              child: SvgPicture.asset(
                TrydosWalletAssets.close,
                height: 18,
                package: TrydosWalletStyles.packageName,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(TransferPurpose purpose, WalletState state) {
    final isSelected = selectedPurpose == purpose.id;
    return GestureDetector(
      onTap: () => setState(() => selectedPurpose = purpose.id),
      child: Container(
        margin: const EdgeInsetsDirectional.only(end: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffFCFCFC) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xff5D5C5D)
                : const Color(0xffD3D3D3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          purpose.name,
          style: TrydosWalletStyles.bodyMedium.copyWith(
            color: const Color(0xff1D1D1D),
            fontSize: isSelected ? 12 : 11,
          ),
        ),
      ),
    );
  }
}

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove any existing commas
    String cleanedText = newValue.text.replaceAll(',', '');

    // Simple 000,000 formatting for 6 digits
    String formatted = '';
    if (cleanedText.length > 3) {
      formatted =
          '${cleanedText.substring(0, cleanedText.length - 3)},${cleanedText.substring(cleanedText.length - 3)}';
    } else {
      formatted = cleanedText;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
