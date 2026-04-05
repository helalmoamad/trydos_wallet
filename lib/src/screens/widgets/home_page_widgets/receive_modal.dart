import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/request_qr_modal.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';

enum ReceiveModalView { main, request }

class ReceiveModal extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onBack;

  const ReceiveModal({super.key, this.scrollController, this.onBack});

  @override
  State<ReceiveModal> createState() => _ReceiveModalState();
}

class _ReceiveModalState extends State<ReceiveModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isMasked = false;
  bool _isDownloading = false;
  bool _isSharing = false;
  ReceiveModalView _currentView = ReceiveModalView.main;

  static const String _maskedName = 'RBTYLS';

  void _resetModalBackgroundToWhite() {
    if (!mounted) return;
    setWalletModalBackground(context, Colors.white);
  }

  void _handleBackAction() {
    final canGoBack = _currentView == ReceiveModalView.request;
    if (canGoBack) {
      setState(() {
        _currentView = ReceiveModalView.main;
      });
      _resetModalBackgroundToWhite();
      return;
    }

    if (widget.onBack != null) {
      widget.onBack!.call();
      return;
    }

    Navigator.pop(context);
  }

  @override
  void initState() {
    super.initState();
  }

  void _syncModalBackButton() {
    final canGoBack = _currentView == ReceiveModalView.request;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackButton(
        context,
        visible: canGoBack || widget.onBack != null,
        onPressed: _handleBackAction,
      );
    });
  }

  Balance? _resolveReceiveBalance(WalletState state) {
    if (state.selectedAssetId != null) {
      final selected = state.balances[state.selectedAssetId!];
      if (selected != null) return selected;
    }

    for (final balance in state.balances.values) {
      if (balance.assetSymbol.toUpperCase() == 'USD') {
        return balance;
      }
    }

    if (state.balances.isNotEmpty) {
      return state.balances.values.first;
    }
    return null;
  }

  String _accountNameFromState(WalletState state) {
    final balanceName = (_resolveReceiveBalance(state)?.accountName ?? '')
        .trim();
    final accountName = balanceName.isNotEmpty
        ? balanceName
        : (Balance.lastMyAccountsPrimaryWallet?.accountName ?? '');
    return accountName;
  }

  String _accountNumberFromState(WalletState state) {
    final balanceNumber = (_resolveReceiveBalance(state)?.accountNumber ?? '')
        .trim();
    final accountNumber = balanceNumber.isNotEmpty
        ? balanceNumber
        : (Balance.lastMyAccountsPrimaryWallet?.accountNumber ?? '');
    return accountNumber;
  }

  String _currencySymbolFromState(WalletState state) {
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
    return '';
  }

  String _currencyDisplayNameFromState(WalletState state) {
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

  String _buildReceiveQrPayload(
    WalletState state,
    String accountName,
    String accountNumber,
  ) {
    return QrTransferPayloadCodec.buildReceivePayload(
      accountNumber: accountNumber,
      accountName: accountName,
      currencySymbol: _currencySymbolFromState(state),
    );
  }

  void _handleCopy() {
    final state = context.read<WalletBloc>().state;
    final accountNumber = _accountNumberFromState(state);
    Clipboard.setData(ClipboardData(text: accountNumber));
    showMessage(
      AppStrings.get(state.languageCode, 'acc_copied_msg'),
      context: context,
      type: MessageType.success,
    );
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

  Future<void> _handleDownload() async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isDownloading = true);
    final state = context.read<WalletBloc>().state;
    final accountNumber = _accountNumberFromState(state);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/qr_card_$accountNumber.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        await Gal.putImage(imagePath);

        // ignore: use_build_context_synchronously
        showMessage(
          AppStrings.get(state.languageCode, 'saved_successfully'),
          // ignore: use_build_context_synchronously
          context: context,
          type: MessageType.success,
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      showMessage(
        AppStrings.get(state.languageCode, 'failed_to_save'),
        // ignore: use_build_context_synchronously
        context: context,
        type: MessageType.error,
      );
    }

    if (mounted) {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isSharing = true);
    final state = context.read<WalletBloc>().state;
    final accountNumber = _accountNumberFromState(state);

    try {
      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/qr_card_$accountNumber.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imagePath)],
          text:
              '${AppStrings.get(state.languageCode, 'my_receipt_qr')} $accountNumber',
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
    _syncModalBackButton();
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (!mounted) return false;
        _handleBackAction();
        return false;
      },
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (_currentView == ReceiveModalView.main) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _resetModalBackgroundToWhite();
            });
          }
          final accountName = _accountNameFromState(state);
          final accountNumber = _accountNumberFromState(state);
          final currencyDisplayName = _currencyDisplayNameFromState(state);
          final qrPayload = _buildReceiveQrPayload(
            state,
            accountName,
            accountNumber,
          );
          return Directionality(
            textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Stack(
              children: [
                // Hidden card for screen capture
                PositionedDirectional(
                  start: -4000,
                  top: -4000,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: _CleanQRCard(
                      accountName: _isMasked ? _maskedName : accountName,
                      accountNumber: accountNumber,
                      currencyDisplayName: currencyDisplayName,
                      qrPayload: qrPayload,
                      languageCode: state.languageCode,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _currentView == ReceiveModalView.main
                          ? _buildReceiveView(
                              context,
                              state,
                              accountName,
                              accountNumber,
                              currencyDisplayName,
                              qrPayload,
                            )
                          : RequestQRModal(
                              accountName: accountName,
                              accountNumber: accountNumber,
                              onBack: () {
                                setState(() {
                                  _currentView = ReceiveModalView.main;
                                });
                              },
                            ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReceiveView(
    BuildContext context,
    WalletState state,
    String accountName,
    String accountNumber,
    String currencyDisplayName,
    String qrPayload,
  ) {
    return Column(
      children: [
        // Trydos Logo
        SvgPicture.asset(
          TrydosWalletAssets.trydos,
          height: 30.h,
          package: TrydosWalletStyles.packageName,
        ),
        SizedBox(height: 20.h),
        // QR Code Area
        Container(
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20.r),
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
                  data: qrPayload,
                  errorCorrectLevel: QrErrorCorrectLevel.M,
                  decoration: const PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(
                      color: Color(0xff1D1D1D),
                      roundFactor: 0.9,
                    ),
                    quietZone: PrettyQrQuietZone.modules(0),
                  ),
                ),
              ),
              SizedBox(height: 5.h),
              Text(
                accountNumber,
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 20.h),
        SizedBox(
          height: 150,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildInfoSection(
                  AppStrings.get(state.languageCode, 'account_name'),
                  _isMasked ? _maskedName : accountName,
                  trailing: GestureDetector(
                    onTap: () => setState(() => _isMasked = !_isMasked),
                    child: SvgPicture.asset(
                      TrydosWalletAssets.hide,
                      height: 16.h,
                      package: TrydosWalletStyles.packageName,
                      colorFilter: ColorFilter.mode(
                        _isMasked
                            ? const Color(0xff1D1D1D)
                            : const Color(0xff8D8D8D),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                _buildInfoSection(
                  AppStrings.get(state.languageCode, 'account_number'),
                  '$accountNumber  $currencyDisplayName',
                ),
              ],
            ),
          ),
        ),

        // Account Details
        Spacer(),
        // Action Buttons
        SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Spacer(),
              _buildActionButton(
                asset: TrydosWalletAssets.generate,

                label: AppStrings.get(state.languageCode, 'request'),
                onTap: () {
                  setState(() {
                    _currentView = ReceiveModalView.request;
                  });
                },
              ),
              SizedBox(width: 50.w),
              _buildActionButton(
                asset: TrydosWalletAssets.copy,
                label: AppStrings.get(state.languageCode, 'copy'),
                onTap: _handleCopy,
              ),
              SizedBox(width: 50.w),
              _buildActionButton(
                asset: TrydosWalletAssets.download,
                label: AppStrings.get(state.languageCode, 'download'),
                onTap: _handleDownload,
                isLoading: _isDownloading,
              ),
              SizedBox(width: 50.w),
              _buildActionButton(
                asset: TrydosWalletAssets.share,
                label: AppStrings.get(state.languageCode, 'share'),
                onTap: _handleShare,
                isLoading: _isSharing,
              ),
              Spacer(),
            ],
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildInfoSection(String label, String value, {Widget? trailing}) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff8D8D8D),
                  fontSize: 11.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                value,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
          PositionedDirectional(
            end: 10.w,
            top: 14.h,
            child: (trailing != null) ? trailing : SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String asset,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: SizedBox(
        height: 42,
        child: Column(
          children: [
            isLoading
                ? SizedBox(
                    height: 20.h,
                    width: 20.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff404040),
                    ),
                  )
                : SvgPicture.asset(
                    asset,
                    height: 20.h,
                    // ignore: deprecated_member_use
                    color: Color(0xff404040),
                    package: TrydosWalletStyles.packageName,
                  ),

            SizedBox(height: 8.h),
            Text(
              label,
              style: context.textTheme.bodyMedium?.rq.copyWith(
                color: const Color(0xff404040),
                fontSize: 11.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanQRCard extends StatelessWidget {
  final String accountName;
  final String accountNumber;
  final String currencyDisplayName;
  final String qrPayload;
  final String languageCode;

  const _CleanQRCard({
    required this.accountName,
    required this.accountNumber,
    required this.currencyDisplayName,
    required this.qrPayload,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = languageCode == 'ar' || languageCode == 'ku';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        height: 1.sh,
        width: 1.sw,
        padding: EdgeInsets.all(30.r),
        decoration: const BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              TrydosWalletAssets.trydos,
              height: 30.h,
              package: TrydosWalletStyles.packageName,
            ),
            SizedBox(height: 20.h),
            SizedBox.square(
              dimension: 300.h,
              child: PrettyQrView.data(
                data: qrPayload,
                errorCorrectLevel: QrErrorCorrectLevel.M,
                decoration: const PrettyQrDecoration(
                  shape: PrettyQrSmoothSymbol(
                    color: Color(0xff1D1D1D),
                    roundFactor: 0.9,
                  ),
                  quietZone: PrettyQrQuietZone.modules(0),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              accountNumber,
              style: context.textTheme.bodyMedium?.mq.copyWith(
                color: const Color(0xff404040),
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, BuildContext context) {
    return Container(
      width: double.infinity,

      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12.r),
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
