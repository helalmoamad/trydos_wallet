import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

enum RequestQRState { filling, generating, finalQR }

class RequestQRModal extends StatefulWidget {
  final ScrollController? scrollController;
  final VoidCallback? onBack;
  const RequestQRModal({super.key, this.scrollController, this.onBack});

  @override
  State<RequestQRModal> createState() => _RequestQRModalState();
}

class _RequestQRModalState extends State<RequestQRModal> {
  final GlobalKey _cardKey = GlobalKey();
  RequestQRState _state = RequestQRState.filling;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _referenceController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  String _selectedPurpose = 'work_partnership';
  String _selectedExpiry = 'always';

  bool _isDownloading = false;
  bool _isSharing = false;

  final String _accountName =
      'Ramaaz Bilişim Teknولojileri Yazılım Limited Sirketi';
  final String _maskedName = 'RBTYLS';
  final String _accountNumber = '100-708';
  bool _isNameMasked = false;

  final List<String> _purposes = [
    'work_partnership',
    'service_fees',
    'home_rent',
    'office_shop_rent',
  ];

  final List<String> _expiryOptions = [
    'always',
    'minutes_3',
    'minutes_15',
    'hour_1',
    'hours_24',
  ];

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_onFormChanged);
    _referenceController.addListener(_onFormChanged);
  }

  void _onFormChanged() {
    setState(() {});
  }

  bool get _isFormValid {
    return _amountController.text.isNotEmpty &&
        _referenceController.text.isNotEmpty &&
        _selectedPurpose.isNotEmpty;
  }

  void _generateRequest() async {
    if (!_isFormValid) return;

    setState(() => _state = RequestQRState.generating);

    await Future.delayed(const Duration(seconds: 5));

    if (mounted) {
      setState(() => _state = RequestQRState.finalQR);
    }
  }

  Future<Uint8List?> _captureCard() async {
    try {
      RenderRepaintBoundary boundary =
          _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Error capturing QR card: $e");
      return null;
    }
  }

  Future<void> _handleDownload(WalletState state) async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isDownloading = true);

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        await Gal.requestAccess();
      }

      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/request_qr_${_referenceController.text}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        await Gal.putImage(imagePath);

        // ignore: use_build_context_synchronously
        showMessage(
          AppStrings.get(state.languageCode, 'saved_successfully'),
          // ignore: use_build_context_synchronously
          context: context,
          type: MessageType.success,
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      showMessage(
        AppStrings.get(state.languageCode, 'failed_to_save'),
        // ignore: use_build_context_synchronously
        context: context,
        type: MessageType.error,
      );
    }

    if (mounted) {
      setState(() => _isDownloading = false);
    }
  }

  Future<void> _handleShare(WalletState state) async {
    if (_isDownloading || _isSharing) return;
    setState(() => _isSharing = true);

    try {
      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/request_qr_${_referenceController.text}.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(imagePath),
        ], text: AppStrings.get(state.languageCode, 'payment_request_for')
            .replaceAll('{amount}', _amountController.text)
            .replaceAll('{currency}', 'USD'));
      }
    } catch (e) {
      debugPrint('Error sharing QR card: $e');
    }

    if (mounted) {
      setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Stack(
              children: [
                // Hidden card for screen capture
                Positioned(
                  left: -4000,
                  top: -4000,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: Material(
                      type: MaterialType.transparency,
                      child: _CleanRequestQRCard(
                        accountName: _accountName,
                        accountNumber: _accountNumber,
                        amount: _amountController.text,
                        reference: _referenceController.text,
                        purpose: _selectedPurpose,
                        expiry: _selectedExpiry,
                        note: _noteController.text,
                        languageCode: state.languageCode,
                      ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
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
                    // Trydos Logo
                    SvgPicture.asset(
                      TrydosWalletAssets.trydos,
                      height: 30,
                      package: TrydosWalletStyles.packageName,
                    ),
                    const SizedBox(height: 20),

                    if (_state == RequestQRState.finalQR) ...[
                      // Final QR View
                      _buildFinalQRView(state),
                    ] else ...[
                      // Filling Form (including generating state)
                      _buildFormView(state),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormView(WalletState state) {
    return Column(
      children: [
        // Faded QR Placeholder
        Opacity(
          opacity: 0.1,
          child: SvgPicture.asset(
            TrydosWalletAssets.realQr,
            height: 250,
            package: TrydosWalletStyles.packageName,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          _accountNumber,
          style: TrydosWalletStyles.bodyMedium.copyWith(
            color: const Color(0xff404040),
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 20),
        // Account Details (Masked)
        _buildInfoBox(
          AppStrings.get(state.languageCode, 'account_name'),
          _isNameMasked ? _maskedName : _accountName,
          isMasked: true,
          onMaskToggle: () => setState(() => _isNameMasked = !_isNameMasked),
          isMaskedNow: _isNameMasked,
        ),
        const SizedBox(height: 5),
        _buildInfoBox(
          AppStrings.get(state.languageCode, 'account_number'),
          '$_accountNumber  ${AppStrings.get(state.languageCode, 'american_dollars')}',
        ),
        const SizedBox(height: 5),
        // Amount and Reference
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                label: AppStrings.get(state.languageCode, 'enter_amount'),
                controller: _amountController,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _buildTextField(
                label: AppStrings.get(state.languageCode, 'enter_reference'),
                controller: _referenceController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        // Combined Purpose and Note
        _buildPurposeAndNoteSection(state),
        const SizedBox(height: 5),
        // Expiry Selection
        _buildChipSelection(
          label: AppStrings.get(state.languageCode, 'valid_until'),
          options: _expiryOptions,
          selectedItem: _selectedExpiry,
          onSelected: (val) => setState(() => _selectedExpiry = val),
          state: state,
        ),

        const SizedBox(height: 25),
        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 20),
            _buildGenerateButton(state),
            _buildCancelButton(state),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildFinalQRView(WalletState state) {
    return Column(
      children: [
        // Vibrant QR Code
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              SvgPicture.asset(
                TrydosWalletAssets.realQr,
                height: 250,
                package: TrydosWalletStyles.packageName,
              ),
              const SizedBox(height: 5),
              Text(
                _accountNumber,
                style: TrydosWalletStyles.bodyMedium.copyWith(
                  color: const Color(0xff1D1D1D),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        // Account Details
        _buildSummaryBox(
          AppStrings.get(state.languageCode, 'account_name'),
          _accountName,
        ),
        const SizedBox(height: 5),
        _buildSummaryBox(
          AppStrings.get(state.languageCode, 'account_number'),
          '$_accountNumber  ${AppStrings.get(state.languageCode, 'american_dollars')}',
        ),
        const SizedBox(height: 5),
        // Transaction Details
        Row(
          children: [
            Expanded(
              child: _buildSummaryBox(
                AppStrings.get(state.languageCode, 'amount'),
                '${_amountController.text} USD',
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _buildSummaryBox(
                AppStrings.get(state.languageCode, 'id'),
                _referenceController.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: _buildSummaryBox(
                AppStrings.get(state.languageCode, 'purpose_of_request'),
                AppStrings.get(state.languageCode, _selectedPurpose),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _buildSummaryBox(
                AppStrings.get(state.languageCode, 'type'),
                AppStrings.get(state.languageCode, 'deposit_request'),
              ),
            ),
          ],
        ),

        // Expiry and Note Summary
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.get(state.languageCode, 'valid_until'),
                        style: TrydosWalletStyles.bodySmall.copyWith(
                          color: const Color(0xff8D8D8D),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _selectedExpiry == 'always'
                            ? AppStrings.get(state.languageCode, 'always')
                            : '${AppStrings.get(state.languageCode, _selectedExpiry)} ${AppStrings.get(state.languageCode, 'until')} 13:59 | 3 ${AppStrings.get(state.languageCode, 'mar')} 2026',
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  if (_noteController.text.isNotEmpty)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            AppStrings.get(state.languageCode, 'note'),
                            style: TrydosWalletStyles.bodySmall.copyWith(
                              color: const Color(0xff8D8D8D),
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _noteController.text,
                            style: TrydosWalletStyles.bodyMedium.copyWith(
                              color: const Color(0xff1D1D1D),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.end,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        (_selectedExpiry == 'always')
            ? const SizedBox.shrink()
            : Center(
                child: Text(
                  AppStrings.get(state.languageCode, 'cannot_use_after_expiry'),
                  style: TrydosWalletStyles.bodySmall.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 11,
                  ),
                ),
              ),

        const SizedBox(height: 40),
        // Action Buttons
        _buildActionRow(state),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? suffixText,
    TextInputType? keyboardType,
    IconData? prefixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffFFFFFF).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffD3D3D3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              if (prefixIcon != null) ...[
                Icon(prefixIcon, size: 16, color: const Color(0xffC4C2C2)),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 12,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffixText != null)
                Text(
                  suffixText,
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff8D8D8D),
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(
    String label,
    String value, {
    bool isMasked = false,
    VoidCallback? onMaskToggle,
    bool isMaskedNow = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xffFCFCFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11,
            ),
          ),

          SizedBox(
            height: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isMasked)
                  GestureDetector(
                    onTap: onMaskToggle,
                    child: SvgPicture.asset(
                      TrydosWalletAssets.hide,
                      package: TrydosWalletStyles.packageName,
                      colorFilter: ColorFilter.mode(
                        isMaskedNow
                            ? const Color(0xff1D1D1D)
                            : const Color(0xff8D8D8D),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Text(
            value,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeAndNoteSection(WalletState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD3D3D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.get(state.languageCode, 'select_purpose_request'),
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _purposes.map((option) {
                final isSelected = _selectedPurpose == option;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedPurpose = option);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xffFCFCFC)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xff388CFF)
                            : const Color(0xffD3D3D3),
                      ),
                    ),
                    child: Text(
                      AppStrings.get(state.languageCode, option),
                      style: TrydosWalletStyles.bodySmall.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: isSelected ? 12 : 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
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
                  controller: _noteController,
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 12,
                  ),
                  decoration: InputDecoration(
                    hintText: AppStrings.get(
                      state.languageCode,
                      'enter_note_receiver',
                    ),
                    hintStyle: TrydosWalletStyles.bodySmall.copyWith(
                      color: const Color(0xffD3D3D3),
                      fontSize: 12,
                    ),
                    isDense: true,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String label, String value, {bool isBold = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffFCFCFC),

        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipSelection({
    required String label,
    required List<String> options,
    required String selectedItem,
    required Function(String) onSelected,
    required WalletState state,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffD3D3D3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              label,
              style: TrydosWalletStyles.bodySmall.copyWith(
                color: const Color(0xff8D8D8D),
                fontSize: 11,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: options.map((option) {
                final isSelected = selectedItem == option;
                return GestureDetector(
                  onTap: () => onSelected(option),
                  child: Container(
                    margin: const EdgeInsets.only(right: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xffFCFCFC)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xff388CFF)
                            : const Color(0xffD3D3D3),
                      ),
                    ),
                    child: Text(
                      AppStrings.get(state.languageCode, option),
                      style: TrydosWalletStyles.bodySmall.copyWith(
                        color: const Color(0xff1D1D1D),
                        fontSize: isSelected ? 12 : 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_selectedExpiry != 'always') ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xffFFFEFA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  AppStrings.get(state.languageCode, 'cannot_use_after_expiry'),
                  style: TrydosWalletStyles.bodySmall.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenerateButton(WalletState state) {
    final isValid = _isFormValid;
    return GestureDetector(
      onTap: isValid ? _generateRequest : null,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              TrydosWalletAssets.generate,
              package: TrydosWalletStyles.packageName,
              colorFilter: ColorFilter.mode(
                isValid ? const Color(0xff388CFF) : const Color(0xff5D5C5D),
                BlendMode.srcIn,
              ),
            ),
          ),
          Text(
            _state == RequestQRState.generating
                ? AppStrings.get(state.languageCode, 'requesting')
                : AppStrings.get(state.languageCode, 'generate_request'),
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: isValid
                  ? const Color(0xff388CFF)
                  : const Color(0xff5D5C5D),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelButton(WalletState state) {
    if (_state == RequestQRState.generating) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        if (widget.onBack != null) {
          widget.onBack!();
        } else {
          Navigator.pop(context);
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            child: SvgPicture.asset(
              TrydosWalletAssets.cancel,
              package: TrydosWalletStyles.packageName,
            ),
          ),
          Text(
            AppStrings.get(state.languageCode, 'cancel'),
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: const Color(0xff5D5C5D),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(WalletState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionIcon(
          TrydosWalletAssets.copy,
          AppStrings.get(state.languageCode, 'copy'),
          () {
            Clipboard.setData(ClipboardData(text: _accountNumber));
            showMessage(
              AppStrings.get(state.languageCode, 'copy_clipboard'),
              context: context,
              type: MessageType.success,
            );
          },
        ),
        _buildActionIcon(
          TrydosWalletAssets.download,
          AppStrings.get(state.languageCode, 'download'),
          () => _handleDownload(state),
          isLoading: _isDownloading,
        ),
        _buildActionIcon(
          TrydosWalletAssets.share,
          AppStrings.get(state.languageCode, 'share'),
          () => _handleShare(state),
          isLoading: _isSharing,
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
          isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xff1D1D1D),
                  ),
                )
              : SvgPicture.asset(
                  asset,
                  height: 20,
                  package: TrydosWalletStyles.packageName,
                ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanRequestQRCard extends StatelessWidget {
  final String accountName;
  final String accountNumber;
  final String amount;
  final String reference;
  final String purpose;
  final String expiry;
  final String note;
  final String languageCode;

  const _CleanRequestQRCard({
    required this.accountName,
    required this.accountNumber,
    required this.amount,
    required this.reference,
    required this.purpose,
    required this.expiry,
    required this.note,
    required this.languageCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SvgPicture.asset(
            TrydosWalletAssets.trydos,
            height: 40,
            package: TrydosWalletStyles.packageName,
          ),
          const SizedBox(height: 20),
          SvgPicture.asset(
            TrydosWalletAssets.realQr,
            height: 300,
            package: TrydosWalletStyles.packageName,
          ),
          const SizedBox(height: 10),
          Text(
            accountNumber,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoBox(
            AppStrings.get(languageCode, 'account_name'),
            accountName,
          ),
          const SizedBox(height: 5),
          _buildInfoBox(
            AppStrings.get(languageCode, 'account_number'),
            '$accountNumber  ${AppStrings.get(languageCode, 'american_dollars')}',
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  AppStrings.get(languageCode, 'amount'),
                  '$amount USD',
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildInfoBox(
                  AppStrings.get(languageCode, 'id'),
                  reference,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: _buildInfoBox(
                  AppStrings.get(languageCode, 'purpose_of_request'),
                  AppStrings.get(languageCode, purpose),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: _buildInfoBox(
                  AppStrings.get(languageCode, 'type'),
                  AppStrings.get(languageCode, 'deposit_request'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          _buildInfoBox(
            AppStrings.get(languageCode, 'valid_until'),
            expiry == 'always'
                ? AppStrings.get(languageCode, 'always')
                : '${AppStrings.get(languageCode, expiry)} ${AppStrings.get(languageCode, 'until')} 13:59 | 3 ${AppStrings.get(languageCode, 'mar')} 2026',
          ),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 5),
            _buildInfoBox(AppStrings.get(languageCode, 'note'), note),
          ],
          const SizedBox(height: 5),
          Text(
            AppStrings.get(languageCode, 'cannot_use_after_expiry'),
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TrydosWalletStyles.bodySmall.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TrydosWalletStyles.bodyMedium.copyWith(
              color: const Color(0xff1D1D1D),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
