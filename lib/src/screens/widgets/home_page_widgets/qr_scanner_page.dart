import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  @override
  void initState() {
    super.initState();
    // Simulate scanning for 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        // Mock data for a Request Flow
        const mockResult = '{'
            '"account_id": "100-708",'
            '"account_name": "R***** B***** T*********** Y***** L******** S*****",'
            '"amount": "100",'
            '"reference": "101213",'
            '"purpose": "work_partnership",'
            '"type": "Transfer | Send",'
            '"expiry_time": "2026-03-03T13:59:00Z"'
            '}';
        Navigator.pop(context, mockResult);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xffC4C2C2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Scanner Frame
              Container(
                height: 350,
                width: 400,
                margin: const EdgeInsets.symmetric(horizontal: 25),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    SvgPicture.asset(
                      TrydosWalletAssets.qr,
                      height: 16,
                      width: 16,
                      colorFilter: const ColorFilter.mode(
                        Color(0xffFCFCFC),
                        BlendMode.srcIn,
                      ),
                      package: TrydosWalletStyles.packageName,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      AppStrings.get(state.languageCode, 'scan_qr_msg'),
                      textAlign: TextAlign.center,
                      style: TrydosWalletStyles.bodyMedium.copyWith(
                        color: const Color(0xffFCFCFC),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 150),

              Text(
                AppStrings.get(state.languageCode, 'or_choose'),
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),

              // Options
              _buildOption(
                icon: TrydosWalletAssets.send,
                title: AppStrings.get(state.languageCode, 'send_pay_cash'),
                subtitle: AppStrings.get(state.languageCode, 'send_money_pay'),
                onTap: () {},
              ),
              const SizedBox(height: 5),
              _buildOption(
                icon: TrydosWalletAssets.receive,
                title: AppStrings.get(state.languageCode, 'receive_charge_request'),
                subtitle: AppStrings.get(state.languageCode, 'charge_wallet_msg'),
                onTap: () {},
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
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
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xffF8F8F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              height: 16,
              width: 16,

              package: TrydosWalletStyles.packageName,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 11,
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
