import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receive_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/send_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/widgets.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

enum QRScannerContentView { scanner, send, receive }

class QRScannerSwitchPage extends StatefulWidget {
  final bool? appairBack;

  const QRScannerSwitchPage({super.key, this.appairBack = false});

  @override
  State<QRScannerSwitchPage> createState() => _QRScannerSwitchPageState();
}

class _QRScannerSwitchPageState extends State<QRScannerSwitchPage>
    with WidgetsBindingObserver {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _didReturnResult = false;
  bool _isProcessing = false;
  bool _dialogShown = false;
  bool _dialogOpen = false;
  bool _closing = false;
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
      // Dispatch the scan and keep this sheet open showing a shimmer in place
      // of the camera until the request resolves (then we reveal the dialog).
      setState(() => _isProcessing = true);
      context.read<WalletBloc>().add(WalletQrScanRequested(raw));
      return;
    }
  }

  void _closeSheet(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  /// Shows the approve/reject dialog on top of the shimmering scanner sheet.
  void _showConfirmDialog(BuildContext sheetContext) {
    final bloc = sheetContext.read<WalletBloc>();
    _dialogOpen = true;
    showDialog<void>(
      context: sheetContext,
      barrierDismissible: true,
      builder: (dialogContext) =>
          BlocProvider.value(value: bloc, child: const _QrLoginConfirmDialog()),
    ).then((_) {
      _dialogOpen = false;
      // Dismissed without acting → cancel the request so the listener closes
      // the sheet too.
      if (bloc.state.qrLoginRequest != null) {
        bloc.add(const WalletQrLoginResetRequested());
      }
    });
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
        child: BlocConsumer<WalletBloc, WalletState>(
          listenWhen: (previous, current) =>
              previous.qrScanStatus != current.qrScanStatus ||
              previous.qrLoginRequest != current.qrLoginRequest,
          listener: (context, state) {
            if (!_isProcessing || _closing) return;

            // Scan failed → close the sheet; WalletHeader surfaces the error.
            if (state.qrScanStatus == WalletStatus.failure) {
              _closing = true;
              _closeSheet(context);
              return;
            }

            // Scan succeeded → reveal the approve/reject dialog on top of the
            // shimmering sheet (only once).
            if (state.qrLoginRequest != null && !_dialogShown) {
              _dialogShown = true;
              _showConfirmDialog(context);
              return;
            }

            // Request cleared after the dialog was shown — approve/reject
            // succeeded or the dialog was dismissed → close dialog + sheet.
            if (_dialogShown && state.qrLoginRequest == null) {
              _closing = true;
              final navigator = Navigator.of(context);
              if (_dialogOpen && navigator.canPop()) {
                navigator.pop(); // approve/reject dialog
              }
              if (navigator.canPop()) {
                navigator.pop(); // scanner sheet
              }
            }
          },
          builder: (context, state) {
            return Directionality(
              textDirection: state.isRtl
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: SizedBox(
                height: 850.h,
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 40.w),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30.r),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 350.h,
                        width: 350.w,

                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: _isProcessing
                            ? Shimmer.fromColors(
                                baseColor: const Color(0xFF2A2A2A),
                                highlightColor: const Color(0xFF5A5A5A),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(30.r),
                                  ),
                                ),
                              )
                            : ClipRRect(
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
                                              Colors.black.withValues(
                                                alpha: 0.0,
                                              ),
                                              Colors.black.withValues(
                                                alpha: 0.75,
                                              ),
                                            ],
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SvgPicture.asset(
                                              TrydosWalletAssets.qr,
                                              height: 25.h,

                                              colorFilter:
                                                  const ColorFilter.mode(
                                                    Color(0xffFCFCFC),
                                                    BlendMode.srcIn,
                                                  ),
                                              package: TrydosWalletStyles
                                                  .packageName,
                                            ),
                                            SizedBox(height: 10.h),
                                            Text(
                                              "Read The Code On The Opposite Side To Login",
                                              textAlign: TextAlign.center,
                                              style: context
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.rq
                                                  .copyWith(
                                                    color: const Color(
                                                      0xffFCFCFC,
                                                    ),
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
                      SizedBox(height: 48.h),
                      Text(
                        "Switch To Web",
                        textAlign: TextAlign.start,
                        style: context.textTheme.bodyMedium?.bq.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 30.sp,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Text(
                        '"You Can Use Your Account On The Web Securely And Easily."',
                        textAlign: TextAlign.start,
                        style: context.textTheme.bodyMedium?.rq.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 16.sp,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        '- Open The Website From The Browser Web',
                        textAlign: TextAlign.start,
                        style: context.textTheme.bodyMedium?.rq.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 14.sp,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        '- Choose Login Via Code Scanning',
                        textAlign: TextAlign.start,
                        style: context.textTheme.bodyMedium?.rq.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 14.sp,
                          height: 1.3,
                        ),
                      ),
                      SizedBox(height: 10.h),
                      Text(
                        '- Read The Code The Opposite Side From Here',
                        textAlign: TextAlign.start,
                        style: context.textTheme.bodyMedium?.rq.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 14.sp,
                          height: 1.3,
                        ),
                      ),

                      const Spacer(),
                      Center(
                        child: SvgPicture.asset(
                          TrydosWalletAssets.privacy,
                          height: 25.h,

                          colorFilter: const ColorFilter.mode(
                            Color(0xff388CFF),
                            BlendMode.srcIn,
                          ),
                          package: TrydosWalletStyles.packageName,
                        ),
                      ),
                      SizedBox(height: 15.h),
                      Center(
                        child: Text(
                          'Your Privacy Is Completely Safe',
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.rq.copyWith(
                            color: const Color(0xff388CFF),
                            fontSize: 14.sp,
                            height: 1.3,
                          ),
                        ),
                      ),
                      SizedBox(height: 35.h),
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
}

/// Which action the user actually tapped (drives the per-button spinner).
enum _QrPendingAction { none, approve, reject }

/// Approve/reject confirmation dialog for a scanned web-login request.
/// The scanner sheet owns closing this dialog, so it only manages the
/// per-button spinner locally.
class _QrLoginConfirmDialog extends StatefulWidget {
  const _QrLoginConfirmDialog();

  @override
  State<_QrLoginConfirmDialog> createState() => _QrLoginConfirmDialogState();
}

class _QrLoginConfirmDialogState extends State<_QrLoginConfirmDialog> {
  _QrPendingAction _pending = _QrPendingAction.none;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final request = state.qrLoginRequest;
        if (request == null) {
          return const SizedBox.shrink();
        }
        final isActionLoading = state.qrActionStatus == WalletStatus.loading;
        final approving =
            isActionLoading && _pending == _QrPendingAction.approve;
        final rejecting =
            isActionLoading && _pending == _QrPendingAction.reject;
        final languageCode = state.languageCode;

        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              'Log in to web — ${request.browser} on ${request.os}',
              style: context.textTheme.bodyMedium?.bq.copyWith(
                fontSize: 16.sp,
                color: const Color(0xFF1D1D1D),
                height: 1.3,
              ),
            ),
            content: Text(
              request.sameCity
                  ? "This login request expires at ${request.expiresAt != null ? request.expiresAt!.toLocal().toString() : 'soon'}."
                  : "⚠️ This computer appears to be in ${request.webCity ?? 'Unknown'}, but your phone is in ${request.appCity ?? 'Unknown'}. Approve only if this is you.",
              style: context.textTheme.bodyMedium?.rq.copyWith(
                fontSize: 13.sp,
                color: request.sameCity
                    ? const Color(0xFF4B5563)
                    : const Color(0xFF8A2B1C),
                height: 1.4,
              ),
            ),
            actionsPadding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              bottom: 12.h,
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isActionLoading
                          ? null
                          : () {
                              setState(
                                () => _pending = _QrPendingAction.reject,
                              );
                              context.read<WalletBloc>().add(
                                WalletQrRejectRequested(request.linkId),
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E6AE8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: rejecting
                          ? SizedBox(
                              height: 18.h,
                              width: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2E6AE8),
                              ),
                            )
                          : Text(
                              AppStrings.get(
                                languageCode,
                                'linked_devices_scan_reject_button',
                              ),
                              style: context.textTheme.bodyMedium?.rq.copyWith(
                                color: const Color(0xFF2E6AE8),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isActionLoading
                          ? null
                          : () {
                              setState(
                                () => _pending = _QrPendingAction.approve,
                              );
                              context.read<WalletBloc>().add(
                                WalletQrApproveRequested(request.linkId),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E6AE8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: approving
                          ? SizedBox(
                              height: 18.h,
                              width: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppStrings.get(
                                languageCode,
                                'linked_devices_scan_approve_button',
                              ),
                              style: context.textTheme.bodyMedium?.rq.copyWith(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
