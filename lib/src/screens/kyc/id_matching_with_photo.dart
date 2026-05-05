import 'dart:async';
import 'dart:io';

//import 'package:dotted_border/dotted_border.dart';
import 'package:dotted_border/dotted_border.dart';
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
class IdMatchingWithPhoto extends StatefulWidget {
  final Function()? onTapNextPage;

  /// Called when the face match fails with a business error (FACE_MISMATCH, FACE_NOT_DETECTED).
  /// The screen navigates back to the beginning of KYC in this case.
  final Function(String errorMessage)? onMatchError;
  final String? selfiePath;
  final String? frontIdPath;
  const IdMatchingWithPhoto({
    super.key,
    this.onTapNextPage,
    this.onMatchError,
    this.selfiePath,
    this.frontIdPath,
  });

  @override
  State<IdMatchingWithPhoto> createState() => _IdMatchingWithPhotoState();
}

class _IdMatchingWithPhotoState extends State<IdMatchingWithPhoto> {
  Timer? _blinkTimer;
  Timer? _nextTimer;

  bool _isMatched = false;
  bool _showPersonStrong = true;
  bool _requestSent = false;
  WalletStatus _lastCompareFaceStatus = WalletStatus.initial;

  @override
  void initState() {
    super.initState();
    _startBlinking();
    // Send compare-face request on first frame using BLoC state data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<WalletBloc>().state;
      final selfie = state.selfieImageData ?? '';
      final idFace = state.kycIdFaceImageData ?? '';
      if (selfie.isNotEmpty && idFace.isNotEmpty && !_requestSent) {
        _requestSent = true;
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          context.read<WalletBloc>().add(
            WalletKycCompareFaceRequested(
              selfieImageData: selfie,
              idFaceImageData: idFace,
            ),
          );
        });
      }
    });
  }

  void _startBlinking() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _isMatched) return;
      final status = context.read<WalletBloc>().state.kycCompareFaceStatus;
      if (status == WalletStatus.failure) return;
      setState(() => _showPersonStrong = !_showPersonStrong);
    });
  }

  void _onSuccess() {
    if (_isMatched) return;
    _blinkTimer?.cancel();
    setState(() => _isMatched = true);
    _nextTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      widget.onTapNextPage?.call();
    });
  }

  void _onRetry() {
    /* widget.onTapNextPage?.call();
    return;*/
    if (!mounted) return;
    final bloc = context.read<WalletBloc>();
    // Read selfie/idFace before resetting (reset clears nothing here but ensures clean status)
    final selfie = bloc.state.selfieImageData ?? '';
    final idFace = bloc.state.kycIdFaceImageData ?? '';
    bloc.add(const WalletKycCompareFaceResetRequested());
    if (selfie.isNotEmpty && idFace.isNotEmpty) {
      bloc.add(
        WalletKycCompareFaceRequested(
          selfieImageData: selfie,
          idFaceImageData: idFace,
        ),
      );
    }
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _nextTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WalletBloc, WalletState>(
      listener: (context, state) {
        final status = state.kycCompareFaceStatus;
        if (status == _lastCompareFaceStatus) return;
        _lastCompareFaceStatus = status;

        if (status == WalletStatus.success) {
          _onSuccess();
        }
        // Failure (any type) is handled directly in the builder UI
      },
      builder: (context, state) {
        final lang = state.languageCode;
        final isFailed = state.kycCompareFaceStatus == WalletStatus.failure;
        final outerIsFaded = !_isMatched && !_showPersonStrong;
        final innerIsFaded = !_isMatched && _showPersonStrong;
        return Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 100.h),
            Text(
              AppStrings.get(lang, 'kyc_identity_verification'),
              style: context.textTheme.titleLarge?.bq.copyWith(
                color: const Color(0xff1D1D1D),
                letterSpacing: 0.14,
                height: 1.43,
                fontSize: 30.sp,
              ),
            ),
            SizedBox(height: 15.h),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  TrydosWalletAssets.liveFace,
                  package: TrydosWalletStyles.packageName,
                  height: 20.h,
                ),
                SizedBox(width: 10.w),
                SvgPicture.asset(
                  TrydosWalletAssets.identity,
                  package: TrydosWalletStyles.packageName,
                  height: 20.h,
                ),
                SizedBox(width: 10.w),
                Text(
                  AppStrings.get(lang, 'kyc_id_matching_not_correct'),
                  style: context.textTheme.titleLarge?.mq.copyWith(
                    color: const Color(0xff1D1D1D),
                    letterSpacing: 0.14,
                    height: 1.1,
                    fontSize: 16.sp,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Directionality(
              textDirection: TextDirection.ltr,
              child: Container(
                height: 400.h,
                width: 1.sw,
                margin: EdgeInsets.symmetric(horizontal: 40.w),
                decoration: BoxDecoration(
                  border: _isMatched
                      ? Border.all(color: const Color(0xff34D317), width: 2)
                      : isFailed
                      ? Border.all(color: const Color(0xffFF5F61), width: 2)
                      : null,
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 220),
                      opacity: _isMatched ? 1 : (_showPersonStrong ? 1 : 0.35),
                      child: Container(
                        height: 400.h,
                        width: 1.sw,

                        decoration: BoxDecoration(
                          border: _isMatched
                              ? null
                              : isFailed
                              ? null
                              : (outerIsFaded
                                    ? Border.all(
                                        color: const Color(0xff388CFF),
                                        width: 2,
                                      )
                                    : null),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30.r),
                          child:
                              widget.selfiePath != null &&
                                  widget.selfiePath!.isNotEmpty
                              ? Image.file(
                                  File(widget.selfiePath!),
                                  height: 400.h,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  TrydosWalletPngAssets.personImage,
                                  package: TrydosWalletStyles.packageName,
                                  height: 400.h,
                                  fit: BoxFit.fitWidth,
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 10.h,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        opacity: _isMatched
                            ? 1
                            : (_showPersonStrong ? 0.35 : 1),
                        child: Container(
                          height: 157.h,
                          width: 280.w,
                          margin: EdgeInsets.symmetric(horizontal: 40.w),

                          decoration: BoxDecoration(
                            border: _isMatched
                                ? Border.all(
                                    color: const Color(0xff34D317),
                                    width: 2,
                                  )
                                : isFailed
                                ? Border.all(
                                    color: const Color(0xffFF5F61),
                                    width: 2,
                                  )
                                : (innerIsFaded
                                      ? Border.all(
                                          color: const Color(0xff388CFF),
                                          width: 2,
                                        )
                                      : null),
                            borderRadius: BorderRadius.circular(30.r),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(30.r),
                            child:
                                widget.frontIdPath != null &&
                                    widget.frontIdPath!.isNotEmpty
                                ? Image.file(
                                    File(widget.frontIdPath!),
                                    height: 157.h,
                                    width: 280.w,
                                    fit: BoxFit.cover,
                                  )
                                : Image.asset(
                                    TrydosWalletPngAssets.frontImage,
                                    package: TrydosWalletStyles.packageName,
                                    height: 157.h,
                                    width: 280.w,
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            /*   SizedBox(height: 10.h), ... */
            if (isFailed) ...[
              SizedBox(height: 10.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Text(
                  AppStrings.get(lang, 'kyc_id_discrepancy'),
                  textAlign: TextAlign.center,
                  style: context.textTheme.titleLarge?.rq.copyWith(
                    color: const Color(0xff1D1D1D),
                    letterSpacing: 0.14,
                    height: 1.43,
                    fontSize: 14.sp,
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: InkWell(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: () {
                    final msg =
                        state.kycCompareFaceErrorMessage ??
                        state.kycCompareFaceErrorCode ??
                        '';
                    widget.onMatchError?.call(msg);
                  },
                  child: DottedBorder(
                    padding: EdgeInsets.zero,
                    borderType: BorderType.RRect,
                    strokeCap: StrokeCap.round,
                    strokeWidth: 0.5,
                    dashPattern: const [3, 3],
                    radius: Radius.circular(20.r),
                    color: const Color(0xff5D5C5D),
                    child: Container(
                      width: 1.sw,
                      height: 60.h,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Center(
                        child: Text(
                          AppStrings.get(lang, 'kyc_try_again_correction'),
                          style: context.textTheme.displayMedium?.mq.copyWith(
                            color: const Color(0xff1D1D1D),
                            letterSpacing: 0.16,
                            height: 1.25,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 25.h),
              Center(
                child: InkWell(
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  onTap: _onRetry,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Text(
                      AppStrings.get(lang, 'kyc_rematch'),
                      style: context.textTheme.titleLarge?.rq.copyWith(
                        color: const Color(0xff4D84FF),
                        letterSpacing: 0.14,
                        height: 1.43,
                        fontSize: 14.sp,
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 30.h),
            ],
          ],
        );
      },
    );
  }
}
