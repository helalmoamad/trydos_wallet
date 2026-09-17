import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receive_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/successful_page.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// Paying a shop: enter or scan a code, confirm, pay, receipt.
///
/// Laid out to match the transfer screen — same header, same dark wallet card,
/// same field chrome — because it is the same act from the customer's side.
/// Only the first field differs: it asks for a **payment code**, not a
/// recipient account, and says so.
///
/// Two ways in, both landing here:
///
/// * **Typed** — opened with no [lookup] from the scanner sheet's "pay a
///   merchant" action; the customer enters the 10-digit code.
/// * **Scanned** — the one scanner reads a code, the send sheet resolves it,
///   and this opens with [lookup] already filled in.
///
/// There is deliberately no scanner inside this screen. The wallet has one
/// scanner, and it routes by what it read.
class MerchantPayModal extends StatefulWidget {
  const MerchantPayModal({
    super.key,
    this.lookup,
    this.code,
    this.onBack,
    this.onSuccessStateChanged,
  });

  /// An already-resolved request. Null when the customer will type the code.
  final MerchantPaymentLookup? lookup;

  /// The code that produced [lookup], so the field shows what was scanned
  /// rather than leaving the customer wondering what the wallet read.
  final String? code;

  final VoidCallback? onBack;
  final ValueChanged<bool>? onSuccessStateChanged;

  @override
  State<MerchantPayModal> createState() => _MerchantPayModalState();
}

class _MerchantPayModalState extends State<MerchantPayModal> {
  /// One controller per screen means one idempotency key per payment: generated
  /// here, reused by every retry of *this* payment, borrowed by no other.
  late final MerchantPaymentController _controller;
  final MerchantPaymentsApiService _api = MerchantPaymentsApiService();

  final TextEditingController _codeController = TextEditingController();
  final FocusNode _codeFocus = FocusNode();
  final ScrollController _formScrollController = ScrollController();

  MerchantPaymentLookup? _lookup;

  Timer? _ticker;
  bool _isResolving = false;
  bool _isPaying = false;
  bool _isRefreshing = false;
  bool _isBalanceHidden = false;
  bool _reportedSuccess = false;
  String? _codeError;

  MerchantPaymentResult? _receipt;
  MerchantPaymentLookup? _settledWithoutReceipt;

  static const Color _ink = Color(0xff1D1D1D);
  static const Color _muted = Color(0xff8D8D8D);
  static const Color _line = Color(0xffD3D3D3);
  static const Color _accent = Color(0xff388CFF);
  static const Color _danger = Color(0xffFF5F60);
  static const Color _blockedTint = Color(0xffFDF3F3);

  static const List<String> _monthKeys = [
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

  @override
  void initState() {
    super.initState();
    _controller = MerchantPaymentController();
    _lookup = widget.lookup;

    if (_lookup != null) {
      _codeController.text = PaymentCode.formatCounterCode(widget.code ?? '');
      _restartTicker();
      // Arriving from a scan: put the wallet on the asset the shop asked for.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _selectMatchingAsset(_lookup!);
      });
    }

    _codeFocus.addListener(() => setState(() {}));
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    _codeFocus.dispose();
    _formScrollController.dispose();
    super.dispose();
  }

  bool get _isResolved => _lookup != null;

  // ─────────────────────────── code entry ───────────────────────────

  /// Resolves as soon as the code is complete — once, not on every keystroke.
  void _onCodeChanged() {
    if (_isResolved || _isResolving) return;

    final digits = PaymentCode.normalize(_codeController.text);
    if (digits.length < PaymentCode.counterCodeLength) {
      if (_codeError != null) setState(() => _codeError = null);
      return;
    }
    unawaited(_resolveCode(digits));
  }

  Future<void> _resolveCode(String code) async {
    if (_isResolving) return;

    final state = context.read<WalletBloc>().state;
    final lang = state.languageCode;

    // A code outside the known namespaces never reaches the network: failed
    // lookups are throttled at ten per fifteen minutes.
    if (!PaymentCode.isResolvable(code)) {
      setState(
        () => _codeError = AppStrings.get(lang, 'merchant_error_invalid_code'),
      );
      return;
    }

    setState(() {
      _isResolving = true;
      _codeError = null;
    });
    FocusScope.of(context).unfocus();

    final result = await _api.resolveCode(code: code, languageCode: lang);
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final resolution = result.data!;

      if (resolution.isMerchant) {
        final merchant = resolution.merchant!;
        setState(() {
          _isResolving = false;
          _lookup = merchant;
        });
        _selectMatchingAsset(merchant);
        _restartTicker();
        return;
      }

      // Either a peer request — which this screen cannot pay — or a `kind`
      // this build does not know. Say so rather than guessing at a flow.
      setState(() {
        _isResolving = false;
        _codeError = AppStrings.get(lang, 'merchant_error_unsupported_code');
      });
      return;
    }

    final failure = MerchantPaymentErrors.classifyLookup(result);
    final key = MerchantPaymentErrors.messageKey(failure);
    setState(() {
      _isResolving = false;
      _codeError = key != null
          ? AppStrings.get(lang, key)
          : (result.errorMessage ??
                AppStrings.get(lang, 'merchant_error_invalid_code'));
    });
  }

  void _clearCode() {
    _ticker?.cancel();
    setState(() {
      _lookup = null;
      _codeError = null;
      _codeController.clear();
    });
    _codeFocus.requestFocus();
  }

  /// Puts the wallet on the asset the request names, so the dark card shows the
  /// balance that will actually pay.
  void _selectMatchingAsset(MerchantPaymentLookup lookup) {
    final bloc = context.read<WalletBloc>();
    final state = bloc.state;

    final symbol = lookup.assetSymbol.toUpperCase();
    final type = lookup.assetType.toUpperCase();
    if (symbol.isEmpty) return;

    String? matchedAssetId;
    for (final entry in state.balances.entries) {
      final balance = entry.value;
      if (balance.assetSymbol.toUpperCase() == symbol &&
          balance.assetType.toUpperCase() == type) {
        matchedAssetId = entry.key;
        break;
      }
    }
    matchedAssetId ??= () {
      for (final currency in state.currencies) {
        if (currency.symbol.toUpperCase() == symbol) return currency.id;
      }
      return null;
    }();

    if (matchedAssetId == null || matchedAssetId.isEmpty) return;
    if (state.selectedAssetId == matchedAssetId) return;

    bloc.add(
      BalanceCardIsSelected(
        isSelected: true,
        assetId: matchedAssetId,
        assetSymbol: lookup.assetSymbol,
        assetType: type,
      ),
    );
    bloc.add(WalletBalanceLoadRequested(matchedAssetId));
  }

  // ───────────────────────────── expiry ─────────────────────────────

  void _restartTicker() {
    _ticker?.cancel();
    if (_lookup?.expiresAt == null) return;

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_lookup?.isExpiredNow ?? false) {
        _ticker?.cancel();
        // The countdown only disables the button; the server still decides.
        unawaited(_refreshLookup());
      }
    });
  }

  Future<void> _refreshLookup() async {
    final current = _lookup;
    if (_isRefreshing || current == null || !mounted) return;
    setState(() => _isRefreshing = true);

    final lang = context.read<WalletBloc>().state.languageCode;
    final result = await _api.lookupMerchantPayment(
      code: current.id,
      languageCode: lang,
    );

    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      if (result.isSuccess && result.data != null) _lookup = result.data;
    });
    if (result.isSuccess && result.data != null) _restartTicker();
  }

  String _validUntilText(WalletState state) {
    final expiry = _lookup?.expiresAt;
    if (expiry == null) return AppStrings.get(state.languageCode, 'always');

    final remaining = expiry.difference(DateTime.now());
    final safeSeconds = remaining.isNegative ? 0 : remaining.inSeconds;
    final mins = safeSeconds ~/ 60;
    final secs = safeSeconds % 60;
    final mmss =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    final time =
        '${expiry.hour.toString().padLeft(2, '0')}:'
        '${expiry.minute.toString().padLeft(2, '0')}';
    final date =
        '${expiry.day} '
        '${AppStrings.get(state.languageCode, _monthKeys[expiry.month - 1])} '
        '${expiry.year}';

    return '$mmss ${AppStrings.get(state.languageCode, 'minutes_until')}'
        '$time | $date';
  }

  // ───────────────────────── paying wallet ─────────────────────────

  /// The MAIN wallet for the asset the request names.
  ///
  /// There is no cross-asset conversion here: a USD request is paid from the
  /// USD wallet or the screen says there is none.
  Balance? _payingWallet(WalletState state) {
    final lookup = _lookup;
    if (lookup == null) return null;

    final symbol = lookup.assetSymbol.toUpperCase();
    final type = lookup.assetType.toUpperCase();
    if (symbol.isEmpty) return null;

    Balance? fallback;
    for (final balance in state.balances.values) {
      if (balance.assetSymbol.toUpperCase() != symbol ||
          balance.assetType.toUpperCase() != type ||
          balance.accountNumber.trim().isEmpty) {
        continue;
      }
      if (balance.accountSubtype.trim().toUpperCase() == 'MAIN') return balance;
      fallback ??= balance;
    }
    return fallback;
  }

  DecimalAmount _totalDue() {
    final lookup = _lookup;
    if (lookup == null) return DecimalAmount.zero;
    final amount = DecimalAmount.tryParse(lookup.amount) ?? DecimalAmount.zero;
    final fee = DecimalAmount.tryParse(lookup.feeAmount) ?? DecimalAmount.zero;
    return amount + fee;
  }

  bool _hasEnoughBalance(Balance? wallet) {
    if (wallet == null) return false;
    // Balances still arrive as doubles; the comparison runs in exact decimal so
    // the amount never passes through a float.
    return DecimalAmount.fromDouble(wallet.available) >= _totalDue();
  }

  bool _isKycBlocked(WalletState state) {
    final status = (state.kycVerificationStatus ?? '').trim().toLowerCase();
    // Unknown is not a block: it usually means the check has not run yet, and
    // the server refuses with a 403 anyway.
    if (status.isEmpty) return false;
    return status != 'verified';
  }

  bool get _isBlocked {
    final lookup = _lookup;
    if (lookup == null) return false;
    return !lookup.payable || lookup.isExpiredNow;
  }

  // ───────────────────────────── paying ─────────────────────────────

  Future<void> _pay(WalletState state) async {
    // One in-flight call, one key. A second tap does nothing.
    if (_isPaying || _controller.isInFlight) return;

    final lookup = _lookup;
    final wallet = _payingWallet(state);
    if (lookup == null || wallet == null) return;

    setState(() => _isPaying = true);

    final outcome = await _controller.pay(
      lookup: lookup,
      accountNumber: wallet.accountNumber,
      languageCode: state.languageCode,
    );

    if (!mounted) return;
    setState(() => _isPaying = false);
    await _handleOutcome(outcome, state);
  }

  Future<void> _handleOutcome(
    MerchantPaymentOutcome outcome,
    WalletState state,
  ) async {
    final lang = state.languageCode;

    switch (outcome) {
      case MerchantPaymentPaid(:final result):
        setState(() => _receipt = result);
        _notifySuccess(true);
        if (mounted) {
          context.read<WalletBloc>().add(const WalletRefreshAllRequested());
        }

      case MerchantPaymentPaidWithoutReceipt(:final lookup):
        setState(() {
          _lookup = lookup;
          _settledWithoutReceipt = lookup;
        });
        _notifySuccess(true);
        if (mounted) {
          context.read<WalletBloc>().add(const WalletRefreshAllRequested());
        }

      case MerchantPaymentNeedsKyc(:final message):
        _showFailure(lang, MerchantPaymentFailure.kycRequired, message);
        await _routeToVerification();

      case MerchantPaymentNotPayable(
        :final failure,
        :final lookup,
        :final message,
      ):
        setState(() {
          if (lookup != null) _lookup = lookup;
        });
        _showFailure(lang, failure, message);
        if (lookup == null) unawaited(_refreshLookup());

      case MerchantPaymentRejected(:final failure, :final message):
        _showFailure(lang, failure, message);
        if (failure == MerchantPaymentFailure.kycRequired) {
          await _routeToVerification();
        }

      case MerchantPaymentNotCompleted():
        // The request is still awaiting payment, so nothing was debited.
        showMessage(
          AppStrings.get(lang, 'merchant_payment_not_completed'),
          context: context,
          type: MessageType.error,
        );

      case MerchantPaymentUnresolved():
        // Not an error: the payment may have gone through, and the pending
        // record is reconciled on the next launch.
        showMessage(
          AppStrings.get(lang, 'merchant_checking_payment'),
          context: context,
          type: MessageType.info,
        );
    }
  }

  void _showFailure(
    String languageCode,
    MerchantPaymentFailure failure,
    String? serverMessage,
  ) {
    final key = MerchantPaymentErrors.messageKey(failure);
    // With no fixed wording, the backend's own message is already localized.
    final text = key != null
        ? AppStrings.get(languageCode, key)
        : (serverMessage ?? AppStrings.get(languageCode, 'transaction_failed'));
    showMessage(text, context: context, type: MessageType.error);
  }

  Future<void> _routeToVerification() async {
    if (!mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const FirstPageKyc()));
    if (!mounted) return;
    context.read<WalletBloc>().add(const WalletKycStatusRequested());
  }

  void _notifySuccess(bool isSuccess) {
    if (_reportedSuccess == isSuccess) return;
    _reportedSuccess = isSuccess;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onSuccessStateChanged?.call(isSuccess);
    });
  }

  /// Closes this sheet and opens the top-up flow.
  ///
  /// The app-level navigator is used deliberately: this sheet is about to be
  /// popped, so its own context is gone by the time the next one opens.
  void _openTopUp() {
    final bloc = context.read<WalletBloc>();
    Navigator.of(context).pop();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rootContext = navigatorKey.currentContext;
      if (rootContext == null) return;
      showWalletModal(
        context: rootContext,
        builder: (ctx, sc) => BlocProvider.value(
          value: bloc,
          child: ReceiveModal(scrollController: sc),
        ),
      );
    });
  }

  Future<void> _openSuccessUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[TrydosWallet] could not open shop url: $e');
    }
  }

  void _syncBackButton() {
    final isDone = _receipt != null || _settledWithoutReceipt != null;
    final onBack = widget.onBack;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackButton(
        context,
        visible: !isDone && onBack != null,
        onPressed: onBack,
      );
    });
  }

  // ───────────────────────────── build ─────────────────────────────

  @override
  Widget build(BuildContext context) {
    _syncBackButton();

    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final receipt = _receipt;
        if (receipt != null) return _buildReceipt(state, receipt);

        final settled = _settledWithoutReceipt;
        if (settled != null) return _buildSettledWithoutReceipt(state, settled);

        return _buildForm(state);
      },
    );
  }

  Widget _buildForm(WalletState state) {
    final wallet = _payingWallet(state);
    final hasEnough = _hasEnoughBalance(wallet);
    final kycBlocked = _isKycBlocked(state);
    final canPay =
        _isResolved &&
        !_isBlocked &&
        wallet != null &&
        hasEnough &&
        !kycBlocked &&
        !_isPaying;

    return SafeArea(
      top: false,
      left: false,
      right: false,
      bottom: true,
      child: Directionality(
        textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
        child: SizedBox(
          height: 850.h,
          child: Container(
            color: _isBlocked ? _blockedTint : Colors.transparent,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 30.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(state),
                  SizedBox(height: 20.h),
                  _buildWalletCard(state),
                  SizedBox(height: 14.h),
                  Text(
                    AppStrings.get(state.languageCode, 'merchant_pay_to'),
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: _ink,
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _formScrollController,
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: Column(
                        children: [
                          _buildCodeField(state),
                          SizedBox(height: 5.h),
                          if (_isResolved) ...[
                            ..._buildResolvedFields(state, wallet, hasEnough),
                          ],
                          SizedBox(height: 10.h),
                          if (_isBlocked) _buildBlockedBanner(state),
                          if (kycBlocked && !_isBlocked) _buildKycBanner(state),
                        ],
                      ),
                    ),
                  ),
                  if (_isResolving)
                    Padding(
                      padding: EdgeInsets.only(bottom: 30.h, top: 10.h),
                      child: SizedBox(
                        height: 20.h,
                        width: 20.w,
                        child: const CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    _buildPayButton(state, canPay: canPay),
                  SizedBox(height: 25.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(WalletState state) {
    return Column(
      children: [
        SvgPicture.asset(
          TrydosWalletAssets.transferSend,
          height: 40.h,
          package: TrydosWalletStyles.packageName,
        ),
        SizedBox(height: 10.h),
        Text(
          AppStrings.get(state.languageCode, 'merchant_pay_title')
              .toUpperCase(),
          style: context.textTheme.bodyMedium?.mq.copyWith(
            color: _ink,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }

  /// The dark card from the transfer screen: balance, the wallet that pays, and
  /// the asset — switched to the request's asset the moment a code resolves.
  ///
  /// Until a code resolves there is nothing truthful to put here. Which wallet
  /// pays depends on the asset the shop asked for, and that is not known yet, so
  /// showing whatever asset happened to be selected would state a balance that
  /// may have nothing to do with this payment. The values shimmer in place
  /// instead, at the exact sizes they will occupy, so nothing shifts when they
  /// arrive.
  Widget _buildWalletCard(WalletState state) {
    final balance = state.balances[state.selectedAssetId ?? ''];
    final isLoading =
        !_isResolved ||
        state.loadingBalanceIds.contains(state.selectedAssetId ?? '');

    final amountStr = balance != null
        ? balance.available.toStringAsFixed(
            balance.available.truncateToDouble() == balance.available ? 0 : 2,
          )
        : '0';

    Currency? currency;
    for (final c in state.currencies) {
      if (c.id == (state.selectedAssetId ?? '')) {
        currency = c;
        break;
      }
    }
    final symbol = currency?.symbol ?? _lookup?.assetSymbol ?? r'$';
    final assetName = currency?.localizedName(state.languageCode) ?? '';

    return Container(
      padding: EdgeInsets.all(10.h),
      decoration: BoxDecoration(
        color: const Color(0xff3C3C3C),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                // Baseline alignment only makes sense between texts. The
                // placeholders have no baseline, so while they are up the row
                // centres them instead of hanging them off the bottom.
                crossAxisAlignment: isLoading
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.baseline,
                textBaseline: isLoading ? null : TextBaseline.alphabetic,
                children: [
                  if (isLoading)
                    _shimmerBlock(width: 120.w, height: 30.h)
                  else
                    Text(
                      _isBalanceHidden ? '****' : amountStr,
                      style: context.textTheme.bodyMedium?.mq.copyWith(
                        color: Colors.white,
                        fontSize: 25.sp,
                      ),
                    ),
                  SizedBox(width: 8.w),
                  if (isLoading)
                    _shimmerBlock(width: 70.w, height: 11.h)
                  else
                    Text(
                      assetName.isEmpty ? symbol : '$symbol | $assetName',
                      style: context.textTheme.bodyMedium?.lq.copyWith(
                        color: Colors.white,
                        fontSize: 9.sp,
                      ),
                    ),
                  SizedBox(width: 15.w),
                  if (!isLoading)
                    GestureDetector(
                      onTap: () => setState(
                        () => _isBalanceHidden = !_isBalanceHidden,
                      ),
                      child: SvgPicture.asset(
                        TrydosWalletAssets.hide,
                        colorFilter: const ColorFilter.mode(
                          _line,
                          BlendMode.srcIn,
                        ),
                        height: 11.h,
                        package: TrydosWalletStyles.packageName,
                      ),
                    ),
                ],
              ),
            ],
          ),
          SizedBox(height: 5.h),
          // The label is static, so it stays put and gives the shimmering
          // values something to sit under.
          Text(
            AppStrings.get(state.languageCode, 'sender_account'),
            style: context.textTheme.bodyMedium?.lq.copyWith(
              color: Colors.white,
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 5.h),
          if (isLoading)
            _shimmerBlock(width: 200.w, height: 16.h)
          else
            Text(
              _senderAccountDisplay(state),
              style: context.textTheme.bodyMedium?.lq.copyWith(
                color: Colors.white,
                fontSize: 13.sp,
              ),
            ),
        ],
      ),
    );
  }

  /// A placeholder that occupies exactly the space its value will.
  ///
  /// The tones are lighter than the card rather than the greys the rest of the
  /// app shimmers with: those are tuned for white surfaces and vanish against
  /// `0xff3C3C3C`.
  Widget _shimmerBlock({required double width, required double height}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xff4E4E4E),
      highlightColor: const Color(0xff6A6A6A),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xff4E4E4E),
          borderRadius: BorderRadius.circular(6.r),
        ),
      ),
    );
  }

  String _senderAccountDisplay(WalletState state) {
    final wallet =
        _payingWallet(state) ?? state.balances[state.selectedAssetId ?? ''];
    final accountNumber = (wallet?.accountNumber ?? '').trim().isNotEmpty
        ? wallet!.accountNumber
        : (Balance.lastMyAccountsPrimaryWallet?.accountNumber ?? '----');

    final subtypeRaw = wallet?.accountSubtype ?? 'MAIN';
    final subtype = subtypeRaw.toUpperCase() == 'MAIN'
        ? AppStrings.get(state.languageCode, 'main_sub_account')
        : subtypeRaw;

    return '$subtype | \u202D$accountNumber\u202C | ${state.maskedName}';
  }

  /// The one field that differs from the transfer screen: a payment code, and
  /// labelled as one.
  Widget _buildCodeField(WalletState state) {
    return _buildField(
      state: state,
      label: AppStrings.get(state.languageCode, 'merchant_enter_code'),
      hint: AppStrings.get(state.languageCode, 'merchant_code_hint'),
      controller: _codeController,
      focusNode: _codeFocus,
      isVerified: _isResolved,
      errorMessage: _codeError,
      keyboardType: TextInputType.number,
      forceLtrValue: true,
      labelColor: _isResolved ? _muted : _ink,
      onEdit: _isResolved ? _clearCode : null,
      subtitle: _isResolved ? _lookup!.merchantName : null,
      inputFormatters: [
        TextInputFormatter.withFunction((oldValue, newValue) {
          final formatted = PaymentCode.formatCounterCodeInput(newValue.text);
          return TextEditingValue(
            text: formatted,
            selection: TextSelection.collapsed(offset: formatted.length),
          );
        }),
      ],
    );
  }

  List<Widget> _buildResolvedFields(
    WalletState state,
    Balance? wallet,
    bool hasEnough,
  ) {
    final lookup = _lookup!;
    final lang = state.languageCode;
    final description = lookup.description.resolve(lang);

    return [
      _buildField(
        state: state,
        label: AppStrings.get(lang, 'merchant_you_are_paying'),
        controller: TextEditingController(text: lookup.merchantName),
        focusNode: FocusNode(),
        isVerified: true,
        enabled: false,
      ),
      SizedBox(height: 5.h),
      _buildField(
        state: state,
        label: AppStrings.get(lang, 'amount_to_be_sent'),
        controller: TextEditingController(text: lookup.amount),
        focusNode: FocusNode(),
        isVerified: true,
        enabled: false,
        forceLtrValue: true,
        suffixFollowsText: true,
        suffix: Text(
          ' ${lookup.assetSymbol}',
          style: context.textTheme.bodyMedium?.rq.copyWith(
            color: _ink,
            fontSize: 13.sp,
          ),
        ),
      ),
      if (lookup.hasFee) ...[
        SizedBox(height: 5.h),
        _buildField(
          state: state,
          label: AppStrings.get(lang, 'merchant_total'),
          controller: TextEditingController(text: _totalDue().raw),
          focusNode: FocusNode(),
          isVerified: true,
          enabled: false,
          forceLtrValue: true,
          suffixFollowsText: true,
          suffix: Text(
            ' ${lookup.assetSymbol}',
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: _ink,
              fontSize: 13.sp,
            ),
          ),
        ),
      ],
      SizedBox(height: 5.h),
      _buildField(
        state: state,
        label: AppStrings.get(lang, 'merchant_order_ref'),
        controller: TextEditingController(
          text: lookup.orderRef.isEmpty ? '-' : lookup.orderRef,
        ),
        focusNode: FocusNode(),
        isVerified: true,
        enabled: false,
        forceLtrValue: true,
      ),
      if (description.isNotEmpty) ...[
        SizedBox(height: 5.h),
        _buildField(
          state: state,
          label: AppStrings.get(lang, 'merchant_description'),
          controller: TextEditingController(text: description),
          focusNode: FocusNode(),
          isVerified: true,
          enabled: false,
        ),
      ],
      SizedBox(height: 5.h),
      _buildField(
        state: state,
        label: AppStrings.get(lang, 'valid_until'),
        controller: TextEditingController(),
        focusNode: FocusNode(),
        isVerified: true,
        enabled: false,
        customValueWidget: Text(
          _validUntilText(state),
          style: context.textTheme.bodyMedium?.mq.copyWith(
            fontSize: 13.sp,
            color: _ink,
          ),
        ),
      ),
      if (wallet == null) ...[
        SizedBox(height: 10.h),
        _buildNote(
          AppStrings.get(
            lang,
            'merchant_no_wallet_for_asset',
          ).replaceAll('{symbol}', lookup.assetSymbol),
        ),
      ] else if (!hasEnough) ...[
        SizedBox(height: 10.h),
        _buildNote(
          AppStrings.get(lang, 'merchant_insufficient_balance_hint'),
          action: AppStrings.get(lang, 'merchant_top_up'),
          onAction: _openTopUp,
        ),
      ],
    ];
  }

  Widget _buildNote(String text, {String? action, VoidCallback? onAction}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xffFFF4F4),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: _ink,
              fontSize: 11.sp,
            ),
          ),
          if (action != null && onAction != null) ...[
            SizedBox(height: 8.h),
            GestureDetector(
              onTap: onAction,
              child: Text(
                action,
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  color: _accent,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Already paid, expired or cancelled — the red banner the transfer screen
  /// uses for a dead request.
  Widget _buildBlockedBanner(WalletState state) {
    final lookup = _lookup!;
    final reason = lookup.isExpiredNow && lookup.payable
        ? AppStrings.get(state.languageCode, 'merchant_expired_now')
        : AppStrings.get(state.languageCode, lookup.status.labelKey);

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 8.h),
          padding: EdgeInsets.symmetric(vertical: 8.h),
          decoration: BoxDecoration(
            color: _danger,
            borderRadius: BorderRadius.circular(12.r),
          ),
          alignment: Alignment.center,
          child: Text(
            reason,
            style: context.textTheme.bodyMedium?.mq.copyWith(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          AppStrings.get(state.languageCode, 'merchant_ask_new_code'),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.rq.copyWith(
            color: _muted,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildKycBanner(WalletState state) {
    return _buildNote(
      AppStrings.get(state.languageCode, 'merchant_error_kyc_required'),
      action: AppStrings.get(state.languageCode, 'merchant_verify_identity_cta'),
      onAction: _routeToVerification,
    );
  }

  Widget _buildPayButton(WalletState state, {required bool canPay}) {
    return InkWell(
      onTap: canPay ? () => _pay(state) : null,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isPaying)
              SizedBox(
                height: 25.h,
                width: 25.h,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            else
              SvgPicture.asset(
                canPay
                    ? TrydosWalletAssets.transferSend
                    : TrydosWalletAssets.sendDisable,
                height: 25.h,
                package: TrydosWalletStyles.packageName,
              ),
            SizedBox(height: 5.h),
            Text(
              _isPaying
                  ? AppStrings.get(state.languageCode, 'sending')
                  : AppStrings.get(state.languageCode, 'merchant_pay_button'),
              style: context.textTheme.bodyMedium?.mq.copyWith(
                color: canPay ? _accent : _muted,
                fontSize: 15.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The transfer screen's field chrome, kept visually identical: same radii,
  /// same fills, same focus and error colours, same "edit" affordance.
  Widget _buildField({
    required WalletState state,
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    String hint = '',
    bool isVerified = false,
    bool enabled = true,
    bool forceLtrValue = false,
    bool suffixFollowsText = false,
    Widget? suffix,
    Widget? customValueWidget,
    String? subtitle,
    String? errorMessage,
    VoidCallback? onEdit,
    Color? labelColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    Color borderColor = focusNode.hasFocus ? _accent : _line;
    if (errorMessage != null) borderColor = const Color(0xffFF5F61);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: isVerified
            ? (_isBlocked ? _blockedTint : const Color(0xffFCFCFC))
            : Colors.white,
        border: isVerified ? null : Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isVerified && onEdit != null) ...[
                GestureDetector(
                  onTap: onEdit,
                  child: Text(
                    AppStrings.get(state.languageCode, 'edit'),
                    style: context.textTheme.bodyMedium?.mq.copyWith(
                      fontSize: 11.sp,
                      color: _accent,
                      decoration: TextDecoration.underline,
                      decorationColor: _accent,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
              ],
              Text(
                label,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  fontSize: 11.sp,
                  color: labelColor ?? _muted,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          if (isVerified)
            customValueWidget ??
                Row(
                  children: [
                    Text(
                      controller.text,
                      textDirection: forceLtrValue ? TextDirection.ltr : null,
                      style: context.textTheme.bodyMedium?.rq.copyWith(
                        color: _ink,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (suffixFollowsText && suffix != null) ...[
                      SizedBox(width: 4.w),
                      suffix,
                    ],
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          subtitle,
                          style: context.textTheme.bodyMedium?.rq.copyWith(
                            color: _muted,
                            fontSize: 11.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                )
          else
            TextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              maxLines: 1,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              textDirection: forceLtrValue ? TextDirection.ltr : null,
              cursorColor: _accent,
              style: context.textTheme.bodyMedium?.mq.copyWith(
                color: _ink,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: context.textTheme.bodyMedium?.mq.copyWith(
                  color: _line,
                  fontSize: 13.sp,
                ),
                suffix: suffixFollowsText ? null : suffix,
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          if (errorMessage != null)
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 8.h),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: const Color(0xffFFF4F4),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: _ink,
                  fontSize: 11.sp,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ──────────────────────────── receipt ────────────────────────────

  Widget _buildReceipt(WalletState state, MerchantPaymentResult receipt) {
    final wallet = _payingWallet(state);
    final successUrl = receipt.successUrl;

    return SuccessfulPage(
      senderAccount: wallet?.accountNumber ?? '',
      // The shop, not an account number: that is what the customer recognises
      // on a receipt they may send back to the shop over chat.
      recipientAccount: receipt.merchantName,
      amount: receipt.amount,
      currencySymbol: receipt.assetSymbol,
      reference: receipt.receiptNumber,
      dateAndTimeString: _formatReceiptDate(receipt.paidAt, state.languageCode),
      type: AppStrings.get(state.languageCode, 'merchant_payment'),
      purpose: receipt.orderRef,
      isSuccess: receipt.isPaid,
      onDone: () => Navigator.of(context).maybePop(),
      onDownload: () {},
      onShare: () {},
      footer: successUrl == null
          ? null
          : GestureDetector(
              onTap: () => _openSuccessUrl(successUrl),
              child: Text(
                AppStrings.get(state.languageCode, 'merchant_return_to_shop'),
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  color: _accent,
                  fontSize: 12.sp,
                ),
              ),
            ),
    );
  }

  /// The money moved but the response was lost, so there is no receipt number.
  /// The customer is told the payment went through and where the receipt will
  /// be — never that it failed.
  Widget _buildSettledWithoutReceipt(
    WalletState state,
    MerchantPaymentLookup settled,
  ) {
    final wallet = _payingWallet(state);

    return SuccessfulPage(
      senderAccount: wallet?.accountNumber ?? '',
      recipientAccount: settled.merchantName,
      amount: settled.amount,
      currencySymbol: settled.assetSymbol,
      reference: settled.orderRef,
      dateAndTimeString: _formatReceiptDate(DateTime.now(), state.languageCode),
      type: AppStrings.get(state.languageCode, 'merchant_payment'),
      purpose: settled.orderRef,
      isSuccess: true,
      onDone: () => Navigator.of(context).maybePop(),
      onDownload: () {},
      onShare: () {},
      footer: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w),
        child: Text(
          AppStrings.get(state.languageCode, 'merchant_paid_without_receipt'),
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.rq.copyWith(
            color: _muted,
            fontSize: 11.sp,
            height: 1.35,
          ),
        ),
      ),
    );
  }

  String _formatReceiptDate(DateTime? value, String languageCode) {
    final dt = value?.toLocal();
    if (dt == null) return '';
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${AppStrings.get(languageCode, _monthKeys[dt.month - 1])} | '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
