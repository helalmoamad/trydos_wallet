import 'dart:async';
import 'package:flutter/material.dart';
import 'package:trydos_wallet/src/api/api_interceptors.dart';
import 'package:trydos_wallet/src/utils/ui_utils.dart';

class ApiErrorListener extends StatefulWidget {
  final Widget child;

  const ApiErrorListener({super.key, required this.child});

  @override
  State<ApiErrorListener> createState() => _ApiErrorListenerState();
}

class _ApiErrorListenerState extends State<ApiErrorListener> {
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();

    _errorSubscription = errorEvents.listen((event) {
      debugPrint('[ApiErrorListener] 400 error detected: ${event.message}');
      if (mounted) {
        _showErrorSnackBar(context, event.message);
      }
    });
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    showMessage(message, context: context, type: MessageType.error);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
