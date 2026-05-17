import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

class ClientQrPage extends StatefulWidget {
  final String languageCode;
  final String accountNumber;
  final String firstName;
  final String lastName;
  final String? phoneNumber;
  final bool isVerified;

  const ClientQrPage({
    super.key,
    required this.languageCode,
    required this.accountNumber,
    required this.isVerified,
    required this.firstName,
    required this.lastName,
    this.phoneNumber,
  });

  @override
  State<ClientQrPage> createState() => _ClientQrPageState();
}

class _ClientQrPageState extends State<ClientQrPage> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isDownloading = false;
  bool _isSharing = false;

  static const PrettyQrDecoration _qrDecoration = PrettyQrDecoration(
    shape: PrettyQrSquaresSymbol(
      color: Color(0xff1D1D1D),
      density: 0.98,
      rounding: 0.60,
      unifiedFinderPattern: true,
    ),
    quietZone: PrettyQrQuietZone.modules(0),
  );

  bool get _isRtl => widget.languageCode == 'ar' || widget.languageCode == 'ku';

  String _buildQrPayload() {
    return '${widget.accountNumber}|${widget.firstName} ${widget.lastName}|${widget.phoneNumber ?? ''}';
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

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/client_qr_${widget.accountNumber}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        await Gal.putImage(imagePath);

        // ignore: use_build_context_synchronously
        showMessage(
          AppStrings.get(widget.languageCode, 'saved_successfully'),
          // ignore: use_build_context_synchronously
          context: context,
          type: MessageType.success,
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      showMessage(
        AppStrings.get(widget.languageCode, 'failed_to_save'),
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

    try {
      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/client_qr_${widget.accountNumber}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(imagePath)],
          text:
              '${AppStrings.get(widget.languageCode, 'my_receipt_qr')} ${widget.accountNumber}',
        );
      }
    } catch (e) {
      debugPrint('Error sharing QR card: $e');
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: widget.accountNumber));
    showMessage(
      AppStrings.get(widget.languageCode, 'acc_copied_msg'),
      context: context,
      type: MessageType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrPayload = _buildQrPayload();
    final normalizedPhone = widget.phoneNumber?.trim().isNotEmpty == true
        ? (widget.phoneNumber!.startsWith('+')
              ? widget.phoneNumber!
              : '+${widget.phoneNumber!}')
        : AppStrings.get(widget.languageCode, 'not_provided');

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              SizedBox(
                height: 50.h,
                width: 1.sw,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10.w),
                      child: InkWell(
                        onTap: () => Navigator.of(context).pop(),
                        child: SvgPicture.asset(
                          TrydosWalletAssets.back,
                          package: TrydosWalletStyles.packageName,
                          height: 20.h,
                          matchTextDirection: true,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      AppStrings.get(widget.languageCode, 'client_id_label'),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.rq.copyWith(
                        fontSize: 16.sp,
                        height: 1.1,
                        color: const Color(0xFF1D1D1D),
                      ),
                    ),
                    const Spacer(),
                    SizedBox(width: 30.w),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              // QR Code Section with hidden capture card
              Expanded(
                child: Stack(
                  children: [
                    // Hidden card for screen capture (outside viewport)
                    PositionedDirectional(
                      start: -4000,
                      top: -4000,
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: _CleanClientQRCard(
                          accountNumber: widget.accountNumber,
                          firstName: widget.firstName,
                          isVerified: widget.isVerified,
                          lastName: widget.lastName,
                          phoneNumber: widget.phoneNumber,
                          qrPayload: qrPayload,
                          languageCode: widget.languageCode,
                        ),
                      ),
                    ),
                    // Visible Content
                    SingleChildScrollView(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        children: [
                          // Visible QR Code
                          Column(
                            children: [
                              SizedBox.square(
                                dimension: 250.h,
                                child: PrettyQrView.data(
                                  data: qrPayload,
                                  errorCorrectLevel: QrErrorCorrectLevel.M,
                                  decoration: _qrDecoration,
                                ),
                              ),
                              SizedBox(height: 5.h),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.accountNumber,
                                    style: context.textTheme.bodyMedium?.mq
                                        .copyWith(
                                          color: const Color(0xff1D1D1D),
                                          height: 1.1,
                                          fontSize: 16.sp,
                                        ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                  SizedBox(width: 5.w),
                                  Text(
                                    "ID",
                                    style: context.textTheme.bodyMedium?.mq
                                        .copyWith(
                                          color: const Color(0xff1D1D1D),
                                          fontSize: 16.sp,
                                          height: 1.1,
                                        ),
                                    textDirection: TextDirection.ltr,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 50.h),
                          // Client Info Section
                          Container(
                            width: 1.sw,
                            margin: EdgeInsets.symmetric(horizontal: 0.w),

                            child: Column(
                              children: [
                                _buildClientInfoRow(
                                  context,
                                  AppStrings.get(
                                    widget.languageCode,
                                    'client_name',
                                  ),
                                  '${widget.firstName} ${widget.lastName}',
                                  trailing: !widget.isVerified
                                      ? SizedBox.shrink()
                                      : SvgPicture.asset(
                                          TrydosWalletAssets.nVerify,
                                          height: 18.h,
                                          // ignore: deprecated_member_use
                                          color: const Color(0xff388CFF),
                                          package:
                                              TrydosWalletStyles.packageName,
                                        ),
                                ),
                                SizedBox(height: 5.h),
                                _buildClientInfoRow(
                                  context,
                                  AppStrings.get(
                                    widget.languageCode,
                                    'client_phone_number',
                                  ),
                                  normalizedPhone,
                                  forceLtr: true,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 30.h),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Action Buttons
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 35.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton(
                        asset: TrydosWalletAssets.copy,
                        label: AppStrings.get(widget.languageCode, 'copy'),
                        onTap: _handleCopy,
                      ),
                      _buildActionButton(
                        asset: TrydosWalletAssets.download,
                        label: AppStrings.get(widget.languageCode, 'download'),
                        onTap: _handleDownload,
                        isLoading: _isDownloading,
                      ),
                      _buildActionButton(
                        asset: TrydosWalletAssets.share,
                        label: AppStrings.get(widget.languageCode, 'share'),
                        onTap: _handleShare,
                        isLoading: _isSharing,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientInfoRow(
    BuildContext context,
    String label,
    String value, {
    bool forceLtr = false,
    Widget? trailing,
  }) {
    return Container(
      height: 56.h,
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 9.h),
      decoration: BoxDecoration(
        color: const Color(0xffFCFCFC),

        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodySmall?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 12.sp,
              height: 1.1,
            ),
          ),
          Spacer(),

          Row(
            children: [
              Text(
                value,
                style: context.textTheme.bodyMedium?.mq.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 14.sp,
                  height: 1.1,
                ),
                textDirection: forceLtr ? TextDirection.ltr : null,
              ),
              SizedBox(width: 10.w),
              if (trailing != null) trailing,
            ],
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
        height: 70.h,
        width: 70.w,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isLoading
                ? SizedBox(
                    height: 24.h,
                    width: 24.w,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff404040),
                    ),
                  )
                : SvgPicture.asset(
                    asset,
                    height: 20.h,
                    // ignore: deprecated_member_use
                    color: const Color(0xff404040),
                    package: TrydosWalletStyles.packageName,
                  ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: context.textTheme.bodySmall?.rq.copyWith(
                color: const Color(0xff404040),
                fontSize: 11.sp,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanClientQRCard extends StatelessWidget {
  final String accountNumber;
  final String firstName;
  final String lastName;
  final bool isVerified;
  final String? phoneNumber;
  final String qrPayload;
  final String languageCode;

  const _CleanClientQRCard({
    required this.accountNumber,
    required this.firstName,
    required this.isVerified,
    required this.lastName,
    this.phoneNumber,
    required this.qrPayload,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    final isRtl = languageCode == 'ar' || languageCode == 'ku';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 60.w),
        child: Container(
          width: 350.w,
          padding: EdgeInsets.all(25.r),
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 300.h,
                child: PrettyQrView.data(
                  data: qrPayload,
                  errorCorrectLevel: QrErrorCorrectLevel.M,
                  decoration: _ClientQrPageState._qrDecoration,
                ),
              ),
              SizedBox(height: 65.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    accountNumber,
                    style: context.textTheme.bodyMedium?.bq.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13.sp,
                      height: 1.1,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  SizedBox(width: 5.w),
                  Text(
                    "ID",
                    style: context.textTheme.bodyMedium?.rq.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13.sp,
                      height: 1.1,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ],
              ),
              SizedBox(height: 15.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    '$firstName $lastName',
                    style: context.textTheme.bodyMedium?.rq.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13.sp,
                      height: 1.1,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  SizedBox(width: 10.w),
                  !isVerified
                      ? SizedBox.shrink()
                      : SvgPicture.asset(
                          TrydosWalletAssets.nVerify,
                          height: 16.h,
                          // ignore: deprecated_member_use
                          color: const Color(0xff388CFF),
                          package: TrydosWalletStyles.packageName,
                        ),
                ],
              ),
              SizedBox(height: 15.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    phoneNumber?.trim().isNotEmpty == true
                        ? (phoneNumber!.startsWith('+')
                              ? phoneNumber!
                              : '+${phoneNumber!}')
                        : AppStrings.get(languageCode, 'not_provided'),
                    style: context.textTheme.bodyMedium?.rq.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13.sp,
                      height: 1.1,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                  SizedBox(width: 10.w),
                  SvgPicture.asset(
                    TrydosWalletAssets.phone,
                    height: 10.h,
                    // ignore: deprecated_member_use
                    color: const Color(0xff8D8D8D),
                    package: TrydosWalletStyles.packageName,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
