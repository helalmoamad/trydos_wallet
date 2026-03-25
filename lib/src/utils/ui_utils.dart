import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:trydos_wallet/src/api/api_interceptors.dart';
import 'package:trydos_wallet/src/bloc/wallet_bloc.dart';
import 'package:trydos_wallet/src/bloc/wallet_state.dart';
import 'package:trydos_wallet/src/localization/app_strings.dart';

/// أنواع الرسائل للتنبيهات.
enum MessageType { success, error, info }

/// عرض رسالة تنبيه (Notification) في أعلى الشاشة بشكل مميز.
/// يتم استخدام [navigatorKey] للوصول للـ Overlay المتاح في التطبيق.
void showMessage(
  String message, {
  BuildContext? context,
  MessageType type = MessageType.info,
  Duration duration = const Duration(seconds: 5),
}) {
  final overlay = context != null
      ? Navigator.of(context).overlay
      : navigatorKey.currentState?.overlay;

  if (overlay == null) {
    // Fallback to SnackBar if Navigator/Overlay is not ready
    final state = context != null
        ? ScaffoldMessenger.of(context)
        : scaffoldMessengerKey.currentState;
    if (state != null) {
      state.showSnackBar(SnackBar(content: Text(message)));
    }
    return;
  }

  late OverlayEntry entry;

  // Keep the signature compatible while always rendering the same notification style.
  final _ = type;

  entry = OverlayEntry(
    builder: (context) {
      return _TopNotificationWidget(
        message: message,
        duration: duration,
        onDismissed: () {
          entry.remove();
        },
      );
    },
  );

  overlay.insert(entry);
}

/// Custom curve for wallet modals:
/// starts slowly from the bottom, then slows down more after mid screen.
class PiecewiseCurve extends Curve {
  const PiecewiseCurve();

  @override
  double transformInternal(double t) {
    if (t <= 0.6) {
      // First stage: slow movement up to around half of the visual travel.
      return 0.55 * Curves.easeInOutCubic.transform(t / 0.6);
    }

    // Second stage: much slower approach toward the final resting position.
    return 0.55 + 0.45 * Curves.easeOutQuart.transform((t - 0.6) / 0.4);
  }
}

/// Closing uses the same feel as opening: slow, then much slower after midpoint.
class ReversePiecewiseCurve extends Curve {
  const ReversePiecewiseCurve();

  @override
  double transformInternal(double t) {
    return const PiecewiseCurve().transform(t);
  }
}

/// Helper to show consistent wallet modals with 90% height and custom animation.
typedef WalletModalBuilder =
    Widget Function(BuildContext context, ScrollController scrollController);

class _WalletModalBackgroundScope
    extends InheritedNotifier<ValueNotifier<Color>> {
  const _WalletModalBackgroundScope({
    required ValueNotifier<Color> super.notifier,
    required super.child,
  });

  static ValueNotifier<Color>? maybeNotifierOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_WalletModalBackgroundScope>()
        ?.notifier;
  }
}

class _WalletModalBackButtonState {
  final bool visible;
  final VoidCallback? onPressed;

  const _WalletModalBackButtonState({required this.visible, this.onPressed});
}

class _WalletModalBackButtonScope
    extends InheritedNotifier<ValueNotifier<_WalletModalBackButtonState>> {
  const _WalletModalBackButtonScope({
    required ValueNotifier<_WalletModalBackButtonState> super.notifier,
    required super.child,
  });

  static ValueNotifier<_WalletModalBackButtonState>? maybeNotifierOf(
    BuildContext context,
  ) {
    return context
        .dependOnInheritedWidgetOfExactType<_WalletModalBackButtonScope>()
        ?.notifier;
  }
}

void setWalletModalBackground(BuildContext context, Color color) {
  final notifier = _WalletModalBackgroundScope.maybeNotifierOf(context);
  if (notifier == null || notifier.value == color) {
    return;
  }
  notifier.value = color;
}

void setWalletModalBackButton(
  BuildContext context, {
  required bool visible,
  VoidCallback? onPressed,
}) {
  final notifier = _WalletModalBackButtonScope.maybeNotifierOf(context);
  if (notifier == null) {
    return;
  }

  notifier.value = _WalletModalBackButtonState(
    visible: visible,
    onPressed: visible ? onPressed : null,
  );
}

Future<T?> showWalletModal<T>({
  required BuildContext context,
  required WalletModalBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color backgroundColor = Colors.white,
}) {
  bool isPopping = false;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: 'Wallet Modal',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 900),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return SafeArea(
        top: false,
        left: false,
        right: false,
        bottom: true,
        child: BlocProvider.value(
          value: context.read<WalletBloc>(),
          child: _WalletModalContainer(
            builder: builder,
            backgroundColor: backgroundColor,
            enableDrag: enableDrag,
            onDismiss: () {
              if (!isPopping && context.mounted) {
                isPopping = true;
                Navigator.of(context).pop();
              }
            },
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      // Use Separate Curves for Forward and Reverse
      final curve = animation.status == AnimationStatus.reverse
          ? const ReversePiecewiseCurve()
          : const PiecewiseCurve();

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: curve)),
        child: child,
      );
    },
  );
}

class _WalletModalContainer extends StatefulWidget {
  final WalletModalBuilder builder;
  final Color backgroundColor;
  final VoidCallback onDismiss;
  final bool enableDrag;

  const _WalletModalContainer({
    required this.builder,
    required this.backgroundColor,
    required this.onDismiss,
    required this.enableDrag,
  });

  @override
  State<_WalletModalContainer> createState() => _WalletModalContainerState();
}

class _WalletModalContainerState extends State<_WalletModalContainer> {
  late DraggableScrollableController _dragController;
  late ScrollController _contentScrollController;
  late ValueNotifier<Color> _backgroundColorNotifier;
  late ValueNotifier<_WalletModalBackButtonState> _backButtonNotifier;
  double _handleDragDistance = 0;

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();
    _contentScrollController = ScrollController();
    _backgroundColorNotifier = ValueNotifier<Color>(widget.backgroundColor);
    _backButtonNotifier = ValueNotifier<_WalletModalBackButtonState>(
      const _WalletModalBackButtonState(visible: false),
    );
  }

  @override
  void dispose() {
    _backgroundColorNotifier.dispose();
    _backButtonNotifier.dispose();
    _contentScrollController.dispose();
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        // Automatically pop when dragged below 10% height
        if (notification.extent < 0.1) {
          widget.onDismiss();
        }
        return false;
      },
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DraggableScrollableSheet(
          controller: _dragController,
          initialChildSize: 0.9,
          minChildSize: 0.0,
          maxChildSize: 0.9,
          expand: false,
          snap: true,
          snapSizes: const [0.0, 0.9],
          builder: (context, sheetScrollController) {
            return Material(
              color: Colors.transparent,
              child: ValueListenableBuilder<Color>(
                valueListenable: _backgroundColorNotifier,
                builder: (context, modalColor, _) {
                  return Container(
                    decoration: BoxDecoration(
                      color: modalColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Keep the sheet controller attached even if child content does not use it.
                        SizedBox(
                          height: 0,
                          child: SingleChildScrollView(
                            controller: sheetScrollController,
                            physics: const NeverScrollableScrollPhysics(),
                            child: const SizedBox(height: 1),
                          ),
                        ),
                        ValueListenableBuilder<_WalletModalBackButtonState>(
                          valueListenable: _backButtonNotifier,
                          builder: (context, backState, _) {
                            return BlocBuilder<WalletBloc, WalletState>(
                              builder: (context, walletState) {
                                final isRtl = walletState.isRtl;
                                final languageCode = walletState.languageCode;
                                return Directionality(
                                  textDirection: isRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  child: SizedBox(
                                    height: 36,
                                    child: Stack(
                                      children: [
                                        if (backState.visible)
                                          PositionedDirectional(
                                            start: 10,
                                            top: 15,
                                            bottom: 0,
                                            child: InkWell(
                                              onTap: backState.onPressed,
                                              child: SizedBox(
                                                height: 30,
                                                width: 60,
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          const EdgeInsetsDirectional.only(
                                                            start: 10,
                                                          ),
                                                      child: Icon(
                                                        Icons
                                                            .arrow_back_ios_new,
                                                        size: 13,
                                                        color: const Color(
                                                          0xff1D1D1D,
                                                        ),
                                                      ),
                                                    ),
                                                    Text(
                                                      ' ${AppStrings.get(languageCode, 'back')}',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                        color: Color(
                                                          0xff1D1D1D,
                                                        ),
                                                        fontSize: 11,
                                                        fontFamily: 'Quicksand',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        // end back button
                                        Center(
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onVerticalDragStart: (_) {
                                              _handleDragDistance = 0;
                                            },
                                            onVerticalDragUpdate: (details) {
                                              if (!widget.enableDrag ||
                                                  !_dragController.isAttached) {
                                                return;
                                              }

                                              final dy =
                                                  details.primaryDelta ?? 0;
                                              if (dy > 0) {
                                                _handleDragDistance += dy;
                                              }

                                              final currentSize =
                                                  _dragController.size;
                                              final delta =
                                                  dy /
                                                  MediaQuery.of(
                                                    context,
                                                  ).size.height;
                                              _dragController.jumpTo(
                                                (currentSize - delta).clamp(
                                                  0.0,
                                                  0.9,
                                                ),
                                              );
                                            },
                                            onVerticalDragEnd: (details) {
                                              if (!widget.enableDrag ||
                                                  !_dragController.isAttached) {
                                                return;
                                              }

                                              final velocity =
                                                  details.primaryVelocity ?? 0;
                                              final shouldClose =
                                                  _handleDragDistance > 24 ||
                                                  velocity > 600;

                                              if (shouldClose) {
                                                _dragController
                                                    .animateTo(
                                                      0,
                                                      duration: const Duration(
                                                        milliseconds: 220,
                                                      ),
                                                      curve: Curves.easeOut,
                                                    )
                                                    .then((_) {
                                                      if (mounted) {
                                                        widget.onDismiss();
                                                      }
                                                    });
                                                return;
                                              }

                                              _dragController.animateTo(
                                                0.9,
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                curve: Curves.easeOut,
                                              );
                                            },
                                            child: Container(
                                              width: 60,
                                              height: 35,
                                              alignment: Alignment.topCenter,
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  top: 10,
                                                ),
                                                child: Container(
                                                  width: 40,
                                                  height: 2,
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xffC4C2C2,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          2,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        // Wrap the builder in a Flexible instead of Expanded to avoid overflow issues
                        // during sheet compression (closing).
                        Flexible(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                            child: _WalletModalBackgroundScope(
                              notifier: _backgroundColorNotifier,
                              child: _WalletModalBackButtonScope(
                                notifier: _backButtonNotifier,
                                child: widget.builder(
                                  context,
                                  _contentScrollController,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TopNotificationWidget extends StatefulWidget {
  final String message;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopNotificationWidget({
    required this.message,
    required this.duration,
    required this.onDismissed,
  });

  @override
  State<_TopNotificationWidget> createState() => _TopNotificationWidgetState();
}

class _TopNotificationWidgetState extends State<_TopNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // إغلاق تلقائي بعد المدة المحددة
    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDismissed();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top + 16;

    return Positioned(
      top: topPadding,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xff444146),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x3D000000),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xffFF4D4F),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.priority_high_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Quicksand',
                      height: 1.1,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.close,
                    color: Color(0xff9A999D),
                    size: 22,
                  ),
                  onPressed: () async {
                    await _controller.reverse();
                    widget.onDismissed();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
