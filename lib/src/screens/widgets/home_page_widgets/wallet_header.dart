import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/qr_scanner_page.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receive_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/send_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/setting_widgets/qr_scanner_switch_widget.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// رأس الصفحة (شعار + أيقونة QR).
class WalletHeader extends StatelessWidget {
  final bool fromSettings;
  const WalletHeader({super.key, this.fromSettings = false});

  @override
  Widget build(BuildContext context) {
    Future<void> openQrScanner() async {
      // The scanner owns the whole web-login flow: it dispatches the scan,
      // shows a shimmer in place of the camera, reveals the approve/reject
      // dialog on top once the scan resolves, and closes both layers when the
      // action succeeds. Here we only surface a scan-time failure afterwards.
      await showWalletModal<String>(
        context: context,
        builder: (_, __) => const QRScannerSwitchPage(appairBack: false),
      );

      if (!context.mounted) return;

      final bloc = context.read<WalletBloc>();
      if (bloc.state.qrScanStatus == WalletStatus.failure) {
        final message = bloc.state.qrScanErrorMessage;
        if (message != null && message.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF1D1D1D),
            ),
          );
        }
        bloc.add(const WalletQrLoginResetRequested());
      }
    }

    final headerContent = BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (previous, current) =>
          previous.balanceCardIsSelected != current.balanceCardIsSelected ||
          previous.selectedAssetId != current.selectedAssetId,
      builder: (context, state) {
        return Padding(
          padding: EdgeInsetsDirectional.only(
            start: 24.w,
            end: 24.w,
            top: 20.h,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: fromSettings
                ? [
                    SvgPicture.asset(
                      TrydosWalletAssets.rdb,
                      package: TrydosWalletStyles.packageName,
                      height: 30.h,
                    ),

                    const Spacer(),
                    SizedBox(
                      child: InkWell(
                        onTap: openQrScanner,

                        child: Column(
                          children: [
                            SvgPicture.asset(
                              TrydosWalletAssets.switchIcon,
                              package: TrydosWalletStyles.packageName,
                              height: 23.h,
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              AppStrings.get(state.languageCode, 'Web'),
                              style: context.textTheme.bodyMedium?.rq.copyWith(
                                color: const Color(0xff1D1D1D),
                                fontSize: 10.sp,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 20.w),

                    SizedBox(
                      child: InkWell(
                        onTap: () {
                          emitLockEvent(LockEvent.lockEvent());
                        },

                        child: Column(
                          children: [
                            SvgPicture.asset(
                              TrydosWalletAssets.lock,
                              package: TrydosWalletStyles.packageName,
                              height: 23.h,
                            ),
                            SizedBox(height: 3.h),
                            Text(
                              AppStrings.get(state.languageCode, 'Lock'),
                              style: context.textTheme.bodyMedium?.rq.copyWith(
                                color: const Color(0xff1D1D1D),
                                fontSize: 10.sp,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ]
                : [
                    SvgPicture.asset(
                      TrydosWalletAssets.rdb,
                      package: TrydosWalletStyles.packageName,
                      height: 30.h,
                    ),
                    const Spacer(),
                    state.balanceCardIsSelected
                        ? InkWell(
                            onTap: () {
                              final walletBloc = context.read<WalletBloc>();
                              showWalletModal(
                                context: context,
                                builder: (context, sc) => BlocProvider.value(
                                  value: walletBloc,
                                  child: ReceiveModal(scrollController: sc),
                                ),
                              );
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                SvgPicture.asset(
                                  TrydosWalletAssets.receive,
                                  height: 20.h,
                                  package: TrydosWalletStyles.packageName,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  AppStrings.get(
                                    state.languageCode,
                                    'receive_label',
                                  ),
                                  style: context.textTheme.bodyMedium?.rq
                                      .copyWith(
                                        color: const Color(0xff404040),
                                        fontSize: 11.sp,
                                        height: 1.3,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : SizedBox(height: 30.h),
                    SizedBox(width: 30.w),
                    state.balanceCardIsSelected
                        ? InkWell(
                            onTap: () async {
                              final walletBloc = context.read<WalletBloc>();
                              final headerContext = context;

                              Future<void> openQRThenSend() async {
                                if (!headerContext.mounted) return;
                                final result = await showWalletModal<String>(
                                  context: headerContext,
                                  builder: (ctx, sc) => BlocProvider.value(
                                    value: walletBloc,
                                    child: QRScannerPage(fromQR: false),
                                  ),
                                );
                                if (!headerContext.mounted || result == null) {
                                  return;
                                }

                                final payload = QrTransferPayloadCodec.tryParse(
                                  result,
                                );
                                // Close the QR scanner modal.
                                showWalletModal(
                                  context: context,
                                  builder: (ctx, sc) => BlocProvider.value(
                                    value: walletBloc,
                                    child: SendModal(
                                      initialPayload: payload,
                                      initialScanRaw: result,
                                      onBack: openQRThenSend,
                                    ),
                                  ),
                                );
                              }

                              await openQRThenSend();
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                  TrydosWalletAssets.send,
                                  height: 20.h,
                                  package: TrydosWalletStyles.packageName,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  AppStrings.get(
                                    state.languageCode,
                                    'send_label',
                                  ),
                                  style: context.textTheme.bodyMedium?.rq
                                      .copyWith(
                                        color: const Color(0xff404040),
                                        fontSize: 11.sp,
                                        height: 1.3,
                                      ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(height: 25.h),
                              Text(
                                "",
                                style: context.textTheme.bodyMedium?.rq
                                    .copyWith(
                                      color: const Color(0xff404040),
                                      fontSize: 11.sp,
                                      height: 1.3,
                                    ),
                              ),
                            ],
                          ),
                    SizedBox(width: 30.w),
                    InkWell(
                      onTap: () async {
                        /*   if (!state.balanceCardIsSelected) {
                    showMessage(
                      AppStrings.get(
                        state.languageCode,
                        'select_currency_to_send_msg',
                      ),
                      context: context,
                      type: MessageType.error,
                    );
                    return;
                  }
*/
                        final walletBloc = context.read<WalletBloc>();
                        final headerContext = context;

                        Future<void> openQRThenSend() async {
                          if (!headerContext.mounted) return;
                          final result = await showWalletModal<String>(
                            context: headerContext,
                            builder: (ctx, sc) => BlocProvider.value(
                              value: walletBloc,
                              child: QRScannerPage(fromQR: true),
                            ),
                          );
                          if (!headerContext.mounted || result == null) return;

                          final payload = QrTransferPayloadCodec.tryParse(
                            result,
                          );

                          showWalletModal(
                            context: headerContext,
                            builder: (ctx, sc) => BlocProvider.value(
                              value: walletBloc,
                              child: SendModal(
                                initialPayload: payload,
                                initialScanRaw: result,
                                onBack: openQRThenSend,
                              ),
                            ),
                          );
                        }

                        await openQRThenSend();
                      },
                      child: SvgPicture.asset(
                        TrydosWalletAssets.qr,
                        package: TrydosWalletStyles.packageName,
                        height: 25.h,
                      ),
                    ),
                  ],
          ),
        );
      },
    );

    // QR web-login confirmation flow is only relevant in the settings header.
    if (!fromSettings) {
      return headerContent;
    }

    return BlocListener<WalletBloc, WalletState>(
      listenWhen: (previous, current) =>
          previous.qrActionSuccessMessage != current.qrActionSuccessMessage &&
          current.qrActionSuccessMessage != null,
      listener: (context, state) {
        // Approve/Reject succeeded (dialog already closed itself) → notify.
        final successMessage = state.qrActionSuccessMessage;
        if (successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                successMessage,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: Colors.white,
                ),
              ),
              backgroundColor: const Color(0xFF1D1D1D),
            ),
          );
          context.read<WalletBloc>().add(const WalletQrLoginResetRequested());
        }
      },
      child: headerContent,
    );
  }
}
