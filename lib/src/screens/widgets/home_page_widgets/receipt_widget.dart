import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';

class ReceiptWidget extends StatelessWidget {
  final String senderAccount;
  final String recipientAccount;
  final String amount;
  final String currencySymbol;
  final String reference;
  final String dateAndTimeString;
  final String type;
  final String purpose;
  final bool isSuccess;
  final bool isFromQr;

  // Optional Unregistered Phone Fields
  final String? recipientPhoneNumber;
  final String? recipientName;
  final String? recipientId;

  const ReceiptWidget({
    super.key,
    required this.senderAccount,
    required this.recipientAccount,
    required this.amount,
    required this.currencySymbol,
    required this.reference,
    required this.dateAndTimeString,
    required this.type,
    required this.purpose,
    required this.isSuccess,
    this.isFromQr = false,
    this.recipientPhoneNumber,
    this.recipientName,
    this.recipientId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400, // Fixed width for consistent receipt aspect ratio
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            TrydosWalletAssets.trydos,
            height: 25,
            package: TrydosWalletStyles.packageName,
          ),
          const SizedBox(height: 10),
          Text(
            'Receipt',
            style: TrydosWalletStyles.bodyLarge.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 10),
          SvgPicture.asset(
            TrydosWalletAssets.realQr,
            height: 70,
            package: TrydosWalletStyles.packageName,
          ),
          const SizedBox(height: 10),
          Text(
            'Verification Code Number $reference',
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),

          _buildFullWidthBox('Sender Account Number', senderAccount),
          const SizedBox(height: 5),

          if (recipientPhoneNumber != null &&
              recipientName != null &&
              recipientId != null) ...[
            _buildFullWidthBox('Recipient Phone Number', recipientPhoneNumber!),
            const SizedBox(height: 5),
            _buildFullWidthBox(
              'Recipient Name & Surname Exact ID',
              recipientName!,
            ),
            const SizedBox(height: 5),
            _buildFullWidthBox('Recipient ID NUMBER', recipientId!),
            const SizedBox(height: 5),
          ] else ...[
            _buildFullWidthBox(
              'Recipient Account Number',
              recipientAccount,
              isFromQr: isFromQr,
            ),
            const SizedBox(height: 5),
          ],
          Row(
            children: [
              Expanded(
                child: _buildHalfWidthBox(
                  'Amount Sanded          ',
                  '$amount $currencySymbol',
                  isBold: true,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(child: _buildHalfWidthBox('Reference', reference)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _buildHalfWidthBox(
                  'Date & Time          ',
                  dateAndTimeString,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(child: _buildHalfWidthBox('Type', type)),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _buildHalfWidthBox(
                  'Purpose Of Money Send            ',
                  purpose,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildStatusBox(
                  'Status',
                  isSuccess ? 'Succeeded' : 'Failed',
                  isSuccess,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xffF9F9F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'You Can Receive The Money Through All Our Centers, Or You Can Download Our Application, Open An Account, Use The Money, And Benefit From All The Services.',
              style: TrydosWalletStyles.bodyMedium.copyWith(
                color: const Color(0xff8D8D8D),
                fontSize: 9,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullWidthBox(
    String label,
    String value, {
    bool isFromQr = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              if (isFromQr) ...[
                SvgPicture.asset(
                  TrydosWalletAssets.realQr,
                  height: 16,
                  width: 16,
                  package: TrydosWalletStyles.packageName,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                value,
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHalfWidthBox(String label, String value, {bool isBold = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 11,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(String label, String value, bool isSuccessStatus) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                value,
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 11,
                ),
              ),
              if (isSuccessStatus) ...[
                const SizedBox(width: 12),
                SvgPicture.asset(
                  TrydosWalletAssets.successed,
                  height: 12,
                  package: TrydosWalletStyles.packageName,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
