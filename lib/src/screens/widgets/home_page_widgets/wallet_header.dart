import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receive_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/send_modal.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// رأس الصفحة (شعار + أيقونة QR).
class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      buildWhen: (previous, current) =>
          previous.balanceCardIsSelected != current.balanceCardIsSelected,
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SvgPicture.asset(
                TrydosWalletAssets.rdb,
                package: TrydosWalletStyles.packageName,
                height: 30,
              ),
              const Spacer(),
              state.balanceCardIsSelected
                  ? InkWell(
                      onTap: () {
                        showWalletModal(
                          context: context,
                          builder: (context, sc) => ReceiveModal(scrollController: sc),
                        );
                      },
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            TrydosWalletAssets.receive,
                            height: 20,
                            package: TrydosWalletStyles.packageName,
                          ),
                          Text(
                            "Receive",
                            style: TrydosWalletStyles.bodySmall.copyWith(
                              color: const Color(0xff404040),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(width: 20),
              state.balanceCardIsSelected
                  ? InkWell(
                      onTap: () {
                        final walletBloc = context.read<WalletBloc>();
                        showWalletModal(
                          context: context,
                          builder: (context, sc) => BlocProvider.value(
                            value: walletBloc,
                            child: SendModal(scrollController: sc),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          SvgPicture.asset(
                            TrydosWalletAssets.send,
                            height: 20,
                            package: TrydosWalletStyles.packageName,
                          ),
                          Text(
                            "Send",
                            style: TrydosWalletStyles.bodySmall.copyWith(
                              color: const Color(0xff404040),
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
              const SizedBox(width: 20),
              InkWell(
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
                child: SvgPicture.asset(
                  TrydosWalletAssets.qr,
                  package: TrydosWalletStyles.packageName,
                  height: 25,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
