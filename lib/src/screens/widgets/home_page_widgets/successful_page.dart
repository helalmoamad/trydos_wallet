import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receipt_widget.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';
import 'package:trydos_wallet/src/utils/ui_utils.dart';

class SuccessfulPage extends StatefulWidget {
  final String senderAccount;
  final String recipientAccount;
  final String amount;
  final String currencySymbol;
  final String reference;
  final String dateAndTimeString;
  final String type;
  final String purpose;
  final bool isSuccess;
  final VoidCallback onDone;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final bool isFromQr;

  // Optional Unregistered Phone fields
  final String? recipientPhoneNumber;
  final String? recipientName;
  final String? recipientId;

  const SuccessfulPage({
    super.key,
    required this.senderAccount,
    required this.recipientAccount,
    required this.amount,
    required this.currencySymbol,
    required this.reference,
    required this.dateAndTimeString,
    required this.type,
    required this.purpose,
    required this.onDone,
    required this.onDownload,
    required this.onShare,
    this.isSuccess = true,
    this.isFromQr = false,
    this.recipientPhoneNumber,
    this.recipientName,
    this.recipientId,
  });

  @override
  State<SuccessfulPage> createState() => _SuccessfulPageState();
}

class _SuccessfulPageState extends State<SuccessfulPage> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isDownloading = false;
  bool _isSharing = false;
  bool _appliedModalUi = false;

  static const Color _successModalBackground = Color(0xffF4FFFA);
  static const Color _defaultModalBackground = Colors.white;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_appliedModalUi) {
      return;
    }
    _appliedModalUi = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackButton(context, visible: false);
      setWalletModalBackground(
        context,
        widget.isSuccess ? _successModalBackground : _defaultModalBackground,
      );
    });
  }

  String _successQrPayload() {
    return QrTransferPayloadCodec.buildTransferResultPayload(
      senderAccount: widget.senderAccount,
      recipientAccount: widget.recipientAccount,
      amount: widget.amount,
      currencySymbol: widget.currencySymbol,
      reference: widget.reference,
      dateAndTime: widget.dateAndTimeString,
      transferType: widget.type,
      purpose: widget.purpose,
      isSuccess: widget.isSuccess,
    );
  }

  Future<Uint8List?> _captureReceipt() async {
    try {
      RenderRepaintBoundary boundary =
          _receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing receipt: $e");
      return null;
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isDownloading = true);
    widget.onDownload(); // Trigger callback if needed

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final imageBytes = await _captureReceipt();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/receipt_${widget.reference}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        await Gal.putImage(imagePath);

        showMessage(
          // ignore: use_build_context_synchronously
          AppStrings.get(
            // ignore: use_build_context_synchronously
            context.read<WalletBloc>().state.languageCode,
            'saved_successfully',
          ),
          // ignore: use_build_context_synchronously
          context: context,
          type: MessageType.success,
        );
      }
    } catch (e) {
      showMessage(
        // ignore: use_build_context_synchronously
        AppStrings.get(
          // ignore: use_build_context_synchronously
          context.read<WalletBloc>().state.languageCode,
          'failed_to_save',
        ),
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
    widget.onShare(); // Trigger callback if needed

    try {
      final imageBytes = await _captureReceipt();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/receipt_${widget.reference}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [
            XFile(imagePath),
            // ignore: use_build_context_synchronously
          ],
          text:
              // ignore: use_build_context_synchronously
              '${AppStrings.get(context.read<WalletBloc>().state.languageCode, 'receipt')} ${widget.reference}',
        );
      }
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Hidden receipt for screen capture
              PositionedDirectional(
                start: -4000,
                top: -4000,
                child: RepaintBoundary(
                  key: _receiptKey,
                  child: Material(
                    type: MaterialType.transparency,
                    child: ReceiptWidget(
                      senderAccount: widget.senderAccount,
                      recipientAccount: widget.recipientAccount,
                      amount: widget.amount,
                      currencySymbol: widget.currencySymbol,
                      reference: widget.reference,
                      dateAndTimeString: widget.dateAndTimeString,
                      type: widget.type,
                      purpose: widget.purpose,
                      isSuccess: widget.isSuccess,
                      isFromQr: widget.isFromQr,
                      recipientPhoneNumber: widget.recipientPhoneNumber,
                      recipientName: widget.recipientName,
                      recipientId: widget.recipientId,
                      languageCode: state.languageCode,
                    ),
                  ),
                ),
              ),

              // Visible UI
              Container(
                padding: EdgeInsets.symmetric(horizontal: 30.h),
                decoration: BoxDecoration(
                  color: const Color(0xffF4FFFA),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30.r),
                  ),
                ),
                child: Column(
                  children: [
                    SvgPicture.asset(
                      TrydosWalletAssets.sendSuccess,
                      height: 40.h,
                      package: TrydosWalletStyles.packageName,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      widget.isSuccess
                          ? AppStrings.get(
                              state.languageCode,
                              'money_sent_success',
                            ).toUpperCase()
                          : AppStrings.get(
                              state.languageCode,
                              'transaction_failed',
                            ).toUpperCase(),
                      style: context.textTheme.bodyMedium?.mq.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: 13.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Container(
                      color: const Color(0xffF4FFFA),
                      child: SizedBox.square(
                        dimension: 120.h,
                        child: PrettyQrView.data(
                          data: _successQrPayload(),
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
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      widget.reference,
                      style: context.textTheme.bodyMedium?.mq.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: 11.sp,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            _buildInfoRow(
                              AppStrings.get(
                                state.languageCode,
                                'sender_account',
                              ),
                              widget.senderAccount,
                            ),
                            SizedBox(height: 5.h),
                            if (widget.recipientPhoneNumber != null &&
                                widget.recipientName != null &&
                                widget.recipientId != null) ...[
                              _buildInfoRow(
                                AppStrings.get(
                                  state.languageCode,
                                  'recipient_phone',
                                ),
                                widget.recipientPhoneNumber!,
                              ),
                              SizedBox(height: 5.h),
                              _buildInfoRow(
                                AppStrings.get(
                                  state.languageCode,
                                  'recipient_name_id',
                                ),
                                widget.recipientName!,
                              ),
                              SizedBox(height: 5.h),
                              _buildInfoRow(
                                AppStrings.get(
                                  state.languageCode,
                                  'recipient_id_num',
                                ),
                                widget.recipientId!,
                              ),
                            ] else
                              _buildInfoRow(
                                AppStrings.get(
                                  state.languageCode,
                                  'recipient_account',
                                ),
                                widget.recipientAccount,
                                qrData: widget.isFromQr
                                    ? _successQrPayload()
                                    : null,
                              ),
                            SizedBox(height: 5.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    AppStrings.get(
                                      state.languageCode,
                                      'amount_to_be_sent',
                                    ),
                                    '${widget.amount} ${widget.currencySymbol}',
                                    isBold: true,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoRow(
                                    AppStrings.get(
                                      state.languageCode,
                                      'reference',
                                    ),
                                    widget.reference,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    AppStrings.get(
                                      state.languageCode,
                                      'date_time',
                                    ),
                                    widget.dateAndTimeString,
                                  ),
                                ),
                                Expanded(
                                  child: _buildInfoRow(
                                    AppStrings.get(state.languageCode, 'type'),
                                    widget.type,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5.h),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInfoRow(
                                    AppStrings.get(
                                      state.languageCode,
                                      'purpose_of_send',
                                    ),
                                    widget.purpose,
                                  ),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        AppStrings.get(
                                          state.languageCode,
                                          'status',
                                        ),
                                        style: TrydosWalletStyles.bodyMedium
                                            .copyWith(
                                              color: const Color(0xff8D8D8D),
                                              fontSize: 9.sp,
                                            ),
                                      ),
                                      SizedBox(height: 5.h),
                                      Row(
                                        children: [
                                          Text(
                                            widget.isSuccess
                                                ? AppStrings.get(
                                                    state.languageCode,
                                                    'succeeded',
                                                  )
                                                : AppStrings.get(
                                                    state.languageCode,
                                                    'failed',
                                                  ),
                                            style: TrydosWalletStyles.bodyMedium
                                                .copyWith(
                                                  color: const Color(
                                                    0xff1D1D1D,
                                                  ),
                                                  fontSize: 11.sp,
                                                ),
                                          ),
                                          if (widget.isSuccess) ...[
                                            SizedBox(width: 12.w),
                                            SvgPicture.asset(
                                              TrydosWalletAssets.successed,
                                              height: 12.h,
                                              package: TrydosWalletStyles
                                                  .packageName,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30.h),
                            (widget.recipientPhoneNumber != null &&
                                        widget.recipientName != null &&
                                        widget.recipientId != null) ||
                                    widget.isFromQr
                                ? const SizedBox.shrink()
                                : SvgPicture.asset(
                                    TrydosWalletAssets.trydos,
                                    height: 25.h,
                                    package: TrydosWalletStyles.packageName,
                                  ),
                            (widget.recipientPhoneNumber != null &&
                                    widget.recipientName != null &&
                                    widget.recipientId != null)
                                ? const SizedBox.shrink()
                                : SizedBox(height: 70.h),
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
                            AppStrings.get(state.languageCode, 'done'),
                            widget.onDone,
                          ),
                          _buildActionIcon(
                            TrydosWalletAssets.download,
                            AppStrings.get(state.languageCode, 'download'),
                            _handleDownload,
                            isLoading: _isDownloading,
                          ),
                          _buildActionIcon(
                            TrydosWalletAssets.share,
                            AppStrings.get(state.languageCode, 'share'),
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

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    String? qrData,
  }) {
    return SizedBox(
      height: 54.h,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff8D8D8D),
                  fontSize: 11.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              if (qrData != null && qrData.isNotEmpty) ...[
                SvgPicture.asset(
                  TrydosWalletAssets.realQr,
                  height: 16.h,
                  width: 16.w,
                  package: TrydosWalletStyles.packageName,
                ),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  value,
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 13.sp,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
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
          if (isLoading && label != 'Done')
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
}
