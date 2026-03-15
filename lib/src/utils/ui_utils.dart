import 'package:flutter/material.dart';
import 'package:trydos_wallet/src/api/api_interceptors.dart';

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

  IconData icon;
  Color color;

  switch (type) {
    case MessageType.success:
      icon = Icons.check_circle_outline;
      color = Colors.green.shade600;
      break;
    case MessageType.error:
      icon = Icons.error_outline;
      color = Colors.red.shade600;
      break;
    case MessageType.info:
      icon = Icons.info_outline;
      color = Colors.blue.shade600;
      break;
  }

  entry = OverlayEntry(
    builder: (context) {
      return _TopNotificationWidget(
        message: message,
        icon: icon,
        backgroundColor: color,
        duration: duration,
        onDismissed: () {
          entry.remove();
        },
      );
    },
  );

  overlay.insert(entry);
}

/// Custom curve for wallet modals: fast opening below 50%, slow above 50%.
class PiecewiseCurve extends Curve {
  const PiecewiseCurve();

  @override
  double transformInternal(double t) {
    // Opening: Extremely fast to 70% of transition (in 10% time), then crawls.
    if (t < 0.1) return (t / 0.1) * 0.7;
    return 0.7 + ((t - 0.1) / 0.9) * 0.3;
  }
}

/// Custom curve for closing: slow for top half, very fast for bottom half.
class ReversePiecewiseCurve extends Curve {
  const ReversePiecewiseCurve();

  @override
  double transformInternal(double t) {
    // We want "slow then fast" during closing (progress 1.0 down to 0.0).
    // Reach 0.5 height slowly (first 70% of time), then snap 0.5 to 0.0 (final 30%).
    if (t > 0.3) {
      // Top 70% of closing time: Moves from height 1.0 down to 0.5
      return 0.5 + ((t - 0.3) / 0.7) * 0.5;
    } else {
      // Final 30% of closing time: Moves from height 0.5 down to 0.0 (Rapid)
      return (t / 0.3) * 0.5;
    }
  }
}

/// Helper to show consistent wallet modals with 90% height and custom animation.
typedef WalletModalBuilder =
    Widget Function(BuildContext context, ScrollController scrollController);

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
    transitionDuration: const Duration(milliseconds: 600),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _WalletModalContainer(
        builder: builder,
        backgroundColor: backgroundColor,
        enableDrag: enableDrag,
        onDismiss: () {
          if (!isPopping && context.mounted) {
            isPopping = true;
            Navigator.of(context).pop();
          }
        },
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

  @override
  void initState() {
    super.initState();
    _dragController = DraggableScrollableController();
  }

  @override
  void dispose() {
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
          builder: (context, scrollController) {
            return Material(
              color: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: 0,
                      maxHeight: MediaQuery.of(context).size.height,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle and Drag Area (Header)
                        // We wrap this in a GestureDetector to make it draggable.
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (details) {
                            if (widget.enableDrag) {
                              final currentSize = _dragController.size;
                              final delta =
                                  details.primaryDelta! /
                                  MediaQuery.of(context).size.height;
                              _dragController.jumpTo(currentSize - delta);
                            }
                          },
                          onVerticalDragEnd: (details) {
                            if (widget.enableDrag) {
                              final currentSize = _dragController.size;
                              if (currentSize < 0.45) {
                                _dragController.animateTo(
                                  0,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              } else {
                                _dragController.animateTo(
                                  0.9,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 0),
                            width: double.infinity,
                            child: Center(
                              child: Container(
                                width: 40,
                                height: 0,
                                decoration: BoxDecoration(
                                  color: const Color(0xffC4C2C2),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Wrap the builder in a Flexible instead of Expanded to avoid overflow issues
                        // during sheet compression (closing).
                        Flexible(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(30),
                            ),
                            child: widget.builder(context, scrollController),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
  final IconData icon;
  final Color backgroundColor;
  final Duration duration;
  final VoidCallback onDismissed;

  const _TopNotificationWidget({
    required this.message,
    required this.icon,
    required this.backgroundColor,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Quicksand',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
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
