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

enum SendModalView { main, transfer }

/// ويدجت يعرض الـ Bottom Sheet الخاص بعمليات الإرسال والدفع.
class SendModal extends StatefulWidget {
  final ScrollController? scrollController;
  final QrTransferPayload? initialPayload;

  const SendModal({super.key, this.scrollController, this.initialPayload});

  @override
  State<SendModal> createState() => _SendModalState();
}

class _SendModalState extends State<SendModal> {
  late SendModalView _currentView;

  @override
  void initState() {
    super.initState();
    _currentView = widget.initialPayload == null
        ? SendModalView.main
        : SendModalView.transfer;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return IndexedStack(
          index: _currentView == SendModalView.main ? 0 : 1,
          children: [
            _buildMainMenuView(state, key: const ValueKey('main')),
            TransferSendModal(
              key: const ValueKey('transfer'),
              scrollController: widget.scrollController,
              initialPayload: widget.initialPayload,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMainMenuView(WalletState state, {Key? key}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                key: key,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    width: double.infinity,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xffC4C2C2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
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
                      height: 1.3,
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
                    title: AppStrings.get(
                      state.languageCode,
                      'cash_withdrawal',
                    ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
                          height: 1.3,
                        ),
                      ),
                      Row(children: actions1),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        subtitle,
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          color: const Color(0xff8D8D8D),
                          fontSize: 11,
                          height: 1.3,
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
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xffF7F7F7),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AppStrings.get(state.languageCode, 'pay_invoice_msg'),
                          style: TrydosWalletStyles.bodyMedium.copyWith(
                            color: const Color(0xff8D8D8D),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    _buildTextAction(
                      AppStrings.get(state.languageCode, 'history'),
                      11,
                      onTap: () {},
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
                  padding: const EdgeInsets.only(right: 8),
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
                          height: 1.3,
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
          height: 1.3,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
