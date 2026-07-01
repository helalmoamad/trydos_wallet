import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:trydos_wallet/src/constent/assets.dart';
import 'package:trydos_wallet/src/constent/build_context.dart';
import 'package:trydos_wallet/src/constent/styles.dart';
import 'package:trydos_wallet/src/constent/theme/typography.dart';
import 'package:trydos_wallet/trydos_wallet.dart';

/// Displays the current user's login history (`GET /users/me/login-history`).
/// Reached from Settings → History; supports a status filter (all/success/
/// failure), pull-to-refresh, and infinite-scroll pagination.
class LoginHistoryPage extends StatefulWidget {
  const LoginHistoryPage({super.key});

  @override
  State<LoginHistoryPage> createState() => _LoginHistoryPageState();
}

class _LoginHistoryPageState extends State<LoginHistoryPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Near the bottom → load the next page.
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<WalletBloc>().add(
        const WalletLoginHistoryLoadMoreRequested(),
      );
    }
  }

  bool _isRtl(String lang) => lang == 'ar' || lang == 'ku';

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WalletBloc, WalletState>(
      builder: (context, state) {
        final lang = state.languageCode;
        return Directionality(
          textDirection: _isRtl(lang) ? TextDirection.rtl : TextDirection.ltr,
          child: Scaffold(
            backgroundColor: const Color(0xffFFFFFF),
            body: SafeArea(
              child: Column(
                children: [
                  // Header
                  SizedBox(
                    height: 50.h,
                    width: 1.sw,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10.w),
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            child: SvgPicture.asset(
                              TrydosWalletAssets.back,
                              package: TrydosWalletStyles.packageName,
                              height: 20.h,
                              matchTextDirection: true,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          AppStrings.get(lang, 'history'),
                          textAlign: TextAlign.center,
                          style: context.textTheme.bodyMedium?.rq.copyWith(
                            fontSize: 16.sp,
                            height: 1.1,
                            color: const Color(0xFF1D1D1D),
                          ),
                        ),
                        SizedBox(width: 20.w),
                        const Spacer(),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  _buildFilterChips(context, state, lang),
                  SizedBox(height: 8.h),
                  Expanded(child: _buildBody(context, state, lang)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChips(
    BuildContext context,
    WalletState state,
    String lang,
  ) {
    final filters = <String, String?>{
      AppStrings.get(lang, 'all'): null,
      AppStrings.get(lang, 'success'): 'success',
      AppStrings.get(lang, 'failed'): 'failure',
    };
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Row(
        children: filters.entries.map((entry) {
          final selected = state.loginHistoryFilter == entry.value;
          return Padding(
            padding: EdgeInsetsDirectional.only(end: 8.w),
            child: InkWell(
              borderRadius: BorderRadius.circular(20.r),
              onTap: () => context.read<WalletBloc>().add(
                WalletLoginHistoryRequested(status: entry.value),
              ),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xff388CFF)
                      : const Color(0xffF2F2F2),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  entry.key,
                  style: context.textTheme.bodyMedium?.rq.copyWith(
                    color: selected ? Colors.white : const Color(0xff1D1D1D),
                    fontSize: 12.sp,
                    height: 1.1,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WalletState state, String lang) {
    // Shimmer on any fresh load (initial OR a filter change) — a load-more uses
    // `loginHistoryLoadingMore` (bottom spinner) and does NOT hit this branch.
    if (state.loginHistoryStatus == WalletStatus.loading) {
      return _buildShimmerList();
    }

    // Any failure → show the failure message only; the bloc already cleared the
    // previous list so no stale data / old filter results remain.
    if (state.loginHistoryStatus == WalletStatus.failure) {
      return _buildMessage(
        context,

        AppStrings.get(lang, 'login_history_load_failed'),
      );
    }

    // Succeeded but no entries.
    if (state.loginHistory.isEmpty) {
      return _buildMessage(
        context,
        AppStrings.get(lang, 'login_history_empty'),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<WalletBloc>().add(
          WalletLoginHistoryRequested(status: state.loginHistoryFilter),
        );
      },
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        // +1 for the trailing load-more indicator.
        itemCount: state.loginHistory.length + 1,
        separatorBuilder: (_, __) => SizedBox(height: 8.h),
        itemBuilder: (context, index) {
          if (index == state.loginHistory.length) {
            return _buildFooter(state);
          }
          return _LoginHistoryCard(item: state.loginHistory[index], lang: lang);
        },
      ),
    );
  }

  Widget _buildFooter(WalletState state) {
    if (!state.loginHistoryLoadingMore) {
      return SizedBox(height: 8.h);
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Center(
        child: SizedBox(
          width: 22.w,
          height: 22.w,
          child: const CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildMessage(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.textTheme.bodyMedium?.rq.copyWith(
            color: const Color(0xff8D8D8D),
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: 6,
      separatorBuilder: (_, __) => SizedBox(height: 8.h),
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: const Color(0xffE6E6E6),
        highlightColor: const Color(0xffF7F7F7),
        child: Container(
          height: 84.h,
          decoration: BoxDecoration(
            color: const Color(0xffEDEDED),
            borderRadius: BorderRadius.circular(15.r),
          ),
        ),
      ),
    );
  }
}

class _LoginHistoryCard extends StatelessWidget {
  const _LoginHistoryCard({required this.item, required this.lang});

  final LoginHistoryItem item;
  final String lang;

  Color get _statusColor =>
      item.isSuccess ? const Color(0xff34D317) : const Color(0xffFF5F61);

  /// A value is worth showing only if it isn't null/empty/"unknown".
  bool _isMeaningful(String? v) {
    final s = v?.trim();
    return s != null && s.isNotEmpty && s.toLowerCase() != 'unknown';
  }

  String _formattedDate() {
    final dt = item.createdAt?.toLocal();
    if (dt == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final device = item.device;
    // key label → value, in display order. Empty/null/unknown are dropped below.
    final pairs = <MapEntry<String, String?>>[
      MapEntry(AppStrings.get(lang, 'login_method'), item.method),
      MapEntry(AppStrings.get(lang, 'login_browser'), device?.browser),
      MapEntry(AppStrings.get(lang, 'login_os'), device?.operatingSystem),
      MapEntry(AppStrings.get(lang, 'login_device'), device?.device),
      MapEntry(AppStrings.get(lang, 'login_city'), item.city),
      MapEntry(AppStrings.get(lang, 'login_country'), item.country),
      MapEntry(AppStrings.get(lang, 'login_ip'), item.ipAddress),
      MapEntry(AppStrings.get(lang, 'login_user_agent'), device?.userAgent),
    ].where((e) => _isMeaningful(e.value)).toList();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xffFCFCFC),
        borderRadius: BorderRadius.circular(15.r),
        border: Border.all(color: const Color(0xffEDEDED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status pill
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: _statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  item.isSuccess
                      ? AppStrings.get(lang, 'success')
                      : AppStrings.get(lang, 'failed'),
                  style: context.textTheme.bodyMedium?.mq.copyWith(
                    color: _statusColor,
                    fontSize: 11.sp,
                    height: 1.1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _formattedDate(),
                textDirection: TextDirection.ltr,
                style: context.textTheme.bodyMedium?.lq.copyWith(
                  color: const Color(0xff8D8D8D),
                  fontSize: 11.sp,
                  height: 1.1,
                ),
              ),
            ],
          ),
          // Failure reason (localized, display as-is)
          if (item.isFailure &&
              (item.failureReasonLabel?.isNotEmpty ?? false)) ...[
            SizedBox(height: 8.h),
            Text(
              item.failureReasonLabel!,
              style: context.textTheme.bodyMedium?.rq.copyWith(
                color: const Color(0xffFF5F61),
                fontSize: 12.sp,
                height: 1.2,
              ),
            ),
          ],
          // key : value list (only meaningful fields)
          ...pairs.map((e) => _kvRow(context, e.key, e.value!.trim())),
        ],
      ),
    );
  }

  Widget _kvRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: context.textTheme.bodyMedium?.mq.copyWith(
              color: const Color(0xff8D8D8D),
              fontSize: 12.sp,
              height: 1.3,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: context.textTheme.bodyMedium?.rq.copyWith(
                color: const Color(0xff1D1D1D),
                fontSize: 12.sp,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
