import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';

/// ويدجت لعرض معاملة واحدة في القائمة.
class TransactionItem extends StatelessWidget {
  final String icon;
  final String directionIcon;
  final String title;
  final Color titleColor;
  final String subtitle;
  final InlineSpan? subtitleSpan;
  final Color subtitleColor;
  final String amount;
  final String symbol;
  final Color amountColor;
  final String status;
  final Color statusColor;
  final bool isSelected;
  final VoidCallback? onTap;

  const TransactionItem({
    super.key,
    required this.icon,
    required this.directionIcon,
    required this.symbol,
    required this.title,
    this.titleColor = Colors.black87,
    required this.subtitle,
    this.subtitleSpan,
    this.subtitleColor = Colors.grey,
    required this.amount,
    this.amountColor = Colors.black,
    required this.status,
    this.statusColor = Colors.grey,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 5.h),
        padding: EdgeInsetsDirectional.only(
          start: 10.w,
          top: 7.h,
          end: 10.w,
          bottom: 7.h,
        ),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: const Color(0xFFD3D3D3))
              : null,
          color: const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  icon,
                  package: TrydosWalletStyles.packageName,
                  height: 16.h,
                ),
                SizedBox(height: 3.h),
                SvgPicture.asset(
                  directionIcon,
                  package: TrydosWalletStyles.packageName,
                  height: 14.h,
                ),
              ],
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: context.textTheme.bodyMedium?.mq.copyWith(
                      fontSize: 13.sp,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text.rich(
                    subtitleSpan ?? TextSpan(text: subtitle),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.bodyMedium?.lq.copyWith(
                      color: subtitleColor,
                      fontSize: 11.sp,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Text(
                      amount,
                      style: context.textTheme.bodyMedium?.mq.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: amountColor,
                        fontSize: 13.sp,
                      ),
                    ),
                    Text(
                      symbol,
                      style: context.textTheme.bodyMedium?.lq.copyWith(
                        color: amountColor,
                        fontSize: 13.sp,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 3.h),
                Text(
                  status,
                  style: context.textTheme.bodyMedium?.lq.copyWith(
                    color: statusColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
