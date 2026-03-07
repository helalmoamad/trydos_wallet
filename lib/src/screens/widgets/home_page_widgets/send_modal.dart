import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/transfer_send_modal.dart';

enum SendModalView { main, transfer }

/// ويدجت يعرض الـ Bottom Sheet الخاص بعمليات الإرسال والدفع.
class SendModal extends StatefulWidget {
  const SendModal({super.key});

  @override
  State<SendModal> createState() => _SendModalState();
}

class _SendModalState extends State<SendModal> {
  SendModalView _currentView = SendModalView.main;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            switchInCurve: Curves.easeOutQuart,
            switchOutCurve: Curves.easeInQuart,
            transitionBuilder: (Widget child, Animation<double> animation) {
              final isTransfer = child is TransferSendModal;
              final offset = isTransfer
                  ? Tween<Offset>(
                      begin: const Offset(1, 0),
                      end: Offset.zero,
                    ).animate(animation)
                  : Tween<Offset>(
                      begin: const Offset(-1, 0),
                      end: Offset.zero,
                    ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: _currentView == SendModalView.main
                ? _buildMainMenuView(key: const ValueKey('main'))
                : const TransferSendModal(key: ValueKey('transfer')),
          ),
        ),
      ),
    );
  }

  Widget _buildMainMenuView({Key? key}) {
    return Column(
      key: key,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 10),
        // Handle
        Container(
          width: 40,
          height: 2,
          decoration: BoxDecoration(
            color: const Color(0xffC4C2C2),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        // Top Icon
        SvgPicture.asset(
          TrydosWalletAssets.send,
          height: 40,
          package: TrydosWalletStyles.packageName,
        ),
        const SizedBox(height: 12),
        Text(
          'SEND | PAY | CASH WITHDRAWAL',
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
          title: 'Transfer | send',
          subtitle: 'Send | Transfer Money To rdb | cash | bank',
          onTap: () => setState(() => _currentView = SendModalView.transfer),
          actions2: [_buildTextAction('History', 11, onTap: () {})],
          actions1: [],
        ),

        // Second Card: Cash Withdrawal
        _buildActionCard(
          icon: TrydosWalletAssets.cashWithdrawal,
          title: 'Cash Withdrawal',
          subtitle: 'Withdrawal Via Our Centers Or Agents',
          onTap: () {},
          actions1: [_buildTextAction('Nearby Centers', 13, onTap: () {})],
          actions2: [_buildTextAction('History', 11, onTap: () {})],
        ),

        // Third Section: Bill Payments
        _buildBillPaymentsSection(),
        const SizedBox(height: 30),
      ],
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

  Widget _buildBillPaymentsSection() {
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
                          'Bill Payments',
                          style: TrydosWalletStyles.bodyMedium.copyWith(
                            color: const Color(0xff1D1D1D),
                            fontSize: 13,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pay Invoice | Bill |',
                          style: TrydosWalletStyles.bodyMedium.copyWith(
                            color: const Color(0xff8D8D8D),
                            fontSize: 11,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    _buildTextAction('History', 11, onTap: () {}),
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
