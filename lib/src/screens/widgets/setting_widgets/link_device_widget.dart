import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/qr_scanner_page.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

class LinkedDevicesPage extends StatefulWidget {
  final String languageCode;

  const LinkedDevicesPage({super.key, required this.languageCode});

  @override
  State<LinkedDevicesPage> createState() => _LinkedDevicesPageState();
}

class _LinkedDevicesPageState extends State<LinkedDevicesPage> {
  bool get _isRtl => widget.languageCode == 'ar' || widget.languageCode == 'ku';

  @override
  void initState() {
    super.initState();
    context.read<WalletBloc>().add(const WalletActiveSessionsRequested());
  }

  Future<void> _openQrScanner() async {
    final result = await showWalletModal<String>(
      context: context,
      builder: (_, __) => const QRScannerPage(fromQR: true),
    );

    if (!mounted || result == null || result.isEmpty) {
      return;
    }

    context.read<WalletBloc>().add(WalletQrScanRequested(result));
  }

  void _approveScan(String linkId) {
    context.read<WalletBloc>().add(WalletQrApproveRequested(linkId));
  }

  void _rejectScan(String linkId) {
    context.read<WalletBloc>().add(WalletQrRejectRequested(linkId));
  }

  void _deleteSession(String sessionId) {
    context.read<WalletBloc>().add(WalletSessionDeleteRequested(sessionId));
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: BlocConsumer<WalletBloc, WalletState>(
        listenWhen: (previous, current) =>
            previous.qrActionSuccessMessage != current.qrActionSuccessMessage &&
                current.qrActionSuccessMessage != null ||
            previous.sessionActionSuccessMessage !=
                    current.sessionActionSuccessMessage &&
                current.sessionActionSuccessMessage != null ||
            previous.sessionActionStatus != current.sessionActionStatus,
        listener: (context, state) {
          final successMessage =
              state.qrActionSuccessMessage ?? state.sessionActionSuccessMessage;
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
          }
        },
        builder: (context, state) {
          final qrRequest = state.qrLoginRequest;
          final errorMessage =
              state.qrScanErrorMessage ??
              state.qrActionErrorMessage ??
              state.activeSessionsErrorMessage ??
              state.sessionActionErrorMessage;
          final isScanning = state.qrScanStatus == WalletStatus.loading;
          final isActionLoading = state.qrActionStatus == WalletStatus.loading;
          final isSessionActionLoading =
              state.sessionActionStatus == WalletStatus.loading;
          final activeSessions = state.activeSessions;
          final activeSessionsLoading =
              state.activeSessionsStatus == WalletStatus.loading;
          if (errorMessage != null) {
            Future.delayed(const Duration(seconds: 3), () {
              // ignore: use_build_context_synchronously
              context.read<WalletBloc>().add(
                const WalletQrLoginResetRequested(),
              );
            });
          }
          return Scaffold(
            backgroundColor: const Color(0xffFFFFFF),
            body: SafeArea(
              child: Column(
                children: [
                  SizedBox(
                    height: 50.h,
                    width: 1.sw,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
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
                                AppStrings.get(
                                  widget.languageCode,
                                  'linked_devices_title',
                                ),
                                textAlign: TextAlign.center,
                                style: context.textTheme.bodyMedium?.rq
                                    .copyWith(
                                      fontSize: 16.sp,
                                      height: 1.1,
                                      color: const Color(0xFF1D1D1D),
                                    ),
                              ),
                              SizedBox(width: 20.w),
                              const Spacer(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Text(
                      AppStrings.get(
                        widget.languageCode,
                        'linked_devices_description',
                      ),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.rq.copyWith(
                        color: const Color(0xFF6B6B6B),
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F8F8),
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: const Color(0xFFE1E5EE),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: 150.w,
                                  height: 150.w,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFFFFF),
                                    borderRadius: BorderRadius.circular(24.r),
                                    border: Border.all(
                                      color: const Color(0xFFD3D3D3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      TrydosWalletAssets.qr,
                                      package: TrydosWalletStyles.packageName,
                                      width: 76.w,
                                      height: 76.w,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24.h),
                                Text(
                                  AppStrings.get(
                                    widget.languageCode,
                                    'linked_devices_scan_title',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodyMedium?.rq
                                      .copyWith(
                                        fontSize: 16.sp,
                                        color: const Color(0xFF1D1D1D),
                                        height: 1.4,
                                      ),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  AppStrings.get(
                                    widget.languageCode,
                                    'linked_devices_scan_hint',
                                  ),
                                  textAlign: TextAlign.center,
                                  style: context.textTheme.bodyMedium?.rq
                                      .copyWith(
                                        fontSize: 13.sp,
                                        color: const Color(0xFF6B6B6B),
                                        height: 1.5,
                                      ),
                                ),
                                SizedBox(height: 20.h),
                              ],
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            margin: EdgeInsets.only(top: 20.h, bottom: 20.h),
                            padding: EdgeInsets.only(
                              left: 16.w,
                              right: 16.w,
                              top: 16.h,
                              bottom: 0.h,
                            ),
                            height: 220.h,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: const Color(0xFFE1E5EE),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.get(
                                        widget.languageCode,
                                        'linked_devices',
                                      ),
                                      style: context.textTheme.bodyMedium?.rq
                                          .copyWith(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1D1D1D),
                                          ),
                                    ),
                                    SizedBox(width: 6.w),
                                    Text(
                                      '(${activeSessions.length})',
                                      style: context.textTheme.bodyMedium?.rq
                                          .copyWith(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF1D1D1D),
                                          ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10.h),
                                if (activeSessionsLoading)
                                  Center(
                                    child: SizedBox(
                                      width: 20.w,
                                      height: 20.w,
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                else if (activeSessions.isEmpty)
                                  Text(
                                    AppStrings.get(
                                      widget.languageCode,
                                      'linked_devices_no_active_sessions',
                                    ),
                                    style: context.textTheme.bodyMedium?.rq
                                        .copyWith(
                                          fontSize: 13.sp,
                                          color: const Color(0xFF6B6B6B),
                                          height: 1.4,
                                        ),
                                  )
                                else
                                  Expanded(
                                    child: SingleChildScrollView(
                                      child: Column(
                                        children: activeSessions
                                            .map(
                                              (session) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: 12.h,
                                                ),
                                                child: Container(
                                                  width: double.infinity,
                                                  padding: EdgeInsets.all(14.w),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFFFFFFFF,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16.r,
                                                        ),
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFFE1E5EE,
                                                      ),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              session
                                                                  .deviceName,
                                                              style: context
                                                                  .textTheme
                                                                  .bodyMedium
                                                                  ?.rq
                                                                  .copyWith(
                                                                    fontSize:
                                                                        13.sp,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w700,
                                                                    color: const Color(
                                                                      0xFF1D1D1D,
                                                                    ),
                                                                  ),
                                                            ),
                                                          ),
                                                          if (session.isCurrent)
                                                            Container(
                                                              padding:
                                                                  EdgeInsets.symmetric(
                                                                    horizontal:
                                                                        10.w,
                                                                    vertical:
                                                                        4.h,
                                                                  ),
                                                              decoration: BoxDecoration(
                                                                color:
                                                                    const Color(
                                                                      0xFFE7F1FF,
                                                                    ),
                                                                borderRadius:
                                                                    BorderRadius.circular(
                                                                      12.r,
                                                                    ),
                                                              ),
                                                              child: Text(
                                                                AppStrings.get(
                                                                  widget
                                                                      .languageCode,
                                                                  'active_session',
                                                                ),
                                                                style: context
                                                                    .textTheme
                                                                    .bodyMedium
                                                                    ?.rq
                                                                    .copyWith(
                                                                      fontSize:
                                                                          11.sp,
                                                                      color: const Color(
                                                                        0xFF2E6AE8,
                                                                      ),
                                                                    ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                      SizedBox(height: 8.h),
                                                      Text(
                                                        '${session.platform.toUpperCase()} · ${session.ipAddress}',
                                                        style: context
                                                            .textTheme
                                                            .bodyMedium
                                                            ?.rq
                                                            .copyWith(
                                                              fontSize: 12.sp,
                                                              color:
                                                                  const Color(
                                                                    0xFF6B6B6B,
                                                                  ),
                                                              height: 1.4,
                                                            ),
                                                      ),
                                                      if (session
                                                              .lastActiveAt !=
                                                          null)
                                                        Text(
                                                          AppStrings.get(
                                                            widget.languageCode,
                                                            'linked_devices_last_active',
                                                          ).replaceFirst(
                                                            '{time}',
                                                            session
                                                                .lastActiveAt!
                                                                .toLocal()
                                                                .toString(),
                                                          ),
                                                          style: context
                                                              .textTheme
                                                              .bodyMedium
                                                              ?.rq
                                                              .copyWith(
                                                                fontSize: 12.sp,
                                                                color:
                                                                    const Color(
                                                                      0xFF6B6B6B,
                                                                    ),
                                                                height: 1.4,
                                                              ),
                                                        ),
                                                      SizedBox(height: 10.h),
                                                      (session.isCurrent ||
                                                              isSessionActionLoading)
                                                          ? Shimmer.fromColors(
                                                              baseColor:
                                                                  const Color(
                                                                    0xFFE0E0E0,
                                                                  ),
                                                              highlightColor:
                                                                  const Color(
                                                                    0xFFF5F5F5,
                                                                  ),
                                                              child: Container(
                                                                width: double
                                                                    .infinity,
                                                                height: 40.h,
                                                                decoration: BoxDecoration(
                                                                  color: const Color(
                                                                    0xFFE0E0E0,
                                                                  ),
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        16.r,
                                                                      ),
                                                                ),
                                                              ),
                                                            )
                                                          : Row(
                                                              children: [
                                                                Expanded(
                                                                  child: OutlinedButton(
                                                                    onPressed:
                                                                        session.isCurrent ||
                                                                            isSessionActionLoading
                                                                        ? null
                                                                        : () => _deleteSession(
                                                                            session.id,
                                                                          ),
                                                                    style: OutlinedButton.styleFrom(
                                                                      side: const BorderSide(
                                                                        color: Color(
                                                                          0xFF2E6AE8,
                                                                        ),
                                                                      ),
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              16.r,
                                                                            ),
                                                                      ),
                                                                      padding: EdgeInsets.symmetric(
                                                                        vertical:
                                                                            14.h,
                                                                      ),
                                                                    ),
                                                                    child: Text(
                                                                      session.isCurrent
                                                                          ? AppStrings.get(
                                                                              widget.languageCode,
                                                                              'linked_devices_current_device',
                                                                            )
                                                                          : AppStrings.get(
                                                                              widget.languageCode,
                                                                              'linked_devices_remove_button',
                                                                            ),
                                                                      style: context.textTheme.bodyMedium?.rq.copyWith(
                                                                        color:
                                                                            session.isCurrent
                                                                            ? const Color(
                                                                                0xFF6B6B6B,
                                                                              )
                                                                            : const Color(
                                                                                0xFF2E6AE8,
                                                                              ),
                                                                        fontSize:
                                                                            14.sp,
                                                                        fontWeight:
                                                                            FontWeight.w700,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          if (errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(14.w),
                              margin: EdgeInsets.only(bottom: 16.h),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF1F0),
                                borderRadius: BorderRadius.circular(16.r),
                                border: Border.all(
                                  color: const Color(0xFFFFC1BC),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                errorMessage,
                                style: context.textTheme.bodyMedium?.rq
                                    .copyWith(
                                      color: const Color(0xFFB12A2A),
                                      fontSize: 13.sp,
                                    ),
                              ),
                            ),
                          ],
                          if (isScanning)
                            Shimmer.fromColors(
                              baseColor: const Color(0xFFBDBDBD),
                              highlightColor: const Color(0xFFEFEFEF),
                              child: Container(
                                width: double.infinity,
                                height: 56.h,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFBDBDBD),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                              ),
                            )
                          else if (qrRequest != null)
                            Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(16.w),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F9FF),
                                    borderRadius: BorderRadius.circular(16.r),
                                    border: Border.all(
                                      color: const Color(0xFFD9E6FF),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Log in to web — ${qrRequest.browser} on ${qrRequest.os}',
                                        style: context.textTheme.bodyMedium?.rq
                                            .copyWith(
                                              fontSize: 14.sp,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1D1D1D),
                                            ),
                                      ),
                                      SizedBox(height: 8.h),
                                      if (!qrRequest.sameCity)
                                        Text(
                                          "⚠️ This computer appears to be in ${qrRequest.webCity ?? 'Unknown'}, but your phone is in ${qrRequest.appCity ?? 'Unknown'}. Approve only if this is you.",
                                          style: context
                                              .textTheme
                                              .bodyMedium
                                              ?.rq
                                              .copyWith(
                                                fontSize: 12.sp,
                                                color: const Color(0xFF8A2B1C),
                                                height: 1.4,
                                              ),
                                        )
                                      else
                                        Text(
                                          "This login request expires at ${qrRequest.expiresAt != null ? qrRequest.expiresAt!.toLocal().toString() : 'soon'}.",
                                          style: context
                                              .textTheme
                                              .bodyMedium
                                              ?.rq
                                              .copyWith(
                                                fontSize: 12.sp,
                                                color: const Color(0xFF4B5563),
                                                height: 1.4,
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 16.h),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: isActionLoading
                                            ? null
                                            : () => _approveScan(
                                                qrRequest.linkId,
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF2E6AE8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16.h,
                                          ),
                                        ),
                                        child: Text(
                                          AppStrings.get(
                                            widget.languageCode,
                                            'linked_devices_scan_approve_button',
                                          ),
                                          style: context
                                              .textTheme
                                              .bodyMedium
                                              ?.rq
                                              .copyWith(
                                                color: Colors.white,
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: isActionLoading
                                            ? null
                                            : () =>
                                                  _rejectScan(qrRequest.linkId),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(
                                            color: Color(0xFF2E6AE8),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16.r,
                                            ),
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            vertical: 16.h,
                                          ),
                                        ),
                                        child: Text(
                                          AppStrings.get(
                                            widget.languageCode,
                                            'linked_devices_scan_reject_button',
                                          ),
                                          style: context
                                              .textTheme
                                              .bodyMedium
                                              ?.rq
                                              .copyWith(
                                                color: const Color(0xFF2E6AE8),
                                                fontSize: 15.sp,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Container(
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(horizontal: 6.w),
                              child: ElevatedButton(
                                onPressed: _openQrScanner,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E6AE8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16.r),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16.h),
                                ),
                                child: Text(
                                  AppStrings.get(
                                    widget.languageCode,
                                    'linked_devices_scan_button',
                                  ),
                                  style: context.textTheme.bodyMedium?.rq
                                      .copyWith(
                                        color: Colors.white,
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                            ),

                          SizedBox(height: 35.h),
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
}
