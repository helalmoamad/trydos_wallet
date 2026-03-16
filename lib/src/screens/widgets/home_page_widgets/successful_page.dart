import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receipt_widget.dart';
import 'package:trydos_wallet/src/utils/ui_utils.dart';

class SuccessfulPage extends StatefulWidget {
  final String senderAccount;
  final String recipientAccount;
  final String amount;
  final String currencySymbol;
  final String reference;
  final String dateAndTimeString;
  final String type;
  final String purpose;
  final bool isSuccess;
  final VoidCallback onDone;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final bool isFromQr;

  // Optional Unregistered Phone fields
  final String? recipientPhoneNumber;
  final String? recipientName;
  final String? recipientId;

  const SuccessfulPage({
    super.key,
    required this.senderAccount,
    required this.recipientAccount,
    required this.amount,
    required this.currencySymbol,
    required this.reference,
    required this.dateAndTimeString,
    required this.type,
    required this.purpose,
    required this.onDone,
    required this.onDownload,
    required this.onShare,
    this.isSuccess = true,
    this.isFromQr = false,
    this.recipientPhoneNumber,
    this.recipientName,
    this.recipientId,
  });

  @override
  State<SuccessfulPage> createState() => _SuccessfulPageState();
}

class _SuccessfulPageState extends State<SuccessfulPage> {
  final GlobalKey _receiptKey = GlobalKey();
  bool _isDownloading = false;
  bool _isSharing = false;

  Future<Uint8List?> _captureReceipt() async {
    try {
      RenderRepaintBoundary boundary =
          _receiptKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing receipt: $e");
      return null;
    }
  }

  Future<void> _handleDownload() async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isDownloading = true);
    widget.onDownload(); // Trigger callback if needed

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final imageBytes = await _captureReceipt();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/receipt_${widget.reference}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        await Gal.putImage(imagePath);

        showMessage(
          // ignore: use_build_context_synchronously
          AppStrings.get(
            context.read<WalletBloc>().state.languageCode,
            'saved_successfully',
          ),
          // ignore: use_build_context_synchronously
          context: context,
          type: MessageType.success,
        );
      }
    } catch (e) {
      showMessage(
        // ignore: use_build_context_synchronously
        AppStrings.get(
          context.read<WalletBloc>().state.languageCode,
          'failed_to_save',
        ),
        // ignore: use_build_context_synchronously
        context: context,
        type: MessageType.error,
      );
    }

    if (mounted) {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShare() async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isSharing = true);
    widget.onShare(); // Trigger callback if needed

    try {
      final imageBytes = await _captureReceipt();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/receipt_${widget.reference}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [
            XFile(imagePath),
            // ignore: use_build_context_synchronously
          ],
          text:
              '${AppStrings.get(context.read<WalletBloc>().state.languageCode, 'receipt')} ${widget.reference}',
        );
      }
    } catch (e) {
      debugPrint('Error sharing receipt: $e');
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Hidden receipt for screen capture
            Positioned(
              left: -4000,
              top: -4000,
              child: RepaintBoundary(
                key: _receiptKey,
                child: Material(
                  type: MaterialType.transparency,
                  child: ReceiptWidget(
                    senderAccount: widget.senderAccount,
                    recipientAccount: widget.recipientAccount,
                    amount: widget.amount,
                    currencySymbol: widget.currencySymbol,
                    reference: widget.reference,
                    dateAndTimeString: widget.dateAndTimeString,
                    type: widget.type,
                    purpose: widget.purpose,
                    isSuccess: widget.isSuccess,
                    isFromQr: widget.isFromQr,
                    recipientPhoneNumber: widget.recipientPhoneNumber,
                    recipientName: widget.recipientName,
                    recipientId: widget.recipientId,
                    languageCode: state.languageCode,
                  ),
                ),
              ),
            ),

            // Visible UI
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 30),
              decoration: const BoxDecoration(
                color: Color(0xffF4FFFA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 10),
                  // Handle
                  Container(
                    width: 40,
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xffC4C2C2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    TrydosWalletAssets.sendSuccess,
                    height: 40,
                    package: TrydosWalletStyles.packageName,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.isSuccess
                        ? AppStrings.get(
                            state.languageCode,
                            'money_sent_success',
                          ).toUpperCase()
                        : AppStrings.get(
                            state.languageCode,
                            'transaction_failed',
                          ).toUpperCase(),
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SvgPicture.asset(
                    TrydosWalletAssets.realQr,
                    height: 120,
                    package: TrydosWalletStyles.packageName,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.reference,
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildInfoRow(
                    AppStrings.get(state.languageCode, 'sender_account'),
                    widget.senderAccount,
                  ),
                  const SizedBox(height: 15),
                  if (widget.recipientPhoneNumber != null &&
                      widget.recipientName != null &&
                      widget.recipientId != null) ...[
                    _buildInfoRow(
                      AppStrings.get(state.languageCode, 'recipient_phone'),
                      widget.recipientPhoneNumber!,
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      AppStrings.get(state.languageCode, 'recipient_name_id'),
                      widget.recipientName!,
                    ),
                    const SizedBox(height: 15),
                    _buildInfoRow(
                      AppStrings.get(state.languageCode, 'recipient_id_num'),
                      widget.recipientId!,
                    ),
                  ] else
                    _buildInfoRow(
                      AppStrings.get(state.languageCode, 'recipient_account'),
                      widget.recipientAccount,
                      isFromQr: widget.isFromQr,
                    ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          AppStrings.get(
                            state.languageCode,
                            'amount_to_be_sent',
                          ),
                          '${widget.amount} ${widget.currencySymbol}',
                          isBold: true,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoRow(
                          AppStrings.get(state.languageCode, 'reference'),
                          widget.reference,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          AppStrings.get(state.languageCode, 'date_time'),
                          widget.dateAndTimeString,
                        ),
                      ),
                      Expanded(
                        child: _buildInfoRow(
                          AppStrings.get(state.languageCode, 'type'),
                          widget.type,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoRow(
                          AppStrings.get(state.languageCode, 'purpose_of_send'),
                          widget.purpose,
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.get(state.languageCode, 'status'),
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: const Color(0xff8D8D8D),
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              children: [
                                Text(
                                  widget.isSuccess
                                      ? AppStrings.get(
                                          state.languageCode,
                                          'succeeded',
                                        )
                                      : AppStrings.get(
                                          state.languageCode,
                                          'failed',
                                        ),
                                  style: TrydosWalletStyles.bodyMedium.copyWith(
                                    color: const Color(0xff1D1D1D),
                                    fontSize: 11,
                                  ),
                                ),
                                if (widget.isSuccess) ...[
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  (widget.recipientPhoneNumber != null &&
                          widget.recipientName != null &&
                          widget.recipientId != null)
                      ? const SizedBox.shrink()
                      : SvgPicture.asset(
                          TrydosWalletAssets.trydos,
                          height: 25,
                          package: TrydosWalletStyles.packageName,
                        ),
                  (widget.recipientPhoneNumber != null &&
                          widget.recipientName != null &&
                          widget.recipientId != null)
                      ? const SizedBox.shrink()
                      : const SizedBox(height: 70),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionIcon(
                        TrydosWalletAssets.done,
                        AppStrings.get(state.languageCode, 'done'),
                        widget.onDone,
                      ),
                      _buildActionIcon(
                        TrydosWalletAssets.download,
                        AppStrings.get(state.languageCode, 'download'),
                        _handleDownload,
                        isLoading: _isDownloading,
                      ),
                      _buildActionIcon(
                        TrydosWalletAssets.share,
                        AppStrings.get(state.languageCode, 'share'),
                        _handleShare,
                        isLoading: _isSharing,
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isBold = false,
    bool isFromQr = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TrydosWalletStyles.bodyMedium.copyWith(
                color: const Color(0xff8D8D8D),
                fontSize: 11,
              ),
            ),
          ],
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
            Expanded(
              child: Text(
                value,
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(
    String asset,
    String label,
    VoidCallback onTap, {
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          if (isLoading && label != 'Done')
            const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            SvgPicture.asset(
              asset,
              height: 20,
              package: TrydosWalletStyles.packageName,
            ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
