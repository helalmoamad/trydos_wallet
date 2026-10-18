import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';
import 'package:trydos_wallet/src/analytics/wallet_analytics.dart';
import 'package:trydos_wallet/src/models/models.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receipt_widget.dart';
import 'package:trydos_wallet/src/utils/ui_utils.dart';

/// View-only details of a past transaction, shown inside a wallet modal.
/// Done closes it (Android back and tapping outside also close, via
/// [showWalletModal]); Download and Share hand over the same receipt image the
/// transfer success screen produces.
class TransactionDetailsPage extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onDone;

  const TransactionDetailsPage({
    super.key,
    required this.transaction,
    required this.onDone,
  });

  @override
  State<TransactionDetailsPage> createState() => _TransactionDetailsPageState();
}

class _TransactionDetailsPageState extends State<TransactionDetailsPage> {
  bool _appliedModalUi = false;
  final GlobalKey _receiptKey = GlobalKey();
  bool _isDownloading = false;
  bool _isSharing = false;

  static const Color _successBackground = Color(0xffF4FFFA);
  static const Color _neutralBackground = Colors.white;

  static const List<String> _monthKeys = [
    'jan', 'feb', 'mar', 'apr', 'may', 'jun', //
    'jul', 'aug', 'sep', 'oct', 'nov', 'dec',
  ];

  Transaction get _t => widget.transaction;

  bool get _isSuccess => _t.status.toUpperCase() == 'COMPLETED';
  bool get _isFailed => _t.status.toUpperCase() == 'FAILED';

  @override
  void initState() {
    super.initState();
    WalletAnalytics.screen(WalletScreens.transactionDetails);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedModalUi) return;
    _appliedModalUi = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackButton(context, visible: false);
      setWalletModalBackground(
        context,
        _isSuccess ? _successBackground : _neutralBackground,
      );
    });
  }

  String _statusLabel(String lang) {
    if (_isSuccess) return AppStrings.get(lang, 'succeeded');
    if (_isFailed) return AppStrings.get(lang, 'failed');
    if (_t.status.toUpperCase() == 'PENDING') {
      return AppStrings.get(lang, 'pending');
    }
    return _t.status;
  }

  Color get _statusColor {
    if (_isSuccess) return const Color(0xff34D317);
    if (_isFailed) return const Color(0xffFF5F61);
    return const Color(0xff8D8D8D);
  }

  String _amountValue() {
    final amount = _t.amount.abs();
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }

  String _formattedAmount() => '${_amountValue()} ${_t.assetSymbol}';

  /// Names the saved/shared file. A transaction with no reference still needs a
  /// distinct name, so its id stands in.
  String get _receiptReference {
    final reference = _t.referenceId.trim();
    return reference.isNotEmpty ? reference : _t.id.trim();
  }

  String _formattedDate(String lang) {
    final dt = DateTime.tryParse(_t.createdAt);
    if (dt == null) return _t.createdAt;
    String two(int n) => n.toString().padLeft(2, '0');
    final month = AppStrings.get(lang, _monthKeys[dt.month - 1]);
    return '${dt.day} $month ${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  String _typeLabel(String lang) {
    if (_t.isAccountTransfer) {
      return _t.isDeposit
          ? AppStrings.get(lang, 'receive_label').replaceAll('/', '|')
          : AppStrings.get(lang, 'transfer_send').replaceAll('/', '|');
    }
    return _t.title.isNotEmpty ? _t.title : _t.type;
  }

  String _purpose() {
    final purpose = _t.metadata.purposeName.trim();
    return purpose.isNotEmpty ? purpose : '—';
  }

  Future<Uint8List?> _captureReceipt() async {
    try {
      final boundary =
          _receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing receipt: $e');
      return null;
    }
  }

  /// Writes the captured receipt to a temp file and returns its path.
  Future<String?> _writeReceiptToTempFile() async {
    final imageBytes = await _captureReceipt();
    if (imageBytes == null) return null;
    final directory = await getTemporaryDirectory();
    final imagePath = '${directory.path}/receipt_$_receiptReference.png';
    await File(imagePath).writeAsBytes(imageBytes);
    return imagePath;
  }

  Future<void> _handleDownload() async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isDownloading = true);

    final languageCode = context.read<WalletBloc>().state.languageCode;
    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final imagePath = await _writeReceiptToTempFile();
      if (imagePath != null) {
        await Gal.putImage(imagePath);

        if (mounted) {
          showMessage(
            AppStrings.get(languageCode, 'saved_successfully'),
            context: context,
            type: MessageType.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showMessage(
          AppStrings.get(languageCode, 'failed_to_save'),
          context: context,
          type: MessageType.error,
        );
      }
    }

    if (mounted) {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isSharing = true);

    final languageCode = context.read<WalletBloc>().state.languageCode;
    try {
      final imagePath = await _writeReceiptToTempFile();
      if (imagePath != null) {
        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imagePath)],
          text: '${AppStrings.get(languageCode, 'receipt')} $_receiptReference',
        );
      }
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  Widget _buildActionIcon(
    String asset,
    String label,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            SizedBox(
              height: 20.h,
              child: const CircularProgressIndicator(strokeWidth: 2),
            )
          else
            SvgPicture.asset(
              asset,
              height: 20.h,
              package: TrydosWalletStyles.packageName,
            ),
          SizedBox(height: 5.h),
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final lang = state.languageCode;
        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Offscreen receipt, captured by Download and Share. Same widget
              // the transfer success screen uses, so a receipt saved from here
              // is identical to one saved right after the transfer.
              PositionedDirectional(
                start: -4000,
                top: -4000,
                child: RepaintBoundary(
                  key: _receiptKey,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ReceiptWidget(
                      senderAccount: _t.senderAccount.accountNumber,
                      recipientAccount: _t.receiverAccount.accountNumber,
                      amount: _amountValue(),
                      currencySymbol: _t.assetSymbol,
                      reference: _receiptReference,
                      dateAndTimeString: _formattedDate(lang),
                      type: _typeLabel(lang),
                      purpose: _purpose(),
                      isSuccess: _isSuccess,
                      languageCode: lang,
                    ),
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30.w),
                decoration: BoxDecoration(
                  color: _isSuccess ? _successBackground : _neutralBackground,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30.r),
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(height: 10.h),
                    SvgPicture.asset(
                      TrydosWalletAssets.trydos,
                      height: 25.h,
                      package: TrydosWalletStyles.packageName,
                    ),
                    SizedBox(height: 18.h),
                    // Status pill
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 18.w,
                        vertical: 8.h,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _statusLabel(lang),
                            style: context.textTheme.bodyMedium?.mq.copyWith(
                              color: _statusColor,
                              fontSize: 13.sp,
                            ),
                          ),
                          if (_isSuccess) ...[
                            SizedBox(width: 8.w),
                            SvgPicture.asset(
                              TrydosWalletAssets.successed,
                              height: 12.h,
                              package: TrydosWalletStyles.packageName,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(height: 50.h),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow(
                              AppStrings.get(lang, 'sender_account'),
                              _t.senderAccount.accountNumber,
                              forceLtrValue: true,
                            ),
                            SizedBox(height: 5.h),
                            _infoRow(
                              AppStrings.get(lang, 'recipient_account'),
                              _t.receiverAccount.accountNumber,
                              forceLtrValue: true,
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoRow(
                                    AppStrings.get(lang, 'amount'),
                                    _formattedAmount(),
                                    isBold: true,
                                  ),
                                ),
                                Expanded(
                                  child: _infoRow(
                                    AppStrings.get(lang, 'reference'),
                                    _t.referenceId,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _infoRow(
                                    AppStrings.get(lang, 'date_time'),
                                    _formattedDate(lang),
                                  ),
                                ),
                                Expanded(
                                  child: _infoRow(
                                    AppStrings.get(lang, 'type'),
                                    _typeLabel(lang),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            _infoRow(
                              AppStrings.get(lang, 'purpose_of_send'),
                              _purpose(),
                            ),
                            SizedBox(height: 30.h),
                          ],
                        ),
                      ),
                    ),
                    SafeArea(
                      top: false,
                      left: false,
                      right: false,
                      bottom: true,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionIcon(
                            TrydosWalletAssets.done,
                            AppStrings.get(lang, 'done'),
                            widget.onDone,
                          ),
                          _buildActionIcon(
                            TrydosWalletAssets.download,
                            AppStrings.get(lang, 'download'),
                            _handleDownload,
                            isLoading: _isDownloading,
                          ),
                          _buildActionIcon(
                            TrydosWalletAssets.share,
                            AppStrings.get(lang, 'share'),
                            _handleShare,
                            isLoading: _isSharing,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 35.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(
    String label,
    String value, {
    bool isBold = false,
    bool forceLtrValue = false,
  }) {
    return SizedBox(
      height: 54.h,
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
          SizedBox(height: 5.h),
          Text(
            value,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            textDirection: forceLtrValue ? TextDirection.ltr : null,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
