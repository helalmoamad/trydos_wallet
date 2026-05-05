import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Monitors real internet connectivity using:
/// 1. connectivity_plus for instant network-interface change triggers.
/// 2. A TCP socket to 8.8.8.8:53 to verify actual internet (bypasses DNS cache).
/// 3. A periodic timer (10 s online / 5 s offline) to catch "WiFi but no internet".
class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _periodicTimer;
  bool _initialized = false;
  bool _checking = false;

  static const Duration _onlineInterval = Duration(seconds: 10);
  static const Duration _offlineInterval = Duration(seconds: 5);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Immediate check on startup
    await _checkAndUpdate();

    // React instantly to network interface changes
    _subscription = Connectivity().onConnectivityChanged.listen((_) {
      _checkAndUpdate();
    });

    // Periodic check catches "WiFi connected but no internet" cases
    _scheduleNextCheck();
  }

  void _scheduleNextCheck() {
    _periodicTimer?.cancel();
    final interval = isOnline.value ? _onlineInterval : _offlineInterval;
    _periodicTimer = Timer(interval, () async {
      await _checkAndUpdate();
      if (_initialized) _scheduleNextCheck();
    });
  }

  Future<void> _checkAndUpdate() async {
    if (_checking) return;
    _checking = true;
    try {
      final online = await _hasRealInternet();
      if (isOnline.value != online) {
        isOnline.value = online;
        // Reschedule with the new interval
        _scheduleNextCheck();
      }
    } finally {
      _checking = false;
    }
  }

  /// TCP connection to Google Public DNS (8.8.8.8:53).
  /// Bypasses OS DNS cache — works even when DNS resolves locally.
  Future<bool> _hasRealInternet() async {
    try {
      final socket = await Socket.connect(
        '8.8.8.8',
        53,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  void dispose() {
    _subscription?.cancel();
    _periodicTimer?.cancel();
    isOnline.dispose();
    _initialized = false;
  }
}
