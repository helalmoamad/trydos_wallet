import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/trydos_wallet.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/successful_page.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/qr_scanner_page.dart';

class TransferSendModal extends StatefulWidget {
  final ScrollController? scrollController;
  const TransferSendModal({super.key, this.scrollController});

  @override
  State<TransferSendModal> createState() => _TransferSendModalState();
}

enum TransferState { input, sending, success }

enum RecipientInputType { account, phone }

class _TransferSendModalState extends State<TransferSendModal> {
  TransferState currentTransferState = TransferState.input;
  RecipientInputType currentInputType = RecipientInputType.account;
  final List<String> purposes = [
    'work_partnership',
    'service_fees',
    'home_rent',
    'office',
  ];
  String? selectedPurpose;
  final FocusNode recipientFocus = FocusNode();
  final FocusNode nameFocus = FocusNode();
  final FocusNode idFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();
  final FocusNode noteFocus = FocusNode();
  final TextEditingController recipientController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController idController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  bool isRecipientVerified = false;
  String? recipientErrorMessage;
  String? nameErrorMessage;
  String? idErrorMessage;
  String? amountErrorMessage;
  bool isEditingRecipient = true;
  String? _phoneForEdit;
  bool?
  isPhoneRegistered; // null=not checked, true=registered, false=not registered

  bool isNameVerified = false;
  bool isEditingName = true;

  bool isIdVerified = false;
  bool isEditingId = true;

  bool isAmountVerified = false;
  bool isEditingAmount = true;

  bool isFromQr = false;
  bool isRequestFlow = false;
  DateTime? expiryTime;
  String? referenceId;
  String? requestType;
  String? maskedAccountName;
  String? qrPurpose;

  bool get isExpired =>
      isRequestFlow &&
      expiryTime != null &&
      DateTime.now().isBefore(expiryTime!);

  @override
  void initState() {
    super.initState();
    recipientFocus.addListener(() {
      if (!recipientFocus.hasFocus && isEditingRecipient) {
        _verifyRecipient();
      }
      setState(() {});
    });
    nameFocus.addListener(() {
      if (!nameFocus.hasFocus &&
          isEditingName &&
          nameController.text.isNotEmpty) {
        setState(() {
          isNameVerified = true;
          isEditingName = false;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          idFocus.requestFocus();
        });
      }
      setState(() {});
    });
    idFocus.addListener(() {
      if (!idFocus.hasFocus && isEditingId && idController.text.isNotEmpty) {
        setState(() {
          isIdVerified = true;
          isEditingId = false;
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          amountFocus.requestFocus();
        });
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
    nameController.addListener(() => setState(() {}));
    idController.addListener(() => setState(() {}));
    amountController.addListener(() => setState(() {}));
    noteController.addListener(() => setState(() {}));
  }

  void _verifyRecipient() {
    final text = recipientController.text
        .replaceAll('-', '')
        .replaceAll(' ', '');
    final lang = context.read<WalletBloc>().state.languageCode;
    // If we're verifying an existing mocked account, don't re-verify
    if (text == '100708') {
      return;
    }
    if (text.isEmpty) return;

    setState(() {
      if (currentInputType == RecipientInputType.account) {
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
          recipientErrorMessage = AppStrings.get(lang, 'incorrect_account_msg');
          isEditingRecipient = true;
        }
      } else {
        // Phone Number processing
        final phoneText = text.replaceAll('+', '');
        if (phoneText.length >= 7) {
          isRecipientVerified = true;
          recipientErrorMessage = null;
          isEditingRecipient = false;
          _phoneForEdit = recipientController.text;

          // Mock lookup: if phone starts with '90' → registered (has account)
          final registered = phoneText.startsWith('90');
          isPhoneRegistered = registered;

          if (registered) {
            // Show account number — same as method 2
            recipientController.text = '100-708';
            Future.delayed(const Duration(milliseconds: 100), () {
              amountFocus.requestFocus();
            });
          } else {
            // Unregistered → ask for name and ID
            Future.delayed(const Duration(milliseconds: 100), () {
              nameFocus.requestFocus();
            });
          }
        } else {
          isRecipientVerified = false;
          recipientErrorMessage = AppStrings.get(lang, 'phone_min_digits_msg');
          isEditingRecipient = true;
        }
      }
    });
  }

  @override
  void dispose() {
    recipientFocus.dispose();
    nameFocus.dispose();
    idFocus.dispose();
    amountFocus.dispose();
    noteFocus.dispose();
    recipientController.dispose();
    nameController.dispose();
    idController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  static const List<String> months = [
    'jan',
    'feb',
    'mar',
    'apr',
    'may',
    'jun',
    'jul',
    'aug',
    'sep',
    'oct',
    'nov',
    'dec',
  ];

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
      final dateAndTimeString =
          '${now.day.toString().padLeft(2, '0')}.${AppStrings.get(state.languageCode, months[now.month - 1])} | ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      return SingleChildScrollView(
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        child: SuccessfulPage(
          senderAccount: senderAccount,
          recipientAccount: recipientController.text,
          amount: amountController.text,
          currencySymbol: symbol,
          reference:
              'TSCR${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          dateAndTimeString: dateAndTimeString,
          type: AppStrings.get(state.languageCode, 'transfer_send'),
          purpose: AppStrings.get(
            state.languageCode,
            qrPurpose ?? selectedPurpose ?? 'work_partnership',
          ),
          onDone: () => Navigator.pop(context),
          onDownload: () {},
          onShare: () {},
          isFromQr: isFromQr,
          // Only pass phone fields when phone is unregistered
          recipientPhoneNumber:
              (currentInputType == RecipientInputType.phone &&
                  isPhoneRegistered == false)
              ? '+ ${_phoneForEdit ?? recipientController.text}'
              : null,
          recipientName:
              (currentInputType == RecipientInputType.phone &&
                  isPhoneRegistered == false)
              ? nameController.text
              : null,
          recipientId:
              (currentInputType == RecipientInputType.phone &&
                  isPhoneRegistered == false)
              ? idController.text
              : null,
        ),
      );
    }

    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return SingleChildScrollView(
          controller: widget.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 15),
                // Back Button & Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          width: double.infinity,
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xffC4C2C2),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SvgPicture.asset(
                          TrydosWalletAssets.transferSend,
                          height: 40,
                          package: TrydosWalletStyles.packageName,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              AppStrings.get(
                                state.languageCode,
                                'transfer_send',
                              ).toUpperCase(),
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: const Color(0xff1D1D1D),
                                fontSize: 13,
                              ),
                            ),
                            isRequestFlow
                                ? Text(
                                    ' ${AppStrings.get(state.languageCode, 'request').toUpperCase()}',
                                    style: TrydosWalletStyles.bodyMedium
                                        .copyWith(
                                          color: const Color(0xff1D1D1D),
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  )
                                : const SizedBox.shrink(),
                          ],
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBalanceSection(state),
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
                      Text(
                        AppStrings.get(state.languageCode, 'sender_account'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        _getSenderAccountDisplay(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _buildAmountRow(state),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppStrings.get(state.languageCode, 'send_to'),
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                _buildRecipientInputSection(state),
                const SizedBox(height: 5),

                if (currentInputType == RecipientInputType.phone &&
                    isPhoneRegistered == false &&
                    isRecipientVerified) ...[
                  _buildInputField(
                    state: state,
                    label: AppStrings.get(
                      state.languageCode,
                      'recipient_name_id',
                    ),
                    controller: nameController,
                    hint: AppStrings.get(
                      state.languageCode,
                      'recipient_name_hint',
                    ),
                    focusNode: nameFocus,
                    isVerified: isNameVerified,
                    errorMessage: nameErrorMessage,
                    onEdit: () => setState(() => isNameVerified = false),
                  ),
                  const SizedBox(height: 5),
                  _buildInputField(
                    state: state,
                    label: AppStrings.get(
                      state.languageCode,
                      'recipient_id_num',
                    ),
                    controller: idController,
                    hint: AppStrings.get(
                      state.languageCode,
                      'recipient_id_hint',
                    ),
                    focusNode: idFocus,
                    isVerified: isIdVerified,
                    errorMessage: idErrorMessage,
                    onEdit: () => setState(() => isIdVerified = false),
                  ),
                  const SizedBox(height: 5),
                ],

                _buildInputField(
                  state: state,
                  label: AppStrings.get(
                    state.languageCode,
                    'amount_to_be_sent',
                  ),
                  controller: amountController,
                  hint: '0',
                  focusNode: amountFocus,
                  isVerified: isAmountVerified,
                  isFromQr: isFromQr,
                  errorMessage: amountErrorMessage,
                  keyboardType: TextInputType.number,
                  onEdit: isRequestFlow
                      ? null
                      : () => setState(() => isAmountVerified = false),
                  suffixFollowsText: true,
                  suffix: Text(
                    ' ${state.balances[state.selectedAssetId ?? '']?.assetSymbol ?? r'$'}',
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 5),

                // Purpose Section
                if (!isRequestFlow) ...[
                  AbsorbPointer(
                    absorbing: currentInputType == RecipientInputType.phone
                        ? (isPhoneRegistered == false
                              ? !(isIdVerified && isAmountVerified)
                              : !(isRecipientVerified && isAmountVerified))
                        : !(isRecipientVerified && isAmountVerified),
                    child: _buildPurposeSection(state),
                  ),
                ],

                if (isRequestFlow) ...[
                  _buildInputField(
                    state: state,
                    label: AppStrings.get(state.languageCode, 'reference_id'),
                    controller: TextEditingController(text: referenceId),
                    hint: '',
                    focusNode: FocusNode(),
                    isVerified: true,
                    showMaskedName: false,
                    enabled: false,
                  ),
                  const SizedBox(height: 5),
                  _buildInputField(
                    state: state,
                    label: AppStrings.get(
                      state.languageCode,
                      'purpose_of_request',
                    ),
                    controller: TextEditingController(
                      text: AppStrings.get(
                        state.languageCode,
                        qrPurpose ?? 'work_partnership',
                      ),
                    ),
                    hint: '',
                    focusNode: FocusNode(),
                    isVerified: true,
                    showMaskedName: false,
                    enabled: false,
                  ),
                  const SizedBox(height: 5),
                  _buildInputField(
                    state: state,
                    label: AppStrings.get(state.languageCode, 'type'),
                    controller: TextEditingController(text: requestType),
                    hint: '',
                    focusNode: FocusNode(),
                    isVerified: true,
                    showMaskedName: false,
                    enabled: false,
                  ),
                  const SizedBox(height: 5),
                  _buildInputField(
                    state: state,
                    label: AppStrings.get(state.languageCode, 'valid_until'),
                    controller: TextEditingController(
                      text: expiryTime == null
                          ? '-'
                          : '${expiryTime!.difference(DateTime.now()).inMinutes < 0 ? 0 : expiryTime!.difference(DateTime.now()).inMinutes}${AppStrings.get(state.languageCode, 'minutes_until')}${expiryTime!.hour.toString().padLeft(2, '0')}:${expiryTime!.minute.toString().padLeft(2, '0')} | ${expiryTime!.day} ${AppStrings.get(state.languageCode, months[expiryTime!.month - 1])} ${expiryTime!.year}',
                    ),
                    hint: '',
                    focusNode: FocusNode(),
                    isVerified: true,
                    showMaskedName: false,
                    enabled: false,
                    showTimeNote: true,
                  ),
                ],

                isRequestFlow
                    ? const SizedBox(height: 10)
                    : const SizedBox(height: 30),

                if (isRequestFlow && isExpired)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xffFF5F60),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      AppStrings.get(state.languageCode, 'expired_code'),
                      style: TrydosWalletStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  _buildSendButton(state),

                const SizedBox(height: 125),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(WalletState state) {
    return Builder(
      builder: (context) {
        final isReadyToSend =
            (isRequestFlow || selectedPurpose != null) &&
            isAmountVerified &&
            (currentInputType == RecipientInputType.account
                ? isRecipientVerified
                : (isPhoneRegistered == true
                      ? isRecipientVerified
                      : (isNameVerified && isIdVerified)));

        return InkWell(
          onTap: isReadyToSend && currentTransferState != TransferState.sending
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
                  isRequestFlow
                      ? (!isReadyToSend
                            ? TrydosWalletAssets.sendDisable
                            : TrydosWalletAssets.transferSend)
                      : (!isReadyToSend
                            ? TrydosWalletAssets.sendDisable
                            : TrydosWalletAssets.transferSend),
                  height: 25,
                  package: TrydosWalletStyles.packageName,
                ),
                const SizedBox(height: 5),
                Text(
                  currentTransferState == TransferState.sending
                      ? AppStrings.get(state.languageCode, 'sending')
                      : (isRequestFlow
                            ? AppStrings.get(
                                state.languageCode,
                                'send_deposits',
                              )
                            : AppStrings.get(state.languageCode, 'send_label')),
                  style: TrydosWalletStyles.bodyLarge.copyWith(
                    color: isReadyToSend
                        ? const Color(0xff388CFF)
                        : const Color(0xff8D8D8D),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPurposeSection(WalletState state) {
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
            AppStrings.get(state.languageCode, 'select_purpose_send'),
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
                return _buildChip(purposes[index], state);
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
                    hintText: AppStrings.get(
                      state.languageCode,
                      'enter_note_receiver',
                    ),
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
    Key? key,
    required WalletState state,
    required String label,
    String? inlineLabel,
    Widget? customTopLabelWidget,
    required String hint,
    String? prefixText,
    Widget? trailing,
    Widget? suffix,
    bool suffixFollowsText = false,
    bool isVerified = false,
    bool isFromQr = false,
    bool isExpired = false,
    bool showTimeNote = false,
    String? errorMessage,
    VoidCallback? onEdit,
    bool showQuestionIcon = false,
    bool showMaskedName = false,
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
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isVerified
            ? isRequestFlow
                  ? isExpired
                        ? const Color(0xffFCFCFC)
                        : const Color(0xffFCFCFC)
                  : const Color(0xffF7F7F7)
            : Colors.white,
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
                  child: Text(
                    AppStrings.get(state.languageCode, 'edit'),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xff388CFF),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xff388CFF),
                    ),
                  ),
                ),
              if (isVerified && onEdit != null) const SizedBox(width: 4),
              if (customTopLabelWidget != null && !isVerified)
                Expanded(child: customTopLabelWidget)
              else ...[
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isRequestFlow
                        ? const Color(0xff8D8D8D)
                        : const Color(0xff1D1D1D),
                  ),
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
                  const Text(
                    'inline label',
                    style: TextStyle(
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
                            if (isFromQr) ...[
                              SvgPicture.asset(
                                TrydosWalletAssets.realQr,
                                height: 16,
                                width: 16,
                                package: TrydosWalletStyles.packageName,
                              ),
                              const SizedBox(width: 10),
                            ],
                            Text(
                              controller?.text ?? '',
                              style: TrydosWalletStyles.bodyMedium.copyWith(
                                color: const Color(0xff1D1D1D),
                                fontSize: 14,
                                fontWeight:
                                    ((int.tryParse(
                                              controller!.text.replaceAll(
                                                ',',
                                                '',
                                              ),
                                            ) ??
                                            0) >
                                        0)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            if (suffixFollowsText && suffix != null) ...[
                              const SizedBox(width: 4),
                              suffix,
                            ],
                            if (!suffixFollowsText && showMaskedName) ...[
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isRequestFlow
                                      ? (maskedAccountName ?? '')
                                      : 'R***** B***** T*********** Y***** L******** S*****',
                                  style: TrydosWalletStyles.bodyMedium.copyWith(
                                    color: const Color(0xff8D8D8D),
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                  overflow: TextOverflow.visible,
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
                          prefixText: prefixText,
                          prefixStyle: TrydosWalletStyles.bodyMedium.copyWith(
                            color: const Color(0xff1D1D1D),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
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
          if (isRequestFlow && !isExpired && showTimeNote)
            const SizedBox(height: 5),
          if (isRequestFlow && !isExpired && showTimeNote)
            Center(
              child: Text(
                AppStrings.get(state.languageCode, 'cannot_use_after_expiry'),
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

  Widget _buildBalanceSection(WalletState state) {
    final balance = state.balances[state.selectedAssetId ?? ''];
    final symbol = balance?.assetSymbol ?? r'$';
    return Text(
      symbol,
      style: TrydosWalletStyles.bodyMedium.copyWith(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getSenderAccountDisplay(WalletState state) {
    final balance = state.balances[state.selectedAssetId ?? ''];
    final accountId = balance?.accountId ?? '----';
    final subtypeRaw = balance?.accountSubtype ?? 'MAIN';
    final subtype = subtypeRaw.toUpperCase() == 'MAIN'
        ? AppStrings.get(state.languageCode, 'main_sub_account')
        : subtypeRaw;
    return '$subtype | $accountId | ${state.maskedName}';
  }

  Widget _buildAmountRow(WalletState state) {
    final balance = state.balances[state.selectedAssetId ?? ''];
    final amountStr = balance != null
        ? balance.available.toStringAsFixed(
            balance.available.truncateToDouble() == balance.available ? 0 : 2,
          )
        : '0';
    final symbol = balance?.assetSymbol ?? r'$';
    final assetName = balance?.asset?.name ?? '';

    return Row(
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
              style: const TextStyle(color: Colors.white, fontSize: 9),
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
    );
  }

  Widget _buildRecipientInputSection(WalletState state) {
    return _buildInputField(
      state: state,
      customTopLabelWidget: Row(
        children: [
          Text(
            AppStrings.get(state.languageCode, 'enter'),
            style: const TextStyle(fontSize: 10, color: Color(0xffD3D3D3)),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => currentInputType = RecipientInputType.account),
            child: Text(
              AppStrings.get(state.languageCode, 'recipient_account'),
              style: TextStyle(
                fontSize: 10,
                decoration: TextDecoration.underline,
                decorationColor: currentInputType == RecipientInputType.account
                    ? const Color(0xff388CFF)
                    : const Color(0xffD3D3D3),
                color: currentInputType == RecipientInputType.account
                    ? const Color(0xff388CFF)
                    : const Color(0xffD3D3D3),
              ),
            ),
          ),
          Text(
            AppStrings.get(state.languageCode, 'or'),
            style: const TextStyle(fontSize: 10, color: Color(0xffD3D3D3)),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => currentInputType = RecipientInputType.phone),
            child: Text(
              AppStrings.get(state.languageCode, 'recipient_phone'),
              style: TextStyle(
                fontSize: 10,
                decoration: TextDecoration.underline,
                decorationColor: currentInputType == RecipientInputType.phone
                    ? const Color(0xff388CFF)
                    : const Color(0xffD3D3D3),
                color: currentInputType == RecipientInputType.phone
                    ? const Color(0xff388CFF)
                    : const Color(0xffD3D3D3),
              ),
            ),
          ),
        ],
      ),
      label: currentInputType == RecipientInputType.account
          ? AppStrings.get(state.languageCode, 'recipient_account_num')
          : AppStrings.get(state.languageCode, 'recipient_phone_num'),
      controller: recipientController,
      hint: currentInputType == RecipientInputType.account
          ? AppStrings.get(state.languageCode, 'enter_recipient_acc')
          : AppStrings.get(state.languageCode, 'enter_recipient_phone'),
      focusNode: recipientFocus,
      isVerified: isRecipientVerified,
      isFromQr: isFromQr,
      showMaskedName: true,
      errorMessage: recipientErrorMessage,
      keyboardType: currentInputType == RecipientInputType.phone
          ? TextInputType.phone
          : TextInputType.number,
      onEdit: isFromQr
          ? null
          : () => setState(() => isRecipientVerified = false),
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
                AppStrings.get(state.languageCode, 'paste'),
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xff388CFF),
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xff388CFF),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () async {
                final result = await showWalletModal<String>(
                  context: context,
                  builder: (context, sc) => const QRScannerPage(),
                );
                if (result != null) {
                  setState(() {
                    isFromQr = true;
                    try {
                      final data = jsonDecode(result);
                      if (data is Map<String, dynamic> &&
                          data.containsKey('expiry_time') &&
                          data.containsKey('amount')) {
                        isRequestFlow = true;
                        currentInputType = RecipientInputType.account;
                        recipientController.text =
                            data['account_id']?.toString() ?? '';
                        amountController.text =
                            data['amount']?.toString() ?? '';
                        referenceId = data['reference']?.toString();
                        qrPurpose = data['purpose']?.toString();
                        requestType = data['type']?.toString();
                        maskedAccountName = data['account_name']?.toString();
                        if (data['expiry_time'] != null) {
                          expiryTime = DateTime.parse(data['expiry_time']);
                        }
                        isRecipientVerified = true;
                        isAmountVerified = true;
                        isEditingRecipient = false;
                        isEditingAmount = false;
                      } else {
                        isRequestFlow = false;
                        currentInputType = RecipientInputType.account;
                        recipientController.text = result;
                        _verifyRecipient();
                      }
                    } catch (e) {
                      isRequestFlow = false;
                      currentInputType = RecipientInputType.account;
                      recipientController.text = result;
                      _verifyRecipient();
                    }
                  });
                }
              },
              child: SvgPicture.asset(
                TrydosWalletAssets.qr,
                height: 14,
                package: TrydosWalletStyles.packageName,
              ),
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
    );
  }

  Widget _buildChip(String key, WalletState state) {
    final isSelected = selectedPurpose == key;
    return GestureDetector(
      onTap: () => setState(() => selectedPurpose = key),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff388CFF) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xff388CFF)
                : const Color(0xffD3D3D3),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          AppStrings.get(state.languageCode, key),
          style: TrydosWalletStyles.bodyMedium.copyWith(
            color: isSelected ? Colors.white : const Color(0xff8D8D8D),
            fontSize: 11,
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
