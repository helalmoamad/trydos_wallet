import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../assets.dart';
import '../styles.dart';

/// رأس الصفحة (شعار + أيقونة QR).
class WalletHeader extends StatelessWidget {
  const WalletHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SvgPicture.asset(
            TrydosWalletAssets.rdb,
            package: TrydosWalletStyles.packageName,
            height: 30,
          ),
          SvgPicture.asset(
            TrydosWalletAssets.qr,
            package: TrydosWalletStyles.packageName,
            height: 35,
          ),
        ],
      ),
    );
  }
}
