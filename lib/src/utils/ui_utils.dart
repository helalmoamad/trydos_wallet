import 'package:flutter/material.dart';
import 'package:trydos_wallet/src/api/api_interceptors.dart';

/// أنواع الرسائل للتنبيهات.
enum MessageType { success, error, info }

/// عرض رسالة تنبيه (Notification) في أعلى الشاشة بشكل مميز.
/// يتم استخدام [navigatorKey] للوصول للـ Overlay المتاح في التطبيق.
void showMessage(
  String message, {
  MessageType type = MessageType.info,
  Duration duration = const Duration(seconds: 5),
}) {
  final overlay = navigatorKey.currentState?.overlay;
  if (overlay == null) {
    // Fallback to SnackBar if Navigator/Overlay is not ready
    final state = scaffoldMessengerKey.currentState;
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
