import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/merchant_payments_page.dart';
import 'package:trydos_wallet/src/screens/widgets/home_page_widgets/send_modal.dart';
import 'package:trydos_wallet/src/utils/payment_code.dart';
import 'package:trydos_wallet/src/utils/payment_link.dart';
import 'package:trydos_wallet/src/utils/ui_utils.dart';

/// Entry points for codes and links that arrive from outside the wallet UI.
///
/// Everything funnels into the same place a scan does — one resolve endpoint,
/// one confirmation screen — so a deep link, a pasted code and a scanned QR
/// cannot drift apart in behaviour.
///
/// The host app wires these to its own plumbing:
///
/// ```dart
/// // Universal link / app link / custom scheme
/// PaymentCodeLauncher.openLink(context, incomingUri);
///
/// // "Payment sent" push notification → the customer's receipts
/// PaymentCodeLauncher.openMerchantPayments(context);
/// ```
///
/// Registering the link paths in the native manifests is the host's job, and is
/// premature until the payment link page at `/r/v1/<requestCode>` actually
/// exists — see [PaymentLink].
abstract class PaymentCodeLauncher {
  PaymentCodeLauncher._();

  /// Opens the payment flow for [code].
  ///
  /// The code goes to the resolve endpoint untouched, and the flow branches on
  /// what comes back — a peer request fills the send screen, a merchant request
  /// opens the merchant confirmation.
  ///
  /// Completes when the customer closes the sheet. Completes with false
  /// immediately when [code] is not in a known namespace, in which case nothing
  /// is opened and no lookup is spent.
  static Future<bool> openCode(BuildContext context, String? code) async {
    final normalized = PaymentCode.normalize(code);
    if (!PaymentCode.isResolvable(normalized)) return false;

    final bloc = context.read<WalletBloc>();
    await showWalletModal(
      context: context,
      builder: (ctx, sc) => BlocProvider.value(
        value: bloc,
        child: SendModal(initialScanRaw: normalized),
      ),
    );
    return true;
  }

  /// Opens the payment flow for a link, if it carries a code we can resolve.
  static Future<bool> openLink(BuildContext context, Uri? uri) {
    return openCode(context, PaymentLink.extractCode(uri));
  }

  /// Opens the customer's merchant payments.
  ///
  /// This is where the payer's "Payment sent … Receipt RDB-R-…" notification
  /// should land. The notification text is already localized by the backend —
  /// deep-link it, do not rebuild it.
  static Future<void> openMerchantPayments(BuildContext context) {
    final bloc = context.read<WalletBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const MerchantPaymentsPage(),
        ),
      ),
    );
  }
}
