import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
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

  static const PrettyQrDecoration _receiptQrDecoration = PrettyQrDecoration(
    shape: PrettyQrSmoothSymbol(color: Color(0xff1D1D1D), roundFactor: 0.32),
    quietZone: PrettyQrQuietZone.modules(1),
  );
  @override
  Widget build(BuildContext context) {
    final isRtl = languageCode == 'ar' || languageCode == 'ku';

    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        width: 1.sw, // Fixed width for consistent receipt aspect ratio
        color: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 100.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              TrydosWalletAssets.trydos,
              height: 25.h,
              package: TrydosWalletStyles.packageName,
            ),
            SizedBox(height: 10.h),
            Text(
              AppStrings.get(languageCode, 'receipt'),
              style: context.textTheme.bodyMedium?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                fontSize: 40.sp,
              ),
            ),
            SizedBox(height: 10.h),
            SizedBox.square(
              dimension: 70.w,
              child: PrettyQrView.data(
                data: _receiptQrPayload(),
                errorCorrectLevel: QrErrorCorrectLevel.M,
                decoration: _receiptQrDecoration,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              '${AppStrings.get(languageCode, 'id')} $reference',
              style: TrydosWalletStyles.bodyMedium.copyWith(
                color: const Color(0xff1D1D1D),
                fontSize: 11.sp,
              ),
            ),
            SizedBox(height: 20.h),

            _buildFullWidthBox(
              AppStrings.get(languageCode, 'sender_account'),
              senderAccount,
              context,
              forceLtrValue: true,
            ),
            SizedBox(height: 5.h),

            if (recipientPhoneNumber != null &&
                recipientName != null &&
                recipientId != null) ...[
              _buildFullWidthBox(
                AppStrings.get(languageCode, 'recipient_phone'),
                recipientPhoneNumber!,
                context,
              ),
              SizedBox(height: 5.h),
              _buildFullWidthBox(
                AppStrings.get(languageCode, 'recipient_name_id'),
                recipientName!,
                context,
              ),
              SizedBox(height: 5.h),
              _buildFullWidthBox(
                AppStrings.get(languageCode, 'recipient_id_num'),
                recipientId!,
                context,
              ),
              SizedBox(height: 5.h),
            ] else ...[
              _buildFullWidthBox(
                AppStrings.get(languageCode, 'recipient_account'),
                recipientAccount,
                context,
                qrData: isFromQr ? _receiptQrPayload() : null,
                forceLtrValue: true,
              ),
              SizedBox(height: 5.h),
            ],
            Row(
              children: [
                Expanded(
                  child: _buildHalfWidthBox(
                    AppStrings.get(languageCode, 'amount_to_be_sent'),
                    '$amount $currencySymbol',
                    context,
                    isBold: true,
                  ),
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: _buildHalfWidthBox(
                    AppStrings.get(languageCode, 'reference'),
                    reference,
                    context,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Row(
              children: [
                Expanded(
                  child: _buildHalfWidthBox(
                    AppStrings.get(languageCode, 'date_time'),
                    dateAndTimeString,
                    context,
                  ),
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: _buildHalfWidthBox(
                    AppStrings.get(languageCode, 'type'),
                    type,
                    context,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Row(
              children: [
                Expanded(
                  child: _buildHalfWidthBox(
                    AppStrings.get(languageCode, 'purpose_of_send'),
                    purpose,
                    context,
                  ),
                ),
                SizedBox(width: 5.w),
                Expanded(
                  child: _buildStatusBox(
                    AppStrings.get(languageCode, 'status'),
                    isSuccess
                        ? AppStrings.get(languageCode, 'succeeded')
                        : AppStrings.get(languageCode, 'failed'),
                    isSuccess,
                    context,
                  ),
                ),
              ],
            ),
            SizedBox(height: 5.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(12.r),
              decoration: BoxDecoration(
                color: const Color(0xffF9F9F9),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                AppStrings.get(languageCode, 'receipt_footer_msg'),
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff8D8D8D),
                  fontSize: 11.sp,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullWidthBox(
    String label,
    String value,
    BuildContext context, {
    String? qrData,
    bool forceLtrValue = false,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              if (qrData != null && qrData.isNotEmpty) ...[
                SvgPicture.asset(
                  TrydosWalletAssets.realQr,
                  height: 16.h,
                  width: 16.w,
                  package: TrydosWalletStyles.packageName,
                ),
                SizedBox(width: 8.w),
              ],
              Text(
                value,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 13.sp,
                ),
                textDirection: forceLtrValue ? TextDirection.ltr : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHalfWidthBox(
    String label,
    String value,
    BuildContext context, {
    bool isBold = false,
  }) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 5.h),
          Text(
            value,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 13.sp,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(
    String label,
    String value,
    bool isSuccessStatus,
    BuildContext context,
  ) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.rq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11.sp,
            ),
          ),
          SizedBox(height: 5.h),
          Row(
            children: [
              Text(
                value,
                style: context.textTheme.bodyMedium?.rq.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 13.sp,
                ),
              ),
              if (isSuccessStatus) ...[
                SizedBox(width: 12.w),
                SvgPicture.asset(
                  TrydosWalletAssets.successed,
                  height: 12.h,

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
