import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: isSelected
          ? Container(
              width: MediaQuery.of(context).size.width,
              padding: const EdgeInsets.only(top: 12, left: 15, right: 15),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (symbolImageUrl != null && symbolImageUrl!.isNotEmpty)
                        Image.network(
                          symbolImageUrl!,

                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                        )
                      else
                        _buildFallbackIcon(),
                      const SizedBox(height: 10),
                      Text(
                        currencyName,
                        style: TrydosWalletStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (isLoadingBalance)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Text(
                            amount,
                            style: TrydosWalletStyles.amountText.copyWith(
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          currencyCode,
                          style: TrydosWalletStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            height: 1.3,
                          ),
                        ),
                        const Spacer(),

                        Column(
                          children: [
                            SvgPicture.asset(
                              TrydosWalletAssets.statistic,
                              package: TrydosWalletStyles.packageName,
                            ),
                            SizedBox(height: 5),
                            Text(
                              "statistic",
                              style: TrydosWalletStyles.bodySmall.copyWith(
                                color: Color(0xffFCFCFC),
                                fontSize: 9,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 25),
                        Column(
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SvgPicture.asset(
                                  TrydosWalletAssets.chart1,

                                  package: TrydosWalletStyles.packageName,
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Info",
                              style: TrydosWalletStyles.bodySmall.copyWith(
                                color: Color(0xffFCFCFC),
                                fontSize: 9,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 25),
                        Column(
                          children: [
                            SvgPicture.asset(
                              TrydosWalletAssets.info,
                              package: TrydosWalletStyles.packageName,
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Info",
                              style: TrydosWalletStyles.bodySmall.copyWith(
                                color: Color(0xffFCFCFC),
                                fontSize: 9,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 10),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Container(
              width: 200,
              padding: const EdgeInsets.only(top: 12, left: 15, right: 15),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (symbolImageUrl != null && symbolImageUrl!.isNotEmpty)
                        Image.network(
                          symbolImageUrl!,

                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
                        )
                      else
                        _buildFallbackIcon(),
                      const SizedBox(height: 10),
                      Text(
                        currencyName,
                        style: TrydosWalletStyles.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (isLoadingBalance)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          Text(
                            amount,
                            style: TrydosWalletStyles.amountText.copyWith(
                              color: Colors.white,
                              fontSize: 25,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          currencyCode,
                          style: TrydosWalletStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
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

  Widget _buildFallbackIcon() {
    if (symbol != null && symbol!.isNotEmpty) {
      return Text(
        symbol!,
        style: TrydosWalletStyles.headlineMedium.copyWith(
          color: Colors.white,
          fontSize: 20,
        ),
      );
    }
    if (flag != null) {
      return Text(flag!, style: const TextStyle(fontSize: 24));
    }
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.currency_exchange, color: Colors.white),
    );
  }
}
