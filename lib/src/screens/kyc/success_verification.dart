import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

/// Digital wallet home page.
class SuccessVerification extends StatefulWidget {
  final Function()? onDone;
  const SuccessVerification({super.key, this.onDone});

  @override
  State<SuccessVerification> createState() => _SuccessVerificationState();
}

class _SuccessVerificationState extends State<SuccessVerification> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final lang = state.languageCode;
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 288.h),
            Text(
              AppStrings.get(lang, 'kyc_success_verification'),
              style: context.textTheme.titleLarge?.bq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 30.sp,
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              AppStrings.get(lang, 'kyc_full_access'),
              style: context.textTheme.titleLarge?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 30.h),
            SvgPicture.asset(
              TrydosWalletAssets.successVerification,
              package: TrydosWalletStyles.packageName,
              height: 150.h,
            ),
            SizedBox(height: 20.h),
            Text(
              "Mohamad Katmawi",
              style: context.textTheme.titleLarge?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 18.sp,
              ),
            ),
          ],
        );
      },
    );
  }
}
