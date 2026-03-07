import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// بطاقة رصيد لتبويب My Wallet (مختارة = أزرق، غير مختارة = أبيض/رمادي).
class WalletBalanceCard extends StatelessWidget {
  final String currencyName;
  final String currencyCode;
  final String amount;
  final bool isSelected;
  final bool isLoadingBalance;
  final VoidCallback onTap;

  const WalletBalanceCard({
    super.key,
    required this.currencyName,
    required this.currencyCode,
    required this.amount,
    required this.isSelected,
    required this.isLoadingBalance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? const Color(0xff315391) : Colors.white;
    final textColor = isSelected ? Colors.white : const Color(0xff8D8D8D);
    final labelColor = isSelected ? Colors.white : const Color(0xff6B6B6B);
    return GestureDetector(
      onTap: onTap,
      child: BlocBuilder<LocalizationBloc, LocalizationState>(
        builder: (context, locState) {
          return Container(
            width: 180,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? null
                  : Border.all(color: const Color(0xffE0E0E0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : const Color(0xffE8E8E8),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    currencyCode,
                    style: TrydosWalletStyles.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get(
                        locState.languageCode,
                        'available_balance',
                      ),
                      style: TrydosWalletStyles.bodySmall.copyWith(
                        color: labelColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (isLoadingBalance)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xff388CFF),
                            ),
                          )
                        else
                          Text(
                            amount,
                            style: TrydosWalletStyles.amountText.copyWith(
                              color: textColor,
                              fontSize: 22,
                            ),
                          ),
                        const SizedBox(width: 4),
                        Text(
                          currencyCode,
                          style: TrydosWalletStyles.bodySmall.copyWith(
                            color: labelColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
