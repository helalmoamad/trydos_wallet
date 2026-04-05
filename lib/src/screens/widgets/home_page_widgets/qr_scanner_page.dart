import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receive_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/send_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/widgets.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

enum QRScannerContentView { scanner, send, receive }

class QRScannerPage extends StatefulWidget {
  final bool fromQR;
  final bool? appairBack;

  const QRScannerPage({
    super.key,
    this.fromQR = false,
    this.appairBack = false,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _didReturnResult = false;
  QRScannerContentView _contentView = QRScannerContentView.scanner;

  Future<void> _stopScanner() async {
    try {
      await _scannerController.stop();
    } on PlatformException catch (e) {
      final isNoActiveStream = (e.message ?? '').contains(
        'No active stream to cancel',
      );
      if (!isNoActiveStream) {
        debugPrint('Scanner stop error: ${e.message}');
      }
    } catch (e) {
      debugPrint('Scanner stop error: $e');
    }
  }

  Future<void> _startScannerIfNeeded() async {
    if (!mounted) return;
    if (_didReturnResult) return;
    if (_contentView != QRScannerContentView.scanner) return;
    try {
      await _scannerController.start();
    } catch (e) {
      debugPrint('Scanner start error: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  void _showScannerRoot() {
    if (!mounted) return;
    setState(() {
      _contentView = QRScannerContentView.scanner;
    });
    unawaited(_startScannerIfNeeded());
  }

  void _syncScannerBackButton() {
    if (_contentView != QRScannerContentView.scanner) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.appairBack == true) {
        setWalletModalBackButton(
          context,
          visible: true,
          onPressed: () => Navigator.pop(context),
        );
      } else {
        setWalletModalBackButton(context, visible: false);
      }
    });
  }

  Future<bool> _handleWillPop() async {
    if (!mounted) return false;
    if (_contentView != QRScannerContentView.scanner) {
      _showScannerRoot();
      return false;
    }

    unawaited(_stopScanner());
    if (widget.appairBack == true) {
      Navigator.pop(context);
      return false;
    }

    return true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      unawaited(_startScannerIfNeeded());
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_stopScanner());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted || _didReturnResult) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) {
        continue;
      }

      _didReturnResult = true;
      unawaited(_stopScanner());
      Navigator.pop(context, raw);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncScannerBackButton();

    if (_contentView == QRScannerContentView.send) {
      return SendModal(onBack: _showScannerRoot, popOnBack: false);
    }

    if (_contentView == QRScannerContentView.receive) {
      return ReceiveModal(onBack: _showScannerRoot);
    }

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: BlocBuilder<WalletBloc, WalletState>(
          builder: (context, state) {
            return Directionality(
              textDirection: state.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: SizedBox(
                height: 850.h,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30.r),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 350.h,
                        width: 350.w,
                        margin: EdgeInsets.symmetric(horizontal: 25.w),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child: Stack(
                            children: [
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: _onDetect,
                              ),
                              Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.only(bottom: 10.h),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.0),
                                        Colors.black.withValues(alpha: 0.75),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgPicture.asset(
                                        TrydosWalletAssets.qr,
                                        height: 25.h,

                                        colorFilter: const ColorFilter.mode(
                                          Color(0xffFCFCFC),
                                          BlendMode.srcIn,
                                        ),
                                        package: TrydosWalletStyles.packageName,
                                      ),
                                      SizedBox(height: 10.h),
                                      Text(
                                        AppStrings.get(
                                          state.languageCode,
                                          'scan_qr_msg',
                                        ),
                                        textAlign: TextAlign.center,
                                        style: context.textTheme.bodyMedium?.rq
                                            .copyWith(
                                              color: const Color(0xffFCFCFC),
                                              fontSize: 11.sp,
                                              height: 1.3,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!widget.fromQR)
                        SizedBox(
                          height: 224.h,
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                Container(
                                  margin: EdgeInsets.symmetric(
                                    horizontal: 10.w,
                                  ),
                                  height: 0.5,
                                  decoration: BoxDecoration(
                                    color: const Color(0xffD3D3D3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Text(
                                  AppStrings.get(
                                    state.languageCode,
                                    'or_choose',
                                  ),
                                  style: context.textTheme.bodyMedium?.rq
                                      .copyWith(
                                        color: const Color(0xff1D1D1D),
                                        fontSize: 13.sp,
                                        height: 1.3,
                                      ),
                                ),
                                SizedBox(height: 10.h),
                                _buildOption(
                                  icon: TrydosWalletAssets.send,
                                  title: AppStrings.get(
                                    state.languageCode,
                                    'send_pay_cash',
                                  ),
                                  subtitle: AppStrings.get(
                                    state.languageCode,
                                    'send_money_pay',
                                  ),
                                  onTap: () {
                                    _stopScanner();
                                    setState(() {
                                      _contentView = QRScannerContentView.send;
                                    });
                                  },
                                ),
                                SizedBox(height: 5.h),
                                _buildOption(
                                  icon: TrydosWalletAssets.receive,
                                  title: AppStrings.get(
                                    state.languageCode,
                                    'receive_charge_request',
                                  ),
                                  subtitle: AppStrings.get(
                                    state.languageCode,
                                    'charge_wallet_msg',
                                  ),
                                  onTap: () {
                                    _stopScanner();
                                    setState(() {
                                      _contentView =
                                          QRScannerContentView.receive;
                                    });
                                  },
                                ),
                                SizedBox(height: 40.h),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOption({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 73.h,
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.all(15.h),
        decoration: BoxDecoration(
          color: const Color(0xffF8F8F8),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              height: 25.h,

              package: TrydosWalletStyles.packageName,
            ),
            SizedBox(width: 15.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyMedium?.mq.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13.sp,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Text(
                    subtitle,
                    style: context.textTheme.bodyMedium?.rq.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 11.sp,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
