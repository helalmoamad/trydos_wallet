import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_event.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

/// Digital wallet home page.
class SuccessVerification extends StatefulWidget {
  final Function()? onDone;
  const SuccessVerification({super.key, this.onDone});

  @override
  State<SuccessVerification> createState() => _SuccessVerificationState();
}

class _SuccessVerificationState extends State<SuccessVerification> {
  Timer? _fallbackTimer;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    // Confirm the submission actually landed on the backend before leaving.
    context.read<WalletBloc>().add(const WalletKycStatusRequested());
    // KYC just completed: immediately refresh the user record (user/me) so the
    // real verified name resolves here, and refresh the current session.
    context.read<WalletBloc>().add(
      const WalletUserProfileRefreshRequested(silent: true),
    );
    context.read<WalletBloc>().add(const WalletActiveSessionsRequested());
    // Fallback so we never hang on the success screen if status is slow/fails.
    _fallbackTimer = Timer(const Duration(seconds: 5), _close);
    // The status request may have already completed (it's also fired at
    // submit) — close shortly if so.
    _maybeCloseForStatus(context.read<WalletBloc>().state);
  }

  /// Once the status request resolves (success or failure), give the user a
  /// brief moment on the success screen, then close the KYC flow.
  void _maybeCloseForStatus(WalletState state) {
    if (_closed) return;
    final done =
        state.kycStatusRequestStatus == WalletStatus.success ||
        state.kycStatusRequestStatus == WalletStatus.failure;
    if (done) {
      Timer(const Duration(milliseconds: 1500), _close);
    }
  }

  void _close() {
    if (_closed || !mounted) return;
    _closed = true;
    widget.onDone?.call();
  }

  @override
  void dispose() {
    _fallbackTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listenWhen: (prev, curr) =>
          prev.kycStatusRequestStatus != curr.kycStatusRequestStatus,
      listener: (context, state) => _maybeCloseForStatus(state),
      builder: (context, state) {
        final lang = state.languageCode;
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 288.h),
            Text(
              AppStrings.get(lang, 'kyc_success_verification'),
              style: context.textTheme.titleLarge?.bq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 30.sp,
              ),
            ),
            SizedBox(height: 15.h),
            Text(
              AppStrings.get(lang, 'kyc_full_access'),
              style: context.textTheme.titleLarge?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 16.sp,
              ),
            ),
            SizedBox(height: 30.h),
            SvgPicture.asset(
              TrydosWalletAssets.successVerification,
              package: TrydosWalletStyles.packageName,
              height: 150.h,
            ),
            SizedBox(height: 20.h),
            Text(
              '${state.firstName} ${state.lastName}'.trim(),
              style: context.textTheme.titleLarge?.mq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.1,
                fontSize: 18.sp,
              ),
            ),
          ],
        );
      },
    );
  }
}
