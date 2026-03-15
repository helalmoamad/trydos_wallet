import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:trydos_wallet/trydos_wallet.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/request_qr_modal.dart';
import 'package:trydos_wallet/src/utils/ui_utils.dart';

enum ReceiveModalView { main, request }

class ReceiveModal extends StatefulWidget {
  final ScrollController? scrollController;
  const ReceiveModal({super.key, this.scrollController});

  @override
  State<ReceiveModal> createState() => _ReceiveModalState();
}

class _ReceiveModalState extends State<ReceiveModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isMasked = false;
  bool _isDownloading = false;
  bool _isSharing = false;
  ReceiveModalView _currentView = ReceiveModalView.main;

  final String _accountName =
      'Ramaaz Bilişim Teknolojileri Yazılım Limited Sirketi';
  final String _maskedName = 'RBTYLS';
  final String _accountNumber = '100-708';

  void _handleCopy() {
    Clipboard.setData(ClipboardData(text: _accountNumber));
    showMessage(
      'Account number copied to clipboard',
      context: context,
      type: MessageType.success,
    );
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

  Future<void> _handleDownload() async {
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
        final imagePath = '${directory.path}/qr_card_$_accountNumber.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        await Gal.putImage(imagePath);

        // ignore: use_build_context_synchronously
        showMessage(
          'QR Card saved to gallery successfully!',
          // ignore: use_build_context_synchronously
          context: context,
          type: MessageType.success,
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      showMessage(
        'Failed to save QR Card.',
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

    try {
      final imageBytes = await _captureCard();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath = '${directory.path}/qr_card_$_accountNumber.png';
        final file = File(imagePath);
        await file.writeAsBytes(imageBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles([
          XFile(imagePath),
        ], text: 'My Receipt Account QR $_accountNumber');
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
    return Stack(
      children: [
        // Hidden card for screen capture
        Positioned(
          left: -4000,
          top: -4000,
          child: RepaintBoundary(
            key: _cardKey,
            child: _CleanQRCard(
              accountName: _isMasked ? _maskedName : _accountName,
              accountNumber: _accountNumber,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              controller: widget.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _currentView == ReceiveModalView.main
                      ? _buildReceiveView(context)
                      : RequestQRModal(
                          scrollController: widget.scrollController,
                          onBack: () {
                            setState(() {
                              _currentView = ReceiveModalView.main;
                            });
                          },
                        ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildReceiveView(BuildContext context) {
    return Column(
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
        const SizedBox(height: 16),
        // QR Code Area
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
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // Account Details
        _buildInfoSection(
          'Account Name',
          _isMasked ? _maskedName : _accountName,
          trailing: GestureDetector(
            onTap: () => setState(() => _isMasked = !_isMasked),
            child: SvgPicture.asset(
              TrydosWalletAssets.hide,
              package: TrydosWalletStyles.packageName,
              colorFilter: ColorFilter.mode(
                _isMasked ? const Color(0xff1D1D1D) : const Color(0xff8D8D8D),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        _buildInfoSection(
          'Account Number',
          '$_accountNumber  American Dollars',
        ),

        const Spacer(),
        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionButton(
              asset: TrydosWalletAssets.generate,
              label: 'Request',
              onTap: () {
                setState(() {
                  _currentView = ReceiveModalView.request;
                });
              },
            ),
            _buildActionButton(
              asset: TrydosWalletAssets.copy,
              label: 'Copy',
              onTap: _handleCopy,
            ),
            _buildActionButton(
              asset: TrydosWalletAssets.download,
              label: 'Download',
              onTap: _handleDownload,
              isLoading: _isDownloading,
            ),
            _buildActionButton(
              asset: TrydosWalletAssets.share,
              label: 'Share',
              onTap: _handleShare,
              isLoading: _isSharing,
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildInfoSection(String label, String value, {Widget? trailing}) {
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
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TrydosWalletStyles.bodyMedium.copyWith(
                    color: const Color(0xff1D1D1D),
                    fontSize: 12,
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String asset,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 70,
        child: Column(
          children: [
            isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xff404040),
                    ),
                  )
                : SvgPicture.asset(
                    asset,
                    height: 20,
                    // ignore: deprecated_member_use
                    color: Color(0xff404040),
                    package: TrydosWalletStyles.packageName,
                  ),

            const SizedBox(height: 8),
            Text(
              label,
              style: TrydosWalletStyles.bodySmall.copyWith(
                color: const Color(0xff404040),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CleanQRCard extends StatelessWidget {
  final String accountName;
  final String accountNumber;

  const _CleanQRCard({required this.accountName, required this.accountNumber});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: MediaQuery.of(context).size.width,
      padding: const EdgeInsets.all(30),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
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
              color: const Color(0xff404040),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoBox('Account Name', accountName),
          const SizedBox(height: 5),
          _buildInfoBox('Account Number', '$accountNumber  American Dollars'),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xffF9F9F9).withValues(alpha: 0.5),
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
            ),
          ),
        ],
      ),
    );
  }
}
