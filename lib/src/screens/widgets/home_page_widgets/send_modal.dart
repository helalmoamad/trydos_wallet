import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/transfer_send_modal.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';
import 'package:trydos_wallet/src/utils/ui_utils.dart';

enum SendModalView { main, transfer }

/// ويدجت يعرض الـ Bottom Sheet الخاص بعمليات الإرسال والدفع.
class SendModal extends StatefulWidget {
  final QrTransferPayload? initialPayload;
  final String? initialScanRaw;
  final VoidCallback? onBack;
  final bool popOnBack;

  const SendModal({
    super.key,
    this.initialPayload,
    this.initialScanRaw,
    this.onBack,
    this.popOnBack = true,
  });

  @override
  State<SendModal> createState() => _SendModalState();
}

class _SendModalState extends State<SendModal> {
  late SendModalView _currentView;
  late bool _hasInitialMainStep;
  bool _isTransferSuccessView = false;

  void _setTransferSuccessView(bool isSuccessView) {
    if (!mounted || _isTransferSuccessView == isSuccessView) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isTransferSuccessView == isSuccessView) return;
      setState(() {
        _isTransferSuccessView = isSuccessView;
      });
    });
  }

  void _handleBackAction() {
    if (_isTransferSuccessView) {
      Navigator.pop(context);
      return;
    }

    final goBackToMain =
        _currentView == SendModalView.transfer && _hasInitialMainStep;
    if (goBackToMain) {
      setState(() {
        _currentView = SendModalView.main;
      });
      return;
    }

    final callback = widget.onBack;
    if (widget.popOnBack) {
      Navigator.pop(context);
      if (callback != null) {
        Future<void>.delayed(const Duration(milliseconds: 950), callback);
      }
    } else {
      callback?.call();
    }
  }

  @override
  void initState() {
    super.initState();
    final hasInitialRaw = (widget.initialScanRaw ?? '').trim().isNotEmpty;
    _hasInitialMainStep = widget.initialPayload == null && !hasInitialRaw;
    _currentView = _hasInitialMainStep
        ? SendModalView.main
        : SendModalView.transfer;
  }

  void _syncModalBackButton() {
    final showBackButton = !_isTransferSuccessView;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackButton(
        context,
        visible: showBackButton,
        onPressed: _handleBackAction,
      );
    });
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
          return Directionality(
            textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: IndexedStack(
              index: _currentView == SendModalView.main ? 0 : 1,
              children: [
                _buildMainMenuView(state, key: const ValueKey('main')),
                TransferSendModal(
                  key: const ValueKey('transfer'),
                  initialPayload: widget.initialPayload,
                  initialScanRaw: widget.initialScanRaw,
                  onSuccessStateChanged: _setTransferSuccessView,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainMenuView(WalletState state, {Key? key}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          key: key,
          children: [
            // Top Icon
            SvgPicture.asset(
              TrydosWalletAssets.send,
              height: 40.h,
              package: TrydosWalletStyles.packageName,
            ),
            SizedBox(height: 10.h),
            Text(
              AppStrings.get(state.languageCode, 'send_pay_cash_upper'),
              style: context.textTheme.bodyMedium?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                fontSize: 13.sp,
              ),
            ),
            SizedBox(height: 20.h),

            // First Card: Transfer | send
            _buildActionCard(
              icon: TrydosWalletAssets.transferSend,
              title: AppStrings.get(state.languageCode, 'transfer_send'),
              subtitle: AppStrings.get(state.languageCode, 'transfer_send_msg'),
              onTap: () {
                setState(() => _currentView = SendModalView.transfer);
              },
              actions2: [
                _buildTextAction(
                  AppStrings.get(state.languageCode, 'history'),
                  11.sp,
                  onTap: () {},
                ),
              ],
              actions1: [],
            ),

            // Second Card: Cash Withdrawal
            _buildActionCard(
              icon: TrydosWalletAssets.cashWithdrawal,
              title: AppStrings.get(state.languageCode, 'cash_withdrawal'),
              subtitle: AppStrings.get(state.languageCode, 'withdrawal_msg'),
              onTap: () {},
              actions1: [
                _buildTextAction(
                  AppStrings.get(state.languageCode, 'nearby_centers'),
                  13.sp,
                  onTap: () {},
                ),
              ],
              actions2: [
                _buildTextAction(
                  AppStrings.get(state.languageCode, 'history'),
                  11.sp,
                  onTap: () {},
                ),
              ],
            ),

            // Third Section: Bill Payments
            _buildBillPaymentsSection(state),
            SizedBox(height: 20.h),
          ],
        );
      },
    );
  }

  Widget _buildActionCard({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required List<Widget> actions1,
    required List<Widget> actions2,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 17.h),

        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xffF8F8F8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,

          children: [
            SvgPicture.asset(
              icon,
              height: 25.h,
              package: TrydosWalletStyles.packageName,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: context.textTheme.bodyMedium?.mq.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 13.sp,
                        ),
                      ),
                      Row(children: actions1),
                    ],
                  ),
                  SizedBox(height: 5.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitle,
                        style: context.textTheme.bodyMedium?.rq.copyWith(
                          color: const Color(0xff8D8D8D),
                          fontSize: 11.sp,
                        ),
                      ),
                      Row(children: actions2),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillPaymentsSection(WalletState state) {
    final List<Map<String, String>> brands = [
      {'name': 'Shein', 'asset': TrydosWalletAssets.shein},
      {'name': 'Amazon', 'asset': TrydosWalletAssets.amazon},
      {'name': 'Paypal', 'asset': TrydosWalletAssets.paypal},
      {'name': 'Syriatel', 'asset': TrydosWalletAssets.syriatel},
      {'name': 'MTN', 'asset': TrydosWalletAssets.mtn},
      {'name': 'Netflix', 'asset': TrydosWalletAssets.netflix},
      {'name': 'Youtube', 'asset': TrydosWalletAssets.youtube},
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),

      padding: EdgeInsetsDirectional.only(top: 15.h, bottom: 15.h, start: 15.w),
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F7),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                TrydosWalletAssets.billPayments,
                width: 25.w,
                package: TrydosWalletStyles.packageName,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get(state.languageCode, 'bill_payments'),
                          style: context.textTheme.bodyMedium?.mq.copyWith(
                            color: const Color(0xff1D1D1D),
                            fontSize: 13.sp,
                          ),
                        ),
                        SizedBox(height: 5.h),
                        Text(
                          AppStrings.get(state.languageCode, 'pay_invoice_msg'),
                          style: context.textTheme.bodyMedium?.rq.copyWith(
                            color: const Color(0xff8D8D8D),
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.only(end: 15.w),
                      child: _buildTextAction(
                        AppStrings.get(state.languageCode, 'history'),
                        11.sp,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: brands.map((brand) {
                return Padding(
                  padding: EdgeInsetsDirectional.only(end: 8.w),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        brand['asset']!,
                        package: TrydosWalletStyles.packageName,
                        fit: BoxFit.contain,
                        height: 70.h,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        brand['name']!,
                        style: context.textTheme.bodyMedium?.rq.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextAction(
    String text,
    double fontSize, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        text,
        style: context.textTheme.bodyMedium?.rq.copyWith(
          color: const Color(0xff8D8D8D),
          fontSize: fontSize,

          decoration: TextDecoration.underline,
          decorationColor: const Color(0xff8D8D8D),
        ),
      ),
    );
  }
}
