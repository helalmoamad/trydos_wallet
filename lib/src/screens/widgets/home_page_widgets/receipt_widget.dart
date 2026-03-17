import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';

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
  final String languageCode;

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
    required this.languageCode,
    this.isFromQr = false,
    this.recipientPhoneNumber,
    this.recipientName,
    this.recipientId,
  });

  String _receiptQrPayload() {
    return QrTransferPayloadCodec.buildTransferResultPayload(
      senderAccount: senderAccount,
      recipientAccount: recipientAccount,
      amount: amount,
      currencySymbol: currencySymbol,
      reference: reference,
      dateAndTime: dateAndTimeString,
      transferType: type,
      purpose: purpose,
      isSuccess: isSuccess,
    );
  }

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
            AppStrings.get(languageCode, 'receipt'),
            style: TrydosWalletStyles.bodyLarge.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox.square(
            dimension: 70,
            child: PrettyQrView.data(
              data: _receiptQrPayload(),
              errorCorrectLevel: QrErrorCorrectLevel.M,
              decoration: const PrettyQrDecoration(
                shape: PrettyQrSmoothSymbol(
                  color: Color(0xff1D1D1D),
                  roundFactor: 0.9,
                ),
                quietZone: PrettyQrQuietZone.modules(0),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${AppStrings.get(languageCode, 'id')} $reference',
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 20),

          _buildFullWidthBox(
            AppStrings.get(languageCode, 'sender_account'),
            senderAccount,
          ),
          const SizedBox(height: 5),

          if (recipientPhoneNumber != null &&
              recipientName != null &&
              recipientId != null) ...[
            _buildFullWidthBox(
              AppStrings.get(languageCode, 'recipient_phone'),
              recipientPhoneNumber!,
            ),
            const SizedBox(height: 5),
            _buildFullWidthBox(
              AppStrings.get(languageCode, 'recipient_name_id'),
              recipientName!,
            ),
            const SizedBox(height: 5),
            _buildFullWidthBox(
              AppStrings.get(languageCode, 'recipient_id_num'),
              recipientId!,
            ),
            const SizedBox(height: 5),
          ] else ...[
            _buildFullWidthBox(
              AppStrings.get(languageCode, 'recipient_account'),
              recipientAccount,
              qrData: isFromQr ? _receiptQrPayload() : null,
            ),
            const SizedBox(height: 5),
          ],
          Row(
            children: [
              Expanded(
                child: _buildHalfWidthBox(
                  AppStrings.get(languageCode, 'amount_to_be_sent'),
                  '$amount $currencySymbol',
                  isBold: true,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildHalfWidthBox(
                  AppStrings.get(languageCode, 'reference'),
                  reference,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _buildHalfWidthBox(
                  AppStrings.get(languageCode, 'date_time'),
                  dateAndTimeString,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildHalfWidthBox(
                  AppStrings.get(languageCode, 'type'),
                  type,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _buildHalfWidthBox(
                  AppStrings.get(languageCode, 'purpose_of_send'),
                  purpose,
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildStatusBox(
                  AppStrings.get(languageCode, 'status'),
                  isSuccess
                      ? AppStrings.get(languageCode, 'succeeded')
                      : AppStrings.get(languageCode, 'failed'),
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
              AppStrings.get(languageCode, 'receipt_footer_msg'),
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

  Widget _buildFullWidthBox(String label, String value, {String? qrData}) {
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
              if (qrData != null && qrData.isNotEmpty) ...[
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
