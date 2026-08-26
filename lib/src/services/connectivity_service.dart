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

  /// Live consumers (mounted wallet screens).
  ///
  /// This is a library embedded in someone else's app, so the periodic check
  /// must not outlive the wallet UI: it opens a TCP socket every 10 s, and
  /// before refcounting nothing ever stopped it — a host that navigated away
  /// from the wallet kept paying for it until the process died.
  int _consumers = 0;

  /// Registers a consumer and starts monitoring if this is the first one.
  /// Every [acquire] must be matched by exactly one [release].
  Future<void> acquire() async {
    _consumers++;
    await initialize();
  }

  /// Drops a consumer; stops monitoring once the last one is gone.
  void release() {
    if (_consumers == 0) return;
    _consumers--;
    if (_consumers == 0) _shutdown();
  }

  void _shutdown() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    // Allow a later acquire() to start monitoring again.
    _initialized = false;
  }

  /// Test seam. Widget tests that mount wallet screens would otherwise open a
  /// real socket to 8.8.8.8 with a 5 s timeout, whose pending timer outlives
  /// the test and fails it with "A Timer is still pending".
  @visibleForTesting
  static bool disabledForTesting = false;

  Future<void> initialize() async {
    if (disabledForTesting) return;
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
    // An in-flight _checkAndUpdate can land after _shutdown(); without this
    // guard it would silently restart the timer the last release() stopped.
    if (!_initialized) return;
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
