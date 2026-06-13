import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

class ClientNamePage extends StatelessWidget {
  final String languageCode;
  final String firstName;
  final String lastName;
  final bool isVerified;

  const ClientNamePage({
    super.key,
    required this.languageCode,
    required this.isVerified,
    required this.firstName,
    required this.lastName,
  });

  bool get _isRtl => languageCode == 'ar' || languageCode == 'ku';

  /// Renders a document image from a network URL: a shimmer while loading,
  /// the [fallback] asset on error/missing URL.
  Widget _docImage({
    required String? url,
    required String fallback,
    required double width,
    required double height,
  }) {
    Widget shimmer() => Shimmer.fromColors(
      baseColor: const Color(0xffE6E6E6),
      highlightColor: const Color(0xffF7F7F7),
      child: Container(
        width: width,
        height: height,
        color: const Color(0xffEDEDED),
      ),
    );

    Widget asset() => Image.asset(
      fallback,
      package: TrydosWalletStyles.packageName,
      fit: BoxFit.cover,
      width: width,
      height: height,
    );

    if (url == null || url.isEmpty) return SizedBox.shrink();
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: width,
      height: height,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : shimmer(),
      errorBuilder: (context, error, stack) => asset(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fullName = '${firstName.trim()} ${lastName.trim()}'.trim();

    // Real uploaded document URLs from GET /api/kyc/current (verified users).
    final record = context.watch<WalletBloc>().state.kycCurrentRecord;
    final selfieUrl = record?.selfieImageUrl?.trim();
    final frontUrl = record?.documentFrontImageUrl?.trim();
    final backUrl = record?.documentBackImageUrl?.trim();

    return Directionality(
      textDirection: _isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xffFFFFFF),
        body: SafeArea(
          child: Column(
            children: [
              // Header
              SizedBox(
                height: 50.h,
                width: 1.sw,
                child: Row(
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
                      AppStrings.get(languageCode, 'client_name'),
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.rq.copyWith(
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
              SizedBox(height: 20.h),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 12.w),
                  child: Column(
                    children: [
                      // Client Name Cell
                      Container(
                        height: 56.h,
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFFFFF),
                          borderRadius: BorderRadius.circular(15.r),
                          border: Border.all(color: const Color(0xffC3C3C3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get(languageCode, 'client_name'),
                              style: context.textTheme.bodySmall?.rq.copyWith(
                                color: const Color(0xff8D8D8D),
                                fontSize: 12.sp,
                                height: 1.1,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Text(
                                  fullName.isEmpty
                                      ? AppStrings.get(
                                          languageCode,
                                          'not_provided',
                                        )
                                      : fullName,
                                  style: context.textTheme.bodyMedium?.mq
                                      .copyWith(
                                        color: const Color(0xFF1D1D1D),
                                        fontSize: 14.sp,
                                        height: 1.2,
                                      ),
                                ),
                                Spacer(),
                                !isVerified
                                    ? SizedBox.shrink()
                                    : SvgPicture.asset(
                                        TrydosWalletAssets.nVerify,
                                        height: 18.h,
                                        // ignore: deprecated_member_use
                                        color: const Color(0xff388CFF),
                                        package: TrydosWalletStyles.packageName,
                                      ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 5.h),
                      !isVerified
                          ? SizedBox.shrink()
                          : _InfoBox(
                              icon: TrydosWalletAssets.worrning,
                              iconColor: null,
                              backgroundColor: const Color(0xffFFF9F0),
                              titleColor: const Color(0xff8D8D8D),
                              descriptionColor: const Color(0xff8D8D8D),
                              title: AppStrings.get(
                                languageCode,
                                'Client Name Cannot Be Changed',
                              ),
                              description: AppStrings.get(
                                languageCode,
                                'Because It Is Linked To The Documents You Submitted',
                              ),

                              languageCode: languageCode,
                            ),
                      // Warning box 1
                      isVerified
                          ? SizedBox.shrink()
                          : _InfoBox(
                              icon: TrydosWalletAssets.worrning,
                              iconColor: null,
                              backgroundColor: const Color(0xffF2FFF0),
                              titleColor: const Color(0xff8D8D8D),
                              descriptionColor: const Color(0xff8D8D8D),
                              title: AppStrings.get(
                                languageCode,
                                'name_must_match_personal_identification',
                              ),
                              description: AppStrings.get(
                                languageCode,
                                'guarantee_funds_official_document',
                              ),
                              languageCode: languageCode,
                            ),
                      isVerified
                          ? SizedBox(height: 30.h)
                          : SizedBox(height: 5.h),
                      isVerified
                          ? Container(
                              width: 1.sw,
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: const Color(0xffFCFCFC),
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Client Uploaded Documents",
                                    style: context.textTheme.bodyMedium?.mq
                                        .copyWith(
                                          color: const Color(0xFF8D8D8D),
                                          fontSize: 12.sp,
                                          height: 1.2,
                                        ),
                                  ),
                                  SizedBox(height: 6.h),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Your Files",
                                        style: context.textTheme.bodyMedium?.mq
                                            .copyWith(
                                              color: const Color(0xFF1D1D1D),
                                              fontSize: 14.sp,
                                              height: 1.2,
                                            ),
                                      ),
                                      Spacer(),
                                      SvgPicture.asset(
                                        TrydosWalletAssets.files,
                                        package: TrydosWalletStyles.packageName,
                                        height: 18.h,
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 15.h),
                                  SizedBox(
                                    height: 120.h,
                                    width: double.infinity,
                                    child: ListView(
                                      scrollDirection: Axis.horizontal,
                                      children: [
                                        SizedBox(
                                          width: 105.w,
                                          height: 120.h,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15.r,
                                            ),
                                            child: _docImage(
                                              url: selfieUrl,
                                              fallback: TrydosWalletPngAssets
                                                  .personImage,
                                              width: 105.w,
                                              height: 120.h,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 5.w),
                                        SizedBox(
                                          width: 190.w,
                                          height: 120.h,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              15.r,
                                            ),
                                            child: _docImage(
                                              url: frontUrl,
                                              fallback: TrydosWalletPngAssets
                                                  .frontImage,
                                              width: 190.w,
                                              height: 120.h,
                                            ),
                                          ),
                                        ),
                                        // Hide the back side entirely when the
                                        // document has no back image (e.g.
                                        // passport → documentBackImageUrl null).
                                        if (backUrl != null &&
                                            backUrl.isNotEmpty) ...[
                                          SizedBox(width: 5.w),
                                          SizedBox(
                                            width: 190.w,
                                            height: 120.h,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15.r),
                                              child: _docImage(
                                                url: backUrl,
                                                fallback: TrydosWalletPngAssets
                                                    .backImage,
                                                width: 190.w,
                                                height: 120.h,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : SizedBox.shrink(),
                      // Warning box 2
                      isVerified
                          ? SizedBox.shrink()
                          : _InfoBox(
                              icon: TrydosWalletAssets.worrning,
                              iconColor: null,
                              backgroundColor: const Color(0xffFFF9F0),
                              titleColor: const Color(0xff1D1D1D),
                              descriptionColor: const Color(0xff1D1D1D),
                              title: AppStrings.get(
                                languageCode,
                                'unprotected_account_limited_access',
                              ),
                              description: AppStrings.get(
                                languageCode,
                                'weekly_transfer_volume',
                              ),
                              trailing: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Text(
                                    ' 60/15 ',
                                    style: context.textTheme.bodyMedium?.bq
                                        .copyWith(
                                          color: const Color(0xFF1D1D1D),
                                          fontSize: 11.sp,
                                          height: 1.1,
                                        ),
                                  ),
                                  Text(
                                    AppStrings.get(languageCode, 'usd_renew'),
                                    style: context.textTheme.bodyMedium?.rq
                                        .copyWith(
                                          color: const Color(0xFF1D1D1D),
                                          fontSize: 11.sp,
                                          height: 1.1,
                                        ),
                                  ),
                                  Text(
                                    AppStrings.get(languageCode, 'fri_1010'),
                                    style: context.textTheme.bodyMedium?.rq
                                        .copyWith(
                                          color: const Color(0xFF1D1D1D),
                                          fontSize: 11.sp,
                                          height: 1.1,
                                        ),
                                  ),
                                ],
                              ),
                              languageCode: languageCode,
                            ),
                      isVerified ? SizedBox.shrink() : SizedBox(height: 5.h),
                      // Protect account blue box
                      isVerified
                          ? SizedBox.shrink()
                          : Container(
                              padding: EdgeInsets.all(12.w),
                              decoration: BoxDecoration(
                                color: const Color(0xffF2FFF0),
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      SvgPicture.asset(
                                        TrydosWalletAssets.successVerification,
                                        package: TrydosWalletStyles.packageName,
                                        height: 15.h,
                                      ),
                                      SizedBox(width: 5.w),
                                      Expanded(
                                        child: Text(
                                          AppStrings.get(
                                            languageCode,
                                            'protect_account_full_access',
                                          ),
                                          style: context
                                              .textTheme
                                              .bodyMedium
                                              ?.mq
                                              .copyWith(
                                                color: const Color(0xFF1D1D1D),
                                                fontSize: 11.sp,
                                                height: 1.1,
                                              ),
                                        ),
                                      ),
                                      SvgPicture.asset(
                                        TrydosWalletAssets.question,
                                        package: TrydosWalletStyles.packageName,
                                        height: 14.h,
                                        // ignore: deprecated_member_use
                                        color: const Color(0xFFC3C3C3),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 5.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 19.w,
                                    ),
                                    child: Text(
                                      AppStrings.get(
                                        languageCode,
                                        'secure_account_safe_transactions',
                                      ),
                                      style: context.textTheme.bodyMedium?.rq
                                          .copyWith(
                                            color: const Color(0xFF1D1D1D),
                                            fontSize: 11.sp,
                                            height: 1.1,
                                          ),
                                    ),
                                  ),
                                  Container(
                                    alignment: Alignment.center,
                                    margin: EdgeInsets.only(top: 12.h),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 12.w,
                                      vertical: 10.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffE0EDFF),
                                      borderRadius: BorderRadius.circular(15.r),
                                    ),
                                    child: InkWell(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const FirstPageKyc(),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SvgPicture.asset(
                                            TrydosWalletAssets
                                                .successVerification,
                                            package:
                                                TrydosWalletStyles.packageName,
                                            height: 15.h,
                                          ),
                                          SizedBox(width: 10.w),
                                          Text(
                                            AppStrings.get(
                                              languageCode,
                                              'protect_verify_now',
                                            ),
                                            style: context
                                                .textTheme
                                                .bodyMedium
                                                ?.mq
                                                .copyWith(
                                                  color: const Color(
                                                    0xFF1D1D1D,
                                                  ),
                                                  fontSize: 11.sp,
                                                  height: 1.1,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String icon;
  final Color? iconColor;
  final Color? titleColor;
  final Color? descriptionColor;
  final Color backgroundColor;
  final String title;
  final String description;
  final Widget? trailing;
  final String languageCode;

  const _InfoBox({
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.title,
    required this.description,
    required this.languageCode,
    this.trailing,
    this.titleColor,
    this.descriptionColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SvgPicture.asset(
                icon,
                package: TrydosWalletStyles.packageName,
                height: 14.h,
                // ignore: deprecated_member_use
                color: iconColor,
              ),
              SizedBox(width: 5.w),
              Expanded(
                child: Text(
                  title,
                  style: context.textTheme.bodyMedium?.mq.copyWith(
                    color: titleColor ?? const Color(0xFF1D1D1D),
                    fontSize: 11.sp,
                    height: 1.1,
                  ),
                ),
              ),
              (trailing == null)
                  ? SizedBox.shrink()
                  : SvgPicture.asset(
                      TrydosWalletAssets.question,
                      package: TrydosWalletStyles.packageName,
                      height: 14.h,
                      // ignore: deprecated_member_use
                      color: const Color(0xFFC3C3C3),
                    ),
            ],
          ),
          SizedBox(height: 5.h),
          Row(
            children: (trailing != null)
                ? [
                    SizedBox(width: 19.w),
                    Text(
                      description,
                      style: context.textTheme.bodyMedium?.rq.copyWith(
                        color: descriptionColor ?? const Color(0xFF1D1D1D),
                        fontSize: 11.sp,
                        height: 1.1,
                      ),
                    ),
                    trailing!,
                  ]
                : [
                    SizedBox(width: 19.w),
                    Expanded(
                      child: Text(
                        description,
                        style: context.textTheme.bodyMedium?.rq.copyWith(
                          color: descriptionColor ?? const Color(0xFF1D1D1D),
                          fontSize: 11.sp,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
          ),
        ],
      ),
    );
  }
}
