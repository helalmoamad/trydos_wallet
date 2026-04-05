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

/// ويدجت لعرض بطاقة الرصيد (للمستخدم في الصفحة الرئيسية).
class BalanceCard extends StatelessWidget {
  final String? symbolImageUrl;
  final String? symbol;
  final String? flag;
  final String currencyName;
  final String amount;
  final String currencyCode;
  final Color color;
  final bool isSelected;
  final bool isLoadingBalance;
  final VoidCallback onTap;

  const BalanceCard({
    super.key,
    this.symbolImageUrl,
    this.symbol,
    this.flag,
    required this.currencyName,
    required this.amount,
    required this.currencyCode,
    required this.color,
    this.isSelected = false,
    this.isLoadingBalance = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: onTap,
          child: isSelected
              ? Container(
                  height: 120.h,
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsetsDirectional.only(
                    top: 12.h,
                    start: 12.w,
                    end: 15.w,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: Color(0xffD3D3D3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (symbolImageUrl != null &&
                              symbolImageUrl!.isNotEmpty)
                            Builder(
                              builder: (_) {
                                final isSvg = symbolImageUrl!
                                    .toLowerCase()
                                    .endsWith('.svg');
                                return Padding(
                                  padding: EdgeInsetsDirectional.only(
                                    start: 5.w,
                                  ),
                                  child: isSvg
                                      ? SvgPicture.network(
                                          symbolImageUrl!,
                                          height: 20.h,
                                          fit: BoxFit.cover,
                                          placeholderBuilder: (_) =>
                                              _buildFallbackIcon(),
                                        )
                                      : Image.network(
                                          symbolImageUrl!,
                                          height: 20.h,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildFallbackIcon(),
                                        ),
                                );
                              },
                            )
                          else
                            _buildFallbackIcon(),
                          SizedBox(height: 10.h),
                          Text(
                            currencyName,
                            style: context.textTheme.bodyMedium?.lq.copyWith(
                              color: Colors.white,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (isLoadingBalance)
                              SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Text(
                                amount,
                                style: context.textTheme.bodyMedium?.rq
                                    .copyWith(
                                      color: Colors.white,
                                      fontSize: 25.sp,
                                    ),
                              ),
                            SizedBox(width: 6.w),
                            Padding(
                              padding: EdgeInsets.only(top: 20.h),
                              child: Text(
                                currencyCode,
                                style: context.textTheme.bodyMedium?.lq
                                    .copyWith(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                      height: 1.3,
                                    ),
                              ),
                            ),
                            const Spacer(),
                            Column(
                              children: [
                                SvgPicture.asset(
                                  TrydosWalletAssets.statistic,
                                  package: TrydosWalletStyles.packageName,
                                  height: 15.h,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  AppStrings.get(
                                    state.languageCode,
                                    'statistic',
                                  ),
                                  style: context.textTheme.bodyMedium?.lq
                                      .copyWith(
                                        color: const Color(0xffFCFCFC),
                                        fontSize: 9.sp,
                                        height: 1.3,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(width: 30.w),
                            Column(
                              children: [
                                SvgPicture.asset(
                                  TrydosWalletAssets.chart,
                                  height: 15.h,
                                  package: TrydosWalletStyles.packageName,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  AppStrings.get(state.languageCode, 'chart'),
                                  style: context.textTheme.bodyMedium?.lq
                                      .copyWith(
                                        color: const Color(0xffFCFCFC),
                                        fontSize: 9.sp,
                                        height: 1.3,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(width: 30.w),
                            Column(
                              children: [
                                SvgPicture.asset(
                                  TrydosWalletAssets.info,
                                  height: 15.h,
                                  package: TrydosWalletStyles.packageName,
                                ),
                                SizedBox(height: 5.h),
                                Text(
                                  AppStrings.get(state.languageCode, 'info'),
                                  style: context.textTheme.bodyMedium?.lq
                                      .copyWith(
                                        color: const Color(0xffFCFCFC),
                                        fontSize: 9.sp,
                                        height: 1.3,
                                      ),
                                ),
                              ],
                            ),
                            SizedBox(width: 10.w),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  height: 120.h,
                  width: 200.w,
                  padding: EdgeInsetsDirectional.only(
                    top: 11.h,
                    start: 12.w,
                    end: 15.w,
                  ),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: Color(0xffD3D3D3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (symbolImageUrl != null &&
                              symbolImageUrl!.isNotEmpty)
                            Padding(
                              padding: EdgeInsetsDirectional.only(start: 5.w),
                              child: Builder(
                                builder: (_) {
                                  final isSvg = symbolImageUrl!
                                      .toLowerCase()
                                      .endsWith('.svg');
                                  return isSvg
                                      ? SvgPicture.network(
                                          symbolImageUrl!,
                                          height: 20.h,
                                          fit: BoxFit.cover,
                                          placeholderBuilder: (_) =>
                                              _buildFallbackIcon(),
                                        )
                                      : Image.network(
                                          symbolImageUrl!,
                                          height: 20.h,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _buildFallbackIcon(),
                                        );
                                },
                              ),
                            )
                          else
                            _buildFallbackIcon(),
                          SizedBox(height: 10.h),
                          Text(
                            currencyName,
                            style: context.textTheme.bodyMedium?.lq.copyWith(
                              color: Colors.white,
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 10.h),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (isLoadingBalance)
                              SizedBox(
                                width: 20.w,
                                height: 20.h,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            else
                              Text(
                                amount,
                                style: context.textTheme.bodyMedium?.mq
                                    .copyWith(
                                      color: Colors.white,
                                      fontSize: 25.sp,
                                    ),
                              ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: EdgeInsets.only(top: 20.h),
                              child: Text(
                                currencyCode,
                                style: context.textTheme.bodyMedium?.lq
                                    .copyWith(
                                      color: Colors.white,
                                      fontSize: 9.sp,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildFallbackIcon() {
    if (symbol != null && symbol!.isNotEmpty) {
      return Text(
        symbol!,
        style: TrydosWalletStyles.headlineMedium.copyWith(
          color: Colors.white,
          fontSize: 20.sp,
        ),
      );
    }
    if (flag != null) {
      return Text(flag!, style: TextStyle(fontSize: 24.sp));
    }
    return Container(
      width: 40.w,
      height: 40.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: const Icon(Icons.currency_exchange, color: Colors.white),
    );
  }
}
