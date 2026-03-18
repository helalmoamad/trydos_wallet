import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/receive_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/send_modal.dart';
import 'package:trydos_wallet/src/screens/widgets/widgets.dart';
import 'package:trydos_wallet/src/utils/qr_transfer_payload.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

enum QRScannerContentView { scanner, send, receive }

class QRScannerPage extends StatefulWidget {
  final bool fromQR;
  final bool? appairBack;

  const QRScannerPage({
    super.key,
    this.fromQR = false,
    this.appairBack = false,
  });

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [BarcodeFormat.qrCode],
  );

  bool _didReturnResult = false;
  QRScannerContentView _contentView = QRScannerContentView.scanner;

  void _showScannerRoot() {
    if (!mounted) return;
    setState(() {
      _contentView = QRScannerContentView.scanner;
    });
  }

  void _syncScannerBackButton() {
    if (_contentView != QRScannerContentView.scanner) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.appairBack == true) {
        setWalletModalBackButton(
          context,
          visible: true,
          onPressed: () => Navigator.pop(context),
        );
      } else {
        setWalletModalBackButton(context, visible: false);
      }
    });
  }

  Future<bool> _handleWillPop() async {
    if (!mounted) return false;
    if (_contentView != QRScannerContentView.scanner) {
      _showScannerRoot();
      return false;
    }

    if (widget.appairBack == true) {
      Navigator.pop(context);
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!mounted || _didReturnResult) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final raw = barcode.rawValue?.trim();
      if (raw == null || raw.isEmpty) {
        continue;
      }

      final parsed = QrTransferPayloadCodec.tryParse(raw);
      if (parsed == null || parsed.accountNumber.trim().isEmpty) {
        continue;
      }

      _didReturnResult = true;
      Navigator.pop(context, raw);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    _syncScannerBackButton();

    if (_contentView == QRScannerContentView.send) {
      return SendModal(onBack: _showScannerRoot, popOnBack: false);
    }

    if (_contentView == QRScannerContentView.receive) {
      return ReceiveModal(onBack: _showScannerRoot);
    }

    return WillPopScope(
      onWillPop: _handleWillPop,
      child: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.9,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 350,
                      width: 400,
                      margin: const EdgeInsets.symmetric(horizontal: 25),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Stack(
                          children: [
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: _onDetect,
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.0),
                                      Colors.black.withValues(alpha: 0.75),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SvgPicture.asset(
                                      TrydosWalletAssets.qr,
                                      height: 16,
                                      width: 16,
                                      colorFilter: const ColorFilter.mode(
                                        Color(0xffFCFCFC),
                                        BlendMode.srcIn,
                                      ),
                                      package: TrydosWalletStyles.packageName,
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      AppStrings.get(
                                        state.languageCode,
                                        'scan_qr_msg',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TrydosWalletStyles.bodyMedium
                                          .copyWith(
                                            color: const Color(0xffFCFCFC),
                                            fontSize: 11,
                                            height: 1.3,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 150),
                    if (!widget.fromQR) ...[
                      Text(
                        AppStrings.get(state.languageCode, 'or_choose'),
                        style: TrydosWalletStyles.bodyMedium.copyWith(
                          color: const Color(0xff1D1D1D),
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildOption(
                        icon: TrydosWalletAssets.send,
                        title: AppStrings.get(
                          state.languageCode,
                          'send_pay_cash',
                        ),
                        subtitle: AppStrings.get(
                          state.languageCode,
                          'send_money_pay',
                        ),
                        onTap: () {
                          setState(() {
                            _contentView = QRScannerContentView.send;
                          });
                        },
                      ),
                      const SizedBox(height: 5),
                      _buildOption(
                        icon: TrydosWalletAssets.receive,
                        title: AppStrings.get(
                          state.languageCode,
                          'receive_charge_request',
                        ),
                        subtitle: AppStrings.get(
                          state.languageCode,
                          'charge_wallet_msg',
                        ),
                        onTap: () {
                          setState(() {
                            _contentView = QRScannerContentView.receive;
                          });
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOption({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: const Color(0xffF8F8F8),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              height: 16,
              width: 16,
              package: TrydosWalletStyles.packageName,
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 13,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TrydosWalletStyles.bodyMedium.copyWith(
                      color: const Color(0xff1D1D1D),
                      fontSize: 11,
                      height: 1.3,
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
}
