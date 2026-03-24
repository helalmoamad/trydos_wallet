import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/styles.dart';

/// ويدجت لعرض معاملة واحدة في القائمة.
class TransactionItem extends StatelessWidget {
  final String icon;
  final String directionIcon;
  final String title;
  final Color titleColor;
  final String subtitle;
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
        margin: const EdgeInsets.only(bottom: 5),
        padding: const EdgeInsetsDirectional.only(
          start: 10,
          top: 8,
          end: 14,
          bottom: 8,
        ),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: const Color(0xFFD3D3D3))
              : null,
          color: const Color(0xFFFCFCFC),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          children: [
            Column(
              children: [
                SvgPicture.asset(icon, package: TrydosWalletStyles.packageName),
                const SizedBox(height: 4),
                SvgPicture.asset(
                  directionIcon,
                  package: TrydosWalletStyles.packageName,
                ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      fontSize: 13,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TrydosWalletStyles.bodySmall.copyWith(
                      color: subtitleColor,
                      fontSize: 11,
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
                      style: TrydosWalletStyles.bodyMedium.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: amountColor,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      symbol,
                      style: TrydosWalletStyles.bodyMedium.copyWith(
                        color: amountColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TrydosWalletStyles.bodySmall.copyWith(
                    color: statusColor,
                    fontSize: 11,
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
