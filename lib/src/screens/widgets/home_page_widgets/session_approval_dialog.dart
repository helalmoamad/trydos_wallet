import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// Shows the push-triggered session/web login approval dialog.
void showSessionApprovalDialog(BuildContext context, WalletBloc bloc) {
  final request = bloc.state.sessionApprovalRequest;
  if (request == null) return;

  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => BlocProvider.value(
      value: bloc,
      child: _SessionApprovalDialog(request: request),
    ),
  ).then((_) {
    // Dismissed (tapped outside) while still pending → cancel so a stale
    // request doesn't reopen later.
    if (bloc.state.sessionApprovalRequest != null) {
      bloc.add(const WalletSessionApprovalResetRequested());
    }
  });
}

/// Which action the user actually tapped (drives the per-button spinner).
enum _ApprovalAction { none, approve, reject }

/// Approve/reject dialog for an incoming `session:approval_request`.
/// Mirrors the QR web-login confirmation design, with a countdown that closes
/// the dialog automatically when [SessionApprovalRequest.expiresAt] passes.
class _SessionApprovalDialog extends StatefulWidget {
  const _SessionApprovalDialog({required this.request});

  final SessionApprovalRequest request;

  @override
  State<_SessionApprovalDialog> createState() => _SessionApprovalDialogState();
}

class _SessionApprovalDialogState extends State<_SessionApprovalDialog> {
  _ApprovalAction _pending = _ApprovalAction.none;
  Timer? _ticker;
  Duration _remaining = Duration.zero;
  bool _hasExpiry = false;

  @override
  void initState() {
    super.initState();
    if (widget.request.expiresAt != null) {
      _hasExpiry = true;
      _tick();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final expiresAt = widget.request.expiresAt;
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _ticker?.cancel();
      // Expired → clear the request; the BlocConsumer listener closes us.
      if (mounted) {
        context.read<WalletBloc>().add(
          const WalletSessionApprovalResetRequested(),
        );
      }
      return;
    }
    if (mounted) setState(() => _remaining = remaining);
  }

  String _formatRemaining(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return BlocConsumer<WalletBloc, WalletState>(
      listenWhen: (previous, current) =>
          previous.sessionApprovalRequest != current.sessionApprovalRequest,
      listener: (context, state) {
        // Responded successfully, dismissed, or expired (request cleared)
        // → close the dialog. Snackbars/reset are handled by the page listener.
        if (state.sessionApprovalRequest == null &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final isLoading = state.sessionApprovalStatus == WalletStatus.loading;
        final approving = isLoading && _pending == _ApprovalAction.approve;
        final rejecting = isLoading && _pending == _ApprovalAction.reject;
        final languageCode = state.languageCode;

        return Directionality(
          textDirection: state.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            title: Text(
              AppStrings.get(
                languageCode,
                'session_approval_title',
              ).replaceFirst('{source}', request.displaySource),
              style: context.textTheme.bodyMedium?.bq.copyWith(
                fontSize: 16.sp,
                color: const Color(0xFF1D1D1D),
                height: 1.3,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.get(languageCode, 'session_approval_hint'),
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    fontSize: 13.sp,
                    color: const Color(0xFF4B5563),
                    height: 1.4,
                  ),
                ),
                if (_hasExpiry) ...[
                  SizedBox(height: 8.h),
                  Text(
                    AppStrings.get(
                      languageCode,
                      'session_approval_expires_in',
                    ).replaceFirst('{time}', _formatRemaining(_remaining)),
                    style: context.textTheme.bodyMedium?.bq.copyWith(
                      fontSize: 13.sp,
                      color: const Color(0xFF2E6AE8),
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
            actionsPadding: EdgeInsets.only(
              left: 16.w,
              right: 16.w,
              bottom: 12.h,
            ),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(() => _pending = _ApprovalAction.reject);
                              context.read<WalletBloc>().add(
                                WalletSessionApprovalResponded(
                                  requestId: request.requestId,
                                  approve: false,
                                ),
                              );
                            },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF2E6AE8)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: rejecting
                          ? SizedBox(
                              height: 18.h,
                              width: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2E6AE8),
                              ),
                            )
                          : Text(
                              AppStrings.get(
                                languageCode,
                                'linked_devices_scan_reject_button',
                              ),
                              style: context.textTheme.bodyMedium?.rq.copyWith(
                                color: const Color(0xFF2E6AE8),
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              setState(
                                () => _pending = _ApprovalAction.approve,
                              );
                              context.read<WalletBloc>().add(
                                WalletSessionApprovalResponded(
                                  requestId: request.requestId,
                                  approve: true,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E6AE8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                      ),
                      child: approving
                          ? SizedBox(
                              height: 18.h,
                              width: 18.h,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              AppStrings.get(
                                languageCode,
                                'linked_devices_scan_approve_button',
                              ),
                              style: context.textTheme.bodyMedium?.rq.copyWith(
                                color: Colors.white,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
