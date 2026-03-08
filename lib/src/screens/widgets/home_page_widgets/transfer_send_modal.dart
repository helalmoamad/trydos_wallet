import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/trydos_wallet.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/successful_page.dart';

class TransferSendModal extends StatefulWidget {
  const TransferSendModal({super.key});

  @override
  State<TransferSendModal> createState() => _TransferSendModalState();
}

enum TransferState { input, sending, success }

class _TransferSendModalState extends State<TransferSendModal> {
  TransferState currentTransferState = TransferState.input;
  final List<String> purposes = [
    'Work/Partnership',
    'Service Fees',
    'Home Rent',
    'Office',
  ];
  String? selectedPurpose;
  final FocusNode recipientFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();
  final FocusNode noteFocus = FocusNode();
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool isRecipientVerified = false;
  String? recipientErrorMessage;
  bool isEditingRecipient = true;

  bool isAmountVerified = false;
  bool isEditingAmount = true;

  @override
  void initState() {
    super.initState();
    recipientFocus.addListener(() {
      if (!recipientFocus.hasFocus && isEditingRecipient) {
        _verifyRecipient();
      }
      setState(() {});
    });
    amountFocus.addListener(() {
      if (!amountFocus.hasFocus &&
          isEditingAmount &&
          amountController.text.isNotEmpty) {
        setState(() {
          isAmountVerified = true;
          isEditingAmount = false;
        });
      }
      setState(() {});
    });
    noteFocus.addListener(() => setState(() {}));
    recipientController.addListener(() => setState(() {}));
    amountController.addListener(() => setState(() {}));
    noteController.addListener(() => setState(() {}));
  }

  void _verifyRecipient() {
    final text = recipientController.text.replaceAll('-', '');
    if (text.isEmpty) return;

    setState(() {
      if (text.length >= 6 && text.startsWith('1')) {
        isRecipientVerified = true;
        recipientErrorMessage = null;
        isEditingRecipient = false;
        // Auto-focus amount field after verification
        Future.delayed(const Duration(milliseconds: 100), () {
          amountFocus.requestFocus();
        });
      } else {
        isRecipientVerified = false;
        recipientErrorMessage =
            'Incorrect Account Number. It Should Start With 1 And Consist Of 6 Digits';
        isEditingRecipient = true;
      }
    });
  }

  @override
  void dispose() {
    recipientFocus.dispose();
    amountFocus.dispose();
    noteFocus.dispose();
    recipientController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (currentTransferState == TransferState.success) {
      final state = context.read<WalletBloc>().state;
      final balance = state.balances[state.selectedAssetId ?? ''];
      final symbol = balance?.assetSymbol ?? r'$';
      final accountId = balance?.accountId ?? '----';
      final subtype = balance?.accountSubtype ?? 'MAIN';
      final senderAccount = '$subtype | $accountId | ${state.maskedName}';

      final now = DateTime.now();
      final months = [
        'Jan',
        'Feb',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'Sept',
        'Oct',
        'Nov',
        'Dec',
      ];
      final dateAndTimeString =
          '${now.day.toString().padLeft(2, '0')}.${months[now.month - 1]} | ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      return SuccessfulPage(
        senderAccount: senderAccount,
        recipientAccount: recipientController.text,
        amount: amountController.text,
        currencySymbol: symbol,
        reference:
            'TSCR${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        dateAndTimeString: dateAndTimeString,
        type: 'Transfer | Send',
        purpose: selectedPurpose ?? '',
        onDone: () => Navigator.pop(context),
        onDownload: () {},
        onShare: () {},
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 15),
          // Back Button & Icon
          Stack(
            alignment: Alignment.center,
            children: [
              Column(
                children: [
                  SvgPicture.asset(
                    TrydosWalletAssets.transferSend,
                    height: 40,
                    package: TrydosWalletStyles.packageName,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'TRANSFER | SEND',
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Sender Account Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xff3C3C3C),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: BlocBuilder<WalletBloc, WalletState>(
              buildWhen: (previous, current) =>
                  previous.selectedAssetId != current.selectedAssetId ||
                  previous.balances != current.balances,
              builder: (context, state) {
                final balance = state.balances[state.selectedAssetId ?? ''];
                final amountStr = balance != null
                    ? balance.available.toStringAsFixed(
                        balance.available.truncateToDouble() ==
                                balance.available
                            ? 0
                            : 2,
                      )
                    : '0';
                final symbol = balance?.assetSymbol ?? r'$';
                final assetName = balance?.asset?.name ?? '';
                final accountId = balance?.accountId ?? '----';
                final subtype = balance?.accountSubtype ?? 'MAIN';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          symbol,
                          style: TrydosWalletStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SvgPicture.asset(
                          TrydosWalletAssets.reload,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                          height: 20,
                          package: TrydosWalletStyles.packageName,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Sender Account',
                      style: TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$subtype | $accountId | ${state.maskedName}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          amountStr,
                          style: TrydosWalletStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            Text(
                              '$symbol | $assetName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(width: 15),
                            SvgPicture.asset(
                              TrydosWalletAssets.hide,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              height: 11,
                              package: TrydosWalletStyles.packageName,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'Send To',
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 15),

          // Recipient Input
          _buildInputField(
            label: isRecipientVerified
                ? 'Recipient Account Number'
                : 'Enter Recipient Account Or',
            inlineLabel: isRecipientVerified ? null : 'Phone Number',
            hint: 'Enter Recipient Account Number',
            focusNode: recipientFocus,
            controller: recipientController,
            isVerified: isRecipientVerified,
            errorMessage: recipientErrorMessage,
            showQuestionIcon: true,
            onEdit: currentTransferState == TransferState.sending
                ? null
                : () {
                    setState(() {
                      isEditingRecipient = true;
                      isRecipientVerified = false;
                      recipientErrorMessage = null;
                      Future.delayed(const Duration(milliseconds: 100), () {
                        recipientFocus.requestFocus();
                      });
                    });
                  },
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (recipientController.text.isEmpty) ...[
                  GestureDetector(
                    onTap: () async {
                      ClipboardData? data = await Clipboard.getData(
                        Clipboard.kTextPlain,
                      );
                      if (data != null && data.text != null) {
                        recipientController.text = data.text!;
                      }
                    },
                    child: Text(
                      'Paste',
                      style: TrydosWalletStyles.bodyMedium.copyWith(
                        color: const Color(0xff388CFF),
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SvgPicture.asset(
                    TrydosWalletAssets.qr,
                    height: 14,
                    package: TrydosWalletStyles.packageName,
                  ),
                ] else
                  GestureDetector(
                    onTap: () => recipientController.clear(),
                    child: SvgPicture.asset(
                      TrydosWalletAssets.close,
                      height: 18,
                      package: TrydosWalletStyles.packageName,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Amount Input
          AbsorbPointer(
            absorbing: !isRecipientVerified,
            child: BlocBuilder<WalletBloc, WalletState>(
              buildWhen: (previous, current) =>
                  previous.selectedAssetId != current.selectedAssetId ||
                  previous.balances != current.balances,
              builder: (context, state) {
                final balance = state.balances[state.selectedAssetId ?? ''];
                final symbol = balance?.assetSymbol ?? 'USD';

                return _buildInputField(
                  label: 'Amount To Be Sent',
                  hint: '000,000',
                  focusNode: amountFocus,
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  suffixFollowsText: true,
                  isVerified: isAmountVerified,
                  onEdit: currentTransferState == TransferState.sending
                      ? null
                      : () {
                          setState(() {
                            isEditingAmount = true;
                            isAmountVerified = false;
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                amountFocus.requestFocus();
                              },
                            );
                          });
                        },
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                    ThousandSeparatorFormatter(),
                  ],
                  suffix: Text(
                    ' $symbol',
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Purpose Section
          AbsorbPointer(
            absorbing: !(isRecipientVerified && isAmountVerified),
            child: _buildPurposeSection(),
          ),

          const SizedBox(height: 20),

          // Send Button
          InkWell(
            onTap:
                (isRecipientVerified &&
                    isAmountVerified &&
                    selectedPurpose != null &&
                    currentTransferState != TransferState.sending)
                ? () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      currentTransferState = TransferState.sending;
                    });
                    Future.delayed(const Duration(seconds: 3), () {
                      if (mounted) {
                        setState(() {
                          currentTransferState = TransferState.success;
                        });
                      }
                    });
                  }
                : null,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset(
                    !(isRecipientVerified &&
                            isAmountVerified &&
                            selectedPurpose != null)
                        ? TrydosWalletAssets.sendDisable
                        : TrydosWalletAssets.transferSend,
                    height: 35,
                    package: TrydosWalletStyles.packageName,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    currentTransferState == TransferState.sending
                        ? 'Sending...'
                        : 'Send',
                    style: TrydosWalletStyles.bodyLarge.copyWith(
                      color:
                          (isRecipientVerified &&
                              isAmountVerified &&
                              selectedPurpose != null)
                          ? const Color(0xff388CFF)
                          : const Color(0xff8D8D8D),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildPurposeSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xffD3D3D3)),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Purpose Of Money Send',
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: purposes.length,
              itemBuilder: (context, index) {
                return _buildChip(purposes[index]);
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              SvgPicture.asset(
                TrydosWalletAssets.edit,
                height: 14,
                package: TrydosWalletStyles.packageName,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: noteController,
                  focusNode: noteFocus,
                  decoration: InputDecoration(
                    hintText: 'Enter Your Note To See On Receiver Account',
                    hintStyle: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xffD3D3D3),
                      fontSize: 11,
                      height: 1.3,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 11,
                  ),
                ),
              ),
              if (noteController.text.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    noteController.clear();
                    setState(() {});
                  },
                  child: SvgPicture.asset(
                    TrydosWalletAssets.close,
                    height: 16,
                    package: TrydosWalletStyles.packageName,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    String? inlineLabel,
    required String hint,
    Widget? trailing,
    Widget? suffix,
    bool suffixFollowsText = false,
    bool isVerified = false,
    String? errorMessage,
    VoidCallback? onEdit,
    bool showQuestionIcon = false,
    bool enabled = true,
    required FocusNode focusNode,
    TextEditingController? controller,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    bool isFocused = focusNode.hasFocus;
    Color borderColor = isFocused
        ? const Color(0xff388CFF)
        : const Color(0xffD3D3D3);

    if (errorMessage != null) {
      borderColor = const Color(0xffFF5F61);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isVerified ? const Color(0xffF7F7F7) : Colors.white,
        border: isVerified ? null : Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isVerified && onEdit != null)
                GestureDetector(
                  onTap: onEdit,
                  child: const Text(
                    'Edit',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xff388CFF),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xff388CFF),
                    ),
                  ),
                ),
              if (isVerified && onEdit != null) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(fontSize: 11, color: const Color(0xff1D1D1D)),
              ),
              if (showQuestionIcon && inlineLabel == null) ...[
                const SizedBox(width: 4),
                SvgPicture.asset(
                  TrydosWalletAssets.question,
                  package: TrydosWalletStyles.packageName,
                ),
              ],
              if (inlineLabel != null) ...[
                const SizedBox(width: 10),
                Text(
                  inlineLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xffD3D3D3),
                    color: Color(0xffD3D3D3),
                  ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
                  TrydosWalletAssets.question,
                  package: TrydosWalletStyles.packageName,
                ),
              ],
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    if (suffixFollowsText && suffix != null && !isVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Opacity(
                              opacity: 0,
                              child: Text(
                                controller?.text.isEmpty ?? true
                                    ? hint
                                    : controller!.text,
                                style: TrydosWalletStyles.bodyMedium.copyWith(
                                  color: const Color(0xff1D1D1D),
                                  fontSize: (controller?.text.isEmpty ?? true)
                                      ? 13
                                      : 14,
                                  fontWeight: (controller?.text.isEmpty ?? true)
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            suffix,
                          ],
                        ),
                      ),
                    if (isVerified)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Row(
                          children: [
                            Text(
                              controller?.text ?? '',
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: const Color(0xff1D1D1D),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (suffixFollowsText && suffix != null) ...[
                              const SizedBox(width: 4),
                              suffix,
                            ],
                            if (!suffixFollowsText &&
                                label.contains('Recipient')) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'R***** B***** T*********** Y***** L******** S*****',
                                  style: TrydosWalletStyles.bodyMedium.copyWith(
                                    color: const Color(0xff1D1D1D),
                                    fontSize: 11,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      TextField(
                        controller: controller,
                        focusNode: focusNode,
                        enabled: enabled,
                        maxLines: 1,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        cursorColor: const Color(0xff388CFF),
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: hint,
                          suffix: suffixFollowsText ? null : suffix,
                          hintStyle: TrydosWalletStyles.bodyMedium.copyWith(
                            color: const Color(0xffD3D3D3),
                            fontSize: 13,
                            height: 1.3,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ),
              if (trailing != null && !isVerified) trailing,
            ],
          ),
          if (errorMessage != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xffFFF4F4),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                errorMessage,
                textAlign: TextAlign.center,
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 11,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChip(String label) {
    bool isSelected = selectedPurpose == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPurpose = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xffFCFCFC) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xff5D5C5D)
                : const Color(0xffD3D3D3),
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TrydosWalletStyles.bodyMedium.copyWith(
            color: const Color(0xff1D1D1D),
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove any existing commas
    String cleanedText = newValue.text.replaceAll(',', '');

    // Simple 000,000 formatting for 6 digits
    String formatted = '';
    if (cleanedText.length > 3) {
      formatted =
          '${cleanedText.substring(0, cleanedText.length - 3)},${cleanedText.substring(cleanedText.length - 3)}';
    } else {
      formatted = cleanedText;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
