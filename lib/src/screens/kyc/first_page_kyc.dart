import 'package:dotted_border/dotted_border.dart';
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
import 'package:trydos_wallet/src/screens/kyc/start_kyc_methods.dart';

/// Digital wallet home page.
class FirstPageKyc extends StatelessWidget {
  const FirstPageKyc({super.key});

  @override
  Widget build(BuildContext context) {
    WalletBloc? existingBloc;
    try {
      existingBloc = BlocProvider.of<WalletBloc>(context);
    } catch (_) {
      existingBloc = null;
    }

    if (existingBloc != null) {
      return BlocProvider.value(
        value: existingBloc,
        child: const _FirstPageKycContent(),
      );
    }

    return BlocProvider(
      create: (context) => WalletBloc(),
      child: const _FirstPageKycContent(),
    );
  }
}

class _FirstPageKycContent extends StatelessWidget {
  const _FirstPageKycContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final lang = state.languageCode;
        final isRtl = lang == 'ar' || lang == 'ku';
        return Scaffold(
          backgroundColor: Color(0xffFFFDD0),
          body: Directionality(
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 288.h),
                Padding(
                  padding: EdgeInsets.only(
                    left: isRtl ? 0.w : 30.w,
                    right: isRtl ? 30.w : 0.w,
                  ),
                  child: Text(
                    AppStrings.get(lang, 'kyc_identity_verification'),
                    style: context.textTheme.titleLarge?.bq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.14,
                      height: 1.43,
                      fontSize: 30.sp,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Text(
                    AppStrings.get(lang, 'kyc_protect_account'),
                    style: context.textTheme.titleLarge?.mq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.14,
                      height: 1.1,
                      fontSize: 16.sp,
                    ),
                  ),
                ),
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Text(
                    AppStrings.get(lang, 'kyc_verify_description'),
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: const Color(0xff1D1D1D),
                      letterSpacing: 0.14,
                      height: 1.1,
                      fontSize: 12.sp,
                    ),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: SizedBox(
                    height: 30.h,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Mohamad Katmawi",
                          style: context.textTheme.titleLarge?.rq.copyWith(
                            color: const Color(0xff1D1D1D),
                            letterSpacing: 0.14,
                            height: 1.43,
                            fontSize: 12.sp,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        SvgPicture.asset(
                          TrydosWalletAssets.nVerify,
                          package: TrydosWalletStyles.packageName,
                          height: 15.h,
                        ),
                      ],
                    ),
                  ),
                ),

                Spacer(),
                Center(
                  child: SvgPicture.asset(
                    TrydosWalletAssets.privacy,
                    package: TrydosWalletStyles.packageName,
                    height: 15.h,
                  ),
                ),
                SizedBox(height: 10.h),
                Center(
                  child: Text(
                    AppStrings.get(lang, 'kyc_privacy_safe'),
                    style: context.textTheme.titleLarge?.rq.copyWith(
                      color: const Color(0xff4D84FF),
                      letterSpacing: 0.14,
                      height: 1.43,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const StartKycMethods(),
                        ),
                      );
                    },
                    child: DottedBorder(
                      padding: EdgeInsets.zero,
                      borderType: BorderType.RRect,
                      strokeCap: StrokeCap.round,
                      strokeWidth: 0.5,
                      dashPattern: const [3, 3],
                      radius: Radius.circular(20.r),
                      color: const Color(0xff5D5C5D),
                      child: Container(
                        width: 1.sw,
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: const Color(0xffFCFCFC),
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Center(
                          child: Text(
                            AppStrings.get(lang, 'kyc_start_verification'),
                            style: context.textTheme.displayMedium?.mq.copyWith(
                              color: const Color(0xff5D5C5D),
                              letterSpacing: 0.16,
                              height: 1.25,
                              fontSize: 16.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 30.h),
                Center(
                  child: InkWell(
                    highlightColor: Colors.transparent,
                    splashColor: Colors.transparent,
                    onTap: () async {},
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 10.h),
                      child: Text(
                        AppStrings.get(lang, 'kyc_later_limited'),
                        style: context.textTheme.titleLarge?.rq.copyWith(
                          color: const Color(0xff4D84FF),
                          letterSpacing: 0.14,
                          height: 1.43,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 35.h),
              ],
            ),
          ),
        );
      },
    );
  }
}
