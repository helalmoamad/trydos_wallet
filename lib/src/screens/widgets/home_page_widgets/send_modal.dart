import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/transfer_send_modal.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';
import 'package:trydos_wallet/src/utils/ui_utils.dart';

enum SendModalView { main, transfer }

/// ويدجت يعرض الـ Bottom Sheet الخاص بعمليات الإرسال والدفع.
class SendModal extends StatefulWidget {
  final QrTransferPayload? initialPayload;
  final VoidCallback? onBack;
  final bool popOnBack;

  const SendModal({
    super.key,
    this.initialPayload,
    this.onBack,
    this.popOnBack = true,
  });

  @override
  State<SendModal> createState() => _SendModalState();
}

class _SendModalState extends State<SendModal> {
  late SendModalView _currentView;
  late bool _hasInitialMainStep;

  void _handleBackAction() {
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
    _hasInitialMainStep = widget.initialPayload == null;
    _currentView = _hasInitialMainStep
        ? SendModalView.main
        : SendModalView.transfer;
  }

  void _syncModalBackButton() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setWalletModalBackButton(
        context,
        visible: true,
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
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              key: key,
              children: [
                const SizedBox(height: 10),
                // Top Icon
                SvgPicture.asset(
                  TrydosWalletAssets.send,
                  height: 40,
                  package: TrydosWalletStyles.packageName,
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.get(state.languageCode, 'send_pay_cash_upper'),
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),

                // First Card: Transfer | send
                _buildActionCard(
                  icon: TrydosWalletAssets.transferSend,
                  title: AppStrings.get(state.languageCode, 'transfer_send'),
                  subtitle: AppStrings.get(
                    state.languageCode,
                    'transfer_send_msg',
                  ),
                  onTap: () =>
                      setState(() => _currentView = SendModalView.transfer),
                  actions2: [
                    _buildTextAction(
                      AppStrings.get(state.languageCode, 'history'),
                      11,
                      onTap: () {},
                    ),
                  ],
                  actions1: [],
                ),

                // Second Card: Cash Withdrawal
                _buildActionCard(
                  icon: TrydosWalletAssets.cashWithdrawal,
                  title: AppStrings.get(state.languageCode, 'cash_withdrawal'),
                  subtitle: AppStrings.get(
                    state.languageCode,
                    'withdrawal_msg',
                  ),
                  onTap: () {},
                  actions1: [
                    _buildTextAction(
                      AppStrings.get(state.languageCode, 'nearby_centers'),
                      13,
                      onTap: () {},
                    ),
                  ],
                  actions2: [
                    _buildTextAction(
                      AppStrings.get(state.languageCode, 'history'),
                      11,
                      onTap: () {},
                    ),
                  ],
                ),

                // Third Section: Bill Payments
                _buildBillPaymentsSection(state),
                const SizedBox(height: 20),
              ],
            ),
          ),
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xffF8F8F8),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset(
              icon,
              height: 25,
              package: TrydosWalletStyles.packageName,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 13,
                        ),
                      ),
                      Row(children: actions1),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitle,
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          color: const Color(0xff8D8D8D),
                          fontSize: 11,
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
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsetsDirectional.only(top: 15, bottom: 15, start: 15),
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SvgPicture.asset(
                TrydosWalletAssets.billPayments,
                width: 25,
                package: TrydosWalletStyles.packageName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppStrings.get(state.languageCode, 'bill_payments'),
                          style: TrydosWalletStyles.bodyMedium.copyWith(
                            color: const Color(0xff1D1D1D),
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.get(state.languageCode, 'pay_invoice_msg'),
                          style: TrydosWalletStyles.bodyMedium.copyWith(
                            color: const Color(0xff8D8D8D),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.only(end: 15.0),
                      child: _buildTextAction(
                        AppStrings.get(state.languageCode, 'history'),
                        11,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: brands.map((brand) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Column(
                    children: [
                      SvgPicture.asset(
                        brand['asset']!,
                        package: TrydosWalletStyles.packageName,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        brand['name']!,
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 13,
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
        style: TrydosWalletStyles.bodyMedium.copyWith(
          color: const Color(0xff8D8D8D),
          fontSize: fontSize,

          decoration: TextDecoration.underline,
          decorationColor: const Color(0xff8D8D8D),
        ),
      ),
    );
  }
}
