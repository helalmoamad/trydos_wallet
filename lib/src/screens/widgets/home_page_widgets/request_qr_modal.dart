// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/utils/payment_request_crypto.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

enum RequestQRState { filling, generating, finalQR }

class RequestQRModal extends StatefulWidget {
  final VoidCallback? onBack;
  final String? accountName;
  final String? accountNumber;
  final ValueChanged<bool>? onFinalStateChanged;

  const RequestQRModal({
    super.key,

    this.onBack,
    this.accountName,
    this.accountNumber,
    this.onFinalStateChanged,
  });

  @override
  State<RequestQRModal> createState() => _RequestQRModalState();
}

class _RequestQRModalState extends State<RequestQRModal> {
  final GlobalKey _cardKey = GlobalKey();
  final ScrollController _formScrollController = ScrollController();
  final GlobalKey _amountFieldKey = GlobalKey();
  final GlobalKey _referenceFieldKey = GlobalKey();
  final GlobalKey _noteFieldKey = GlobalKey();
  final GlobalKey _noteRowKey = GlobalKey();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _referenceFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();
  RequestQRState _state = RequestQRState.filling;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedPurpose = '';
  String _selectedExpiry = 'always';

  bool _isDownloading = false;
  bool _isSharing = false;
  Timer? _expiryTicker;
  DateTime? _responseExpiryTime;
  String? _encryptedRequestQrPayload;
  ValueNotifier<Color>? _modalBackgroundNotifier;

  final String _maskedName = '*******';
  bool _isNameMasked = false;

  void _notifyFinalStateChanged() {
    widget.onFinalStateChanged?.call(_state == RequestQRState.finalQR);
  }

  String get _accountName {
    final fromWidget = widget.accountName?.trim() ?? '';
    if (fromWidget.isNotEmpty) return fromWidget;
    return Balance.lastMyAccountsPrimaryWallet?.accountName ?? '';
  }

  String get _accountNumber {
    final fromWidget = widget.accountNumber?.trim() ?? '';
    if (fromWidget.isNotEmpty) return fromWidget;
    return Balance.lastMyAccountsPrimaryWallet?.accountNumber ?? '';
  }

  final List<String> _expiryOptions = [
    'always',
    'minute_1',
    'minutes_3',
    'minutes_15',
    'hour_1',
    'hours_24',
  ];

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(const WalletTransferPurposesLoadRequested());
    _amountController.addListener(_onFormChanged);
    _referenceController.addListener(_onFormChanged);

    _amountFocusNode.addListener(() {
      if (_amountFocusNode.hasFocus) {
        _scrollFieldIntoView(_amountFieldKey);
      }
    });
    _referenceFocusNode.addListener(() {
      if (_referenceFocusNode.hasFocus) {
        _scrollFieldIntoView(_referenceFieldKey);
      }
    });
    _noteFocusNode.addListener(() {
      if (_noteFocusNode.hasFocus) {
        _scrollFieldIntoView(_noteRowKey);
        Future.delayed(const Duration(milliseconds: 260), () {
          if (!mounted || !_noteFocusNode.hasFocus) return;
          _scrollFieldIntoView(_noteRowKey);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _modalBackgroundNotifier ??= walletModalBackgroundNotifierOf(context);
  }

  DateTime? _parseResponseExpiry(dynamic value) {
    if (value == null) return null;
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value)?.toLocal();
    }
    return null;
  }

  bool get _isFinalQrExpired =>
      _state == RequestQRState.finalQR &&
      _responseExpiryTime != null &&
      DateTime.now().isAfter(_responseExpiryTime!);

  void _restartExpiryWatcher() {
    _expiryTicker?.cancel();
    if (_responseExpiryTime == null) return;

    _expiryTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_isFinalQrExpired) {
        _expiryTicker?.cancel();
      }
    });
  }

  void _syncModalBackground() {
    final backgroundColor = _isFinalQrExpired
        ? const Color(0xffFDF3F3)
        : Colors.white;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackground(context, backgroundColor);
    });
  }

  void _resetModalBackground() {
    if (!mounted) return;
    setWalletModalBackground(context, Colors.white);
  }

  void _scrollFieldIntoView(GlobalKey fieldKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        final fieldContext = fieldKey.currentContext;
        if (fieldContext == null) return;

        Scrollable.ensureVisible(
          fieldContext,
          alignment: 0.2,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    });
  }

  @override
  void dispose() {
    // Ensure parent modal returns to default background when this page closes.
    _modalBackgroundNotifier?.value = Colors.white;
    _expiryTicker?.cancel();
    _formScrollController.dispose();
    _amountFocusNode.dispose();
    _referenceFocusNode.dispose();
    _noteFocusNode.dispose();
    _amountController.dispose();
    _referenceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<TransferPurpose> _purposeOptions(WalletState state) {
    return state.transferPurposes;
  }

  static const PrettyQrDecoration _receiveQrDecoration = PrettyQrDecoration(
    shape: PrettyQrSquaresSymbol(
      color: Color(0xff1D1D1D),
      density: 0.98,
      rounding: 0.60,
      unifiedFinderPattern: true,
    ),
    quietZone: PrettyQrQuietZone.modules(0),
  );

  String _purposeName(WalletState state, String purposeId) {
    for (final purpose in _purposeOptions(state)) {
      if (purpose.id == purposeId) {
        return purpose.name;
      }
    }
    return purposeId;
  }

  void _onFormChanged() {
    setState(() {});
  }

  bool get _isFormValid {
    return _amountController.text.isNotEmpty &&
        _referenceController.text.isNotEmpty &&
        _selectedPurpose.isNotEmpty;
  }

  Duration? _expiryDuration() {
    switch (_selectedExpiry) {
      case 'minute_1':
        return const Duration(minutes: 1);
      case 'minutes_3':
        return const Duration(minutes: 3);
      case 'minutes_15':
        return const Duration(minutes: 15);
      case 'hour_1':
        return const Duration(hours: 1);
      case 'hours_24':
        return const Duration(hours: 24);
      default:
        return null;
    }
  }

  DateTime? _expiryDateTime() {
    final duration = _expiryDuration();
    if (duration == null) {
      return null;
    }
    return DateTime.now().add(duration);
  }

  String _currencySymbol(WalletState state) {
    final selectedSymbol = state.selectedAssetSymbol.trim();
    if (selectedSymbol.isNotEmpty) {
      return selectedSymbol;
    }

    final selectedId = state.selectedAssetId;
    if (selectedId != null) {
      for (final currency in state.currencies) {
        if (currency.id == selectedId && currency.symbol.trim().isNotEmpty) {
          return currency.symbol;
        }
      }
    }
    if (state.currencies.isNotEmpty) {
      return state.currencies.first.symbol;
    }
    return 'SYP';
  }

  String _currencyDisplayName(WalletState state) {
    final selectedId = state.selectedAssetId;
    if (selectedId != null) {
      for (final currency in state.currencies) {
        if (currency.id == selectedId) {
          final localized = currency.localizedName(state.languageCode);
          if (localized.isNotEmpty) return localized;
          if (currency.symbol.isNotEmpty) return currency.symbol;
        }
      }
    }

    if (state.currencies.isNotEmpty) {
      final first = state.currencies.first;
      final localized = first.localizedName(state.languageCode);
      if (localized.isNotEmpty) return localized;
      if (first.symbol.isNotEmpty) return first.symbol;
    }
    return AppStrings.get(state.languageCode, 'american_dollars');
  }

  String _selectedAssetType(WalletState state) {
    final selectedType = state.selectedAssetType.trim().toUpperCase();
    if (selectedType.isNotEmpty) {
      return selectedType == 'METAL' ? 'METAL' : 'CURRENCY';
    }

    final selectedId = state.selectedAssetId;

    if (selectedId != null) {
      for (final currency in state.currencies) {
        if (currency.id == selectedId) {
          final type = currency.assetType.toUpperCase();
          return type == 'METAL' ? 'METAL' : 'CURRENCY';
        }
      }
    }

    final type = (state.balances[selectedId ?? '']?.assetType ?? 'CURRENCY')
        .toUpperCase();
    return type == 'METAL' ? 'METAL' : 'CURRENCY';
  }

  String _monthKey(int month) {
    const months = [
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
    return months[month - 1];
  }

  String _monthName(WalletState state, int month) {
    return AppStrings.get(state.languageCode, _monthKey(month));
  }

  String _validUntilText(WalletState state) {
    final expiry = _expiryDateTime();
    if (expiry == null) {
      return AppStrings.get(state.languageCode, 'always');
    }

    return '${expiry.hour.toString().padLeft(2, '0')}:${expiry.minute.toString().padLeft(2, '0')} | ${expiry.day} ${AppStrings.get(state.languageCode, _monthKey(expiry.month))} ${expiry.year}';
  }

  String _requestQrPayload(WalletState state) {
    return QrTransferPayloadCodec.buildRequestPayload(
      accountNumber: _accountNumber,
      accountName: _accountName,
      currencySymbol: _currencySymbol(state),
      amount: _amountController.text.trim(),
      reference: _referenceController.text.trim(),
      purpose: _selectedPurpose,
      requestType: AppStrings.get(state.languageCode, 'deposit_request'),
      expiryTime: _expiryDateTime(),
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );
  }

  void _generateRequest() async {
    if (!_isFormValid) return;

    // Generate idempotency key
    final idempotencyKey = DateTime.now().millisecondsSinceEpoch.toString();

    // Get expiry minutes from selected expiry
    int? expiryMinutes;
    if (_selectedExpiry != 'always') {
      switch (_selectedExpiry) {
        case 'minute_1':
          expiryMinutes = 1;
          break;
        case 'minutes_3':
          expiryMinutes = 3;
          break;
        case 'minutes_15':
          expiryMinutes = 15;
          break;
        case 'hour_1':
          expiryMinutes = 60;
          break;
        case 'hours_24':
          expiryMinutes = 1440;
          break;
      }
    }

    // Emit the event to create payment request
    if (mounted) {
      context.read<WalletBloc>().add(
        WalletPaymentRequestCreated(
          accountNumber: _accountNumber,
          assetType: _selectedAssetType(context.read<WalletBloc>().state),
          assetSymbol: _currencySymbol(context.read<WalletBloc>().state),
          amount: double.parse(_amountController.text),
          purposeId: _selectedPurpose,
          reference: _referenceController.text,
          note: _noteController.text.isNotEmpty ? _noteController.text : null,
          expiryMinutes: expiryMinutes,
          isPermanent: _selectedExpiry == 'always',
          idempotencyKey: idempotencyKey,
        ),
      );

      setState(() => _state = RequestQRState.generating);
    }
  }

  Future<Uint8List?> _captureCard() async {
    try {
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing QR card: $e");
      return null;
    }
  }

  Future<void> _handleDownload(WalletState state) async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isDownloading = true);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/request_qr_${_referenceController.text}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        await Gal.putImage(imagePath);

        showMessage(
          AppStrings.get(state.languageCode, 'saved_successfully'),

          context: context,
          type: MessageType.success,
        );
      }
    } catch (e) {
      showMessage(
        AppStrings.get(state.languageCode, 'failed_to_save'),

        context: context,
        type: MessageType.error,
      );
    }

    if (mounted) {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShare(WalletState state) async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isSharing = true);

    try {
      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/request_qr_${_referenceController.text}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: AppStrings.get(state.languageCode, 'payment_request_for')
              .replaceAll('{amount}', _amountController.text)
              .replaceAll('{currency}', _currencySymbol(state)),
        );
      }
    } catch (e) {
      debugPrint('Error sharing QR card: $e');
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletBloc, WalletState>(
      listener: (context, state) {
        // Handle payment request response
        if (state.paymentRequestStatus == WalletStatus.success &&
            state.paymentRequestResponse != null) {
          // Update state to show final QR view with response data
          if (mounted) {
            setState(() {
              _state = RequestQRState.finalQR;
              _responseExpiryTime = _parseResponseExpiry(
                state.paymentRequestResponse!.expiresAt,
              );
              _encryptedRequestQrPayload = PaymentRequestCrypto.encrypt(
                state.paymentRequestResponse!.qrData.code,
                _accountNumber,
              );
            });
            _restartExpiryWatcher();
            _notifyFinalStateChanged();
          }
        } else if (state.paymentRequestStatus == WalletStatus.failure) {
          // Show error message
          showMessage(
            state.paymentRequestErrorMessage ??
                AppStrings.get(state.languageCode, 'failed'),
            context: context,
            type: MessageType.error,
          );
          if (mounted) {
            setState(() {
              _state = RequestQRState.filling;
              _responseExpiryTime = null;
              _encryptedRequestQrPayload = null;
            });
            _notifyFinalStateChanged();
          }
        }
      },
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          _syncModalBackground();
          final qrPayload = _requestQrPayload(state);
          final effectiveQrPayload =
              (_state == RequestQRState.finalQR &&
                  state.paymentRequestResponse != null)
              ? (_encryptedRequestQrPayload ??
                    PaymentRequestCrypto.encrypt(
                      state.paymentRequestResponse!.qrData.code,
                      _accountNumber,
                    ))
              : qrPayload;
          final validUntilText = _validUntilText(state);
          final currencyDisplayName = _currencyDisplayName(state);
          return Directionality(
            textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: SizedBox(
              height: 850.h,
              child: Stack(
                children: [
                  // Hidden card for screen capture
                  PositionedDirectional(
                    start: -4000,
                    top: -4000,
                    child: RepaintBoundary(
                      key: _cardKey,
                      child: Material(
                        type: MaterialType.transparency,
                        child: _CleanRequestQRCard(
                          accountName: _isNameMasked
                              ? _maskedName
                              : _accountName,
                          accountNumber: _accountNumber,
                          currencyDisplayName: currencyDisplayName,
                          qrPayload: effectiveQrPayload,
                          amount: _amountController.text,
                          currencySymbol: _currencySymbol(state),
                          reference: _referenceController.text,
                          purpose: _purposeName(state, _selectedPurpose),
                          validUntilText: validUntilText,
                          requestType: AppStrings.get(
                            state.languageCode,
                            'deposit_request',
                          ),
                          note: _noteController.text,
                          languageCode: state.languageCode,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 850.h,
                    child: Container(
                      color: _isFinalQrExpired
                          ? const Color(0xffFDF3F3)
                          : Colors.transparent,
                      child: Column(
                        children: [
                          // Trydos Logo
                          SvgPicture.asset(
                            TrydosWalletAssets.trydos,
                            height: 30.h,
                            package: TrydosWalletStyles.packageName,
                          ),
                          SizedBox(height: 20.h),

                          if (_state == RequestQRState.finalQR &&
                              state.paymentRequestResponse != null) ...[
                            // Final QR View with Response Data
                            _buildFinalQRView(state),
                          ] else ...[
                            // Filling Form (with loading state only on button)
                            _buildFormView(state),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFormView(WalletState state) {
    return Expanded(
      child: Column(
        children: [
          // Faded QR Placeholder
          Column(
            children: [
              SvgPicture.asset(
                TrydosWalletAssets.hideQr,
                height: 250.h,
                package: TrydosWalletStyles.packageName,
              ),
              SizedBox(height: 5.h),
              Text(
                _accountNumber,
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  color: const Color(0xff404040),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              controller: _formScrollController,

              child: Column(
                children: [
                  SizedBox(height: 18.h),
                  // Account Details (Masked)
                  _buildInfoBox(
                    AppStrings.get(state.languageCode, 'account_name'),
                    _isNameMasked ? _maskedName : _accountName,
                    isMasked: true,
                    onMaskToggle: () =>
                        setState(() => _isNameMasked = !_isNameMasked),
                    isMaskedNow: _isNameMasked,
                    state: state,
                  ),
                  SizedBox(height: 5.h),
                  _buildInfoBox(
                    AppStrings.get(state.languageCode, 'account_number'),
                    '$_accountNumber  ${_currencyDisplayName(state)}',
                    state: state,
                  ),
                  SizedBox(height: 5.h),
                  // Amount and Reference
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          fieldKey: _amountFieldKey,
                          label: AppStrings.get(
                            state.languageCode,
                            'enter_amount',
                          ),
                          controller: _amountController,
                          suffixText: _currencySymbol(state),
                          focusNode: _amountFocusNode,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildTextField(
                          fieldKey: _referenceFieldKey,
                          label: AppStrings.get(
                            state.languageCode,
                            'enter_reference',
                          ),
                          controller: _referenceController,
                          focusNode: _referenceFocusNode,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  // Combined Purpose and Note
                  _buildPurposeAndNoteSection(state),
                  SizedBox(height: 5.h),
                  // Expiry Selection
                  _buildChipSelection(
                    label: AppStrings.get(state.languageCode, 'valid_until'),
                    options: _expiryOptions,
                    selectedItem: _selectedExpiry,
                    onSelected: (val) => setState(() => _selectedExpiry = val),
                    state: state,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.only(bottom: 35.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(width: 20.w),
                _buildGenerateButton(state),
                _buildCancelButton(state),
              ],
            ),
          ),

          // Action Buttons
        ],
      ),
    );
  }

  Widget _buildFinalQRView(WalletState state) {
    final response = state.paymentRequestResponse;
    if (response == null) return const SizedBox.shrink();
    final isPermanent = response.isPermanent && _responseExpiryTime == null;
    final expiryText = isPermanent
        ? AppStrings.get(state.languageCode, 'always')
        : _finalValidUntilText(state);
    final fieldBackground = _isFinalQrExpired
        ? const Color(0xffFDF3F3)
        : const Color(0xffFCFCFC);

    return Expanded(
      child: Column(
        children: [
          // Vibrant QR Code
          Container(
            padding: EdgeInsets.symmetric(vertical: 0.h),
            decoration: BoxDecoration(
              color: _isFinalQrExpired ? const Color(0xffFDF3F3) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox.square(
                  dimension: 250.h,
                  child: PrettyQrView.data(
                    data:
                        _encryptedRequestQrPayload ??
                        PaymentRequestCrypto.encrypt(
                          response.qrData.code,
                          _accountNumber,
                        ),
                    errorCorrectLevel: QrErrorCorrectLevel.M,
                    decoration: _receiveQrDecoration,
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  _isFinalQrExpired
                      ? AppStrings.get(state.languageCode, 'expired_code')
                      : _accountNumber,
                  style: context.textTheme.bodyMedium?.mq.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(height: 18.h),
                  // Account Details
                  _buildInfoBox(
                    AppStrings.get(state.languageCode, 'account_name'),
                    _isNameMasked ? _maskedName : _accountName,
                    isMasked: true,
                    onMaskToggle: () =>
                        setState(() => _isNameMasked = !_isNameMasked),
                    isMaskedNow: _isNameMasked,
                    backgroundColor: fieldBackground,
                    state: state,
                  ),
                  SizedBox(height: 5.h),
                  _buildSummaryBox(
                    AppStrings.get(state.languageCode, 'account_number'),
                    '${response.requesterAccountNumber}  ${_currencyDisplayName(state)}',
                    backgroundColor: fieldBackground,
                  ),
                  SizedBox(height: 5.h),
                  // Transaction Details
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryBox(
                          AppStrings.get(state.languageCode, 'amount'),
                          '${response.amount} ${response.assetSymbol}',
                          backgroundColor: fieldBackground,
                        ),
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: _buildSummaryBox(
                          AppStrings.get(state.languageCode, 'reference'),
                          _referenceController.text,
                          backgroundColor: fieldBackground,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryBox(
                          AppStrings.get(
                            state.languageCode,
                            'purpose_of_request',
                          ),
                          _purposeName(state, _selectedPurpose),
                          backgroundColor: fieldBackground,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: _buildSummaryBox(
                          AppStrings.get(state.languageCode, 'type'),
                          response.assetType,
                          backgroundColor: fieldBackground,
                        ),
                      ),
                    ],
                  ),

                  // Expiry Summary
                  SizedBox(height: 5.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 10.h,
                    ),
                    decoration: BoxDecoration(
                      color: fieldBackground,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get(state.languageCode, 'valid_until'),
                          style: context.textTheme.bodyMedium?.rq.copyWith(
                            color: const Color(0xff8D8D8D),
                            fontSize: 11.sp,
                          ),
                        ),
                        SizedBox(height: 10.h),
                        Container(
                          height: 30.h,
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                            horizontal: 15.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: _isFinalQrExpired
                                  ? const Color(0xffFDF3F3)
                                  : const Color(0xffD3D3D3),
                            ),
                            borderRadius: BorderRadius.circular(15.r),
                            color: fieldBackground,
                          ),
                          child: Text(
                            expiryText,
                            style: context.textTheme.bodyMedium?.mq.copyWith(
                              color: const Color(0xff1D1D1D),
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 15.h),
                  (isPermanent || _isFinalQrExpired)
                      ? const SizedBox.shrink()
                      : Center(
                          child: Text(
                            AppStrings.get(
                              state.languageCode,
                              'cannot_use_after_expiry',
                            ),
                            style: context.textTheme.bodyMedium?.mq.copyWith(
                              color: const Color(0xff1D1D1D),
                              fontSize: 11.sp,
                            ),
                          ),
                        ),
                  _isFinalQrExpired
                      ? _buildExpiredBar(state)
                      : SizedBox.shrink(),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: 5.h, bottom: 35.h),
            child: _isFinalQrExpired
                ? SizedBox.shrink()
                : _buildActionRow(state),
          ),
        ],
      ),
    );
  }

  String _finalValidUntilText(WalletState state) {
    final expiry = _responseExpiryTime;
    if (expiry == null) {
      return '--';
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
        '$mmss ${AppStrings.get(state.languageCode, 'minutes_until')}$timeStr | ${expiry.day} ${_monthName(state, expiry.month)} ${expiry.year}';
    return dateStr;
  }

  Widget _buildExpiredBar(WalletState state) {
    return Container(
      width: double.infinity,
      height: 30.h,

      padding: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xffFF5F61),
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: Alignment.center,
      child: Text(
        AppStrings.get(state.languageCode, 'expired_code'),
        style: context.textTheme.bodyMedium?.bq.copyWith(
          color: Colors.white,
          fontSize: 11.sp,
        ),
      ),
    );
  }

  Widget _buildTextField({
    Key? fieldKey,
    required String label,
    required TextEditingController controller,
    FocusNode? focusNode,
    String? suffixText,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    return Container(
      key: fieldKey,
      height: 56.h,
      decoration: BoxDecoration(
        color: const Color(0xffFFFFFF).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: const Color(0xffD3D3D3)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 16.h, color: const Color(0xffC4C2C2)),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: keyboardType,
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 13.sp,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffixText != null)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    suffixText,
                    style: context.textTheme.bodyMedium?.rq.copyWith(
                      color: const Color(0xff8D8D8D),
                      fontSize: 13.sp,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    String label,
    String value, {
    bool isMasked = false,
    VoidCallback? onMaskToggle,
    bool isMaskedNow = false,
    Color backgroundColor = const Color(0xffFCFCFC),
    WalletState? state,
  }) {
    return Stack(
      children: [
        Container(
          width: double.infinity,

          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(15.r),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff8D8D8D),
                  fontSize: 11.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 5),

              Text(
                value,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        PositionedDirectional(
          top: 16.h,
          end: 10.w,

          child: (isMasked)
              ? GestureDetector(
                  onTap: onMaskToggle,
                  child: SvgPicture.asset(
                    TrydosWalletAssets.hide,
                    height: 14.h,
                    package: TrydosWalletStyles.packageName,
                    colorFilter: ColorFilter.mode(
                      isMaskedNow
                          ? const Color(0xff1D1D1D)
                          : const Color(0xff8D8D8D),
                      BlendMode.srcIn,
                    ),
                  ),
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildPurposeAndNoteSection(WalletState state) {
    final purposeOptions = _purposeOptions(state);
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: const Color(0xffD3D3D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get(state.languageCode, 'select_purpose_request'),
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 5.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: purposeOptions.map((option) {
                final isSelected = _selectedPurpose == option.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPurpose = option.id);
                  },
                  child: Container(
                    height: 30.h,
                    margin: EdgeInsetsDirectional.only(end: 5.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xffFCFCFC)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xff388CFF)
                            : const Color(0xffD3D3D3),
                      ),
                    ),
                    child: Text(
                      option.name,
                      style: context.textTheme.bodyMedium?.rq.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: isSelected ? 12.sp : 11.sp,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            key: _noteRowKey,
            children: [
              SvgPicture.asset(
                TrydosWalletAssets.edit,
                height: 14.h,
                package: TrydosWalletStyles.packageName,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: TextField(
                  key: _noteFieldKey,
                  controller: _noteController,
                  focusNode: _noteFocusNode,
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 13.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.get(
                      state.languageCode,
                      'enter_note_receiver',
                    ),
                    hintStyle: TrydosWalletStyles.bodySmall.copyWith(
                      color: const Color(0xffD3D3D3),
                      fontSize: 12.sp,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(
    String label,
    String value, {
    bool isBold = false,
    int maxLines = 1,
    Color backgroundColor = const Color(0xffFCFCFC),
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChipSelection({
    required String label,
    required List<String> options,
    required String selectedItem,
    required Function(String) onSelected,
    required WalletState state,
  }) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: const Color(0xffD3D3D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 9.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final isSelected = selectedItem == option;
                return GestureDetector(
                  onTap: () => onSelected(option),
                  child: Container(
                    height: 30.h,
                    margin: EdgeInsetsDirectional.only(end: 5.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xffFCFCFC)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(15.r),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xff388CFF)
                            : const Color(0xffD3D3D3),
                      ),
                    ),
                    child: Text(
                      AppStrings.get(state.languageCode, option),
                      style: context.textTheme.bodyMedium?.rq.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: isSelected ? 12.sp : 11.sp,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedExpiry != 'always') ...[
            const SizedBox(height: 5),
            Container(
              padding: EdgeInsets.symmetric(vertical: 5.h),
              width: double.infinity,

              child: Center(
                child: Text(
                  AppStrings.get(state.languageCode, 'cannot_use_after_expiry'),
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateButton(WalletState state) {
    final isValid = _isFormValid;
    final isLoading = _state == RequestQRState.generating;
    return GestureDetector(
      onTap: (isValid && !isLoading) ? _generateRequest : null,
      child: Column(
        children: [
          Container(
            height: 30.h,

            padding: EdgeInsets.all(5.h),
            child: SvgPicture.asset(
              TrydosWalletAssets.generate,
              package: TrydosWalletStyles.packageName,
              colorFilter: ColorFilter.mode(
                isValid ? const Color(0xff388CFF) : const Color(0xff8D8D8D),
                BlendMode.srcIn,
              ),
            ),
          ),
          Text(
            isLoading
                ? '${AppStrings.get(state.languageCode, 'generate_request')}...'
                : AppStrings.get(state.languageCode, 'generate_request'),
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: isValid
                  ? const Color(0xff388CFF)
                  : const Color(0xff5D5C5D),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(WalletState state) {
    if (_state == RequestQRState.generating) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        _resetModalBackground();
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.pop(context);
        }
      },
      child: Column(
        children: [
          Container(
            height: 30.h,

            padding: EdgeInsets.all(5.h),
            child: SvgPicture.asset(
              TrydosWalletAssets.cancel,

              package: TrydosWalletStyles.packageName,
            ),
          ),
          Text(
            AppStrings.get(state.languageCode, 'cancel'),
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff5D5C5D),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(WalletState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionIcon(
          TrydosWalletAssets.copy,
          AppStrings.get(state.languageCode, 'copy'),
          () {
            Clipboard.setData(ClipboardData(text: _accountNumber));
            showMessage(
              AppStrings.get(state.languageCode, 'copy_clipboard'),
              context: context,
              type: MessageType.success,
            );
          },
        ),
        _buildActionIcon(
          TrydosWalletAssets.download,
          AppStrings.get(state.languageCode, 'download'),
          () => _handleDownload(state),
          isLoading: _isDownloading,
        ),
        _buildActionIcon(
          TrydosWalletAssets.share,
          AppStrings.get(state.languageCode, 'share'),
          () => _handleShare(state),
          isLoading: _isSharing,
        ),
      ],
    );
  }

  Widget _buildActionIcon(
    String asset,
    String label,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xff1D1D1D),
                  ),
                )
              : SvgPicture.asset(
                  asset,
                  height: 20.h,
                  package: TrydosWalletStyles.packageName,
                ),
          const SizedBox(height: 8),
          Text(
            label,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanRequestQRCard extends StatelessWidget {
  final String accountName;
  final String accountNumber;
  final String currencyDisplayName;
  final String qrPayload;
  final String amount;
  final String currencySymbol;
  final String reference;
  final String purpose;
  final String requestType;
  final String validUntilText;
  final String note;
  final String languageCode;

  const _CleanRequestQRCard({
    required this.accountName,
    required this.accountNumber,
    required this.currencyDisplayName,
    required this.qrPayload,
    required this.amount,
    required this.currencySymbol,
    required this.reference,
    required this.purpose,
    required this.requestType,
    required this.validUntilText,
    required this.note,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = languageCode == 'ar' || languageCode == 'ku';
    final isAlways = validUntilText == AppStrings.get(languageCode, 'always');

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: 1.sw,
        padding: EdgeInsets.symmetric(horizontal: 30.w, vertical: 100.h),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SvgPicture.asset(
              TrydosWalletAssets.trydos,
              height: 40.h,
              package: TrydosWalletStyles.packageName,
            ),
            SizedBox(height: 20.h),
            SizedBox.square(
              dimension: 300.h,
              child: PrettyQrView.data(
                data: qrPayload,
                errorCorrectLevel: QrErrorCorrectLevel.M,
                decoration: _RequestQRModalState._receiveQrDecoration,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              accountNumber,
              style: context.textTheme.bodyMedium?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 20.h),
            _buildInfoBox(
              AppStrings.get(languageCode, 'account_name'),
              accountName,
              context,
            ),
            SizedBox(height: 5.h),
            _buildInfoBox(
              AppStrings.get(languageCode, 'account_number'),
              '$accountNumber  $currencyDisplayName',
              context,
            ),
            SizedBox(height: 5.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    AppStrings.get(languageCode, 'amount'),
                    '$amount $currencySymbol',
                    context,
                  ),
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: _buildInfoBox(
                    AppStrings.get(languageCode, 'reference'),
                    reference,
                    context,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Row(
              children: [
                Expanded(
                  child: _buildInfoBox(
                    AppStrings.get(languageCode, 'purpose_of_request'),
                    purpose,
                    context,
                  ),
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: _buildInfoBox(
                    AppStrings.get(languageCode, 'type'),
                    requestType,
                    context,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xffF9F9F9),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.get(languageCode, 'valid_until'),
                    style: context.textTheme.bodyMedium?.rq.copyWith(
                      color: const Color(0xff8D8D8D),
                      fontSize: 11.sp,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xffD3D3D3)),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      validUntilText,
                      style: context.textTheme.bodyMedium?.rq.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: 11.sp,
                      ),
                    ),
                  ),
                  if (!isAlways) ...[
                    SizedBox(height: 8.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 6.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffFCFCFC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        AppStrings.get(languageCode, 'cannot_use_after_expiry'),
                        textAlign: TextAlign.center,
                        style: context.textTheme.bodyMedium?.rq.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, BuildContext context) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }
}
