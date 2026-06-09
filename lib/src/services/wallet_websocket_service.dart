import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

typedef WalletSocketLog = void Function(String message);
typedef WalletSocketEvent = void Function(String event, dynamic payload);

/// Socket.IO WebSocket client for real-time wallet updates (namespace=/wallet).
class WalletWebSocketService {
  WalletWebSocketService({
    required this.baseUrl,
    required this.token,
    required this.onLog,
    required this.onTrackedEvent,
    this.allowBadCertificate = false,
  });

  static const Set<String> trackedEvents = <String>{
    'ledger:created',
    'ledger:completed',
    'ledger:failed',
    'ledger:cancelled',
    'balance:updated',
    'session:approval_request',
  };

  static const String _namespace = '/wallet';
  static const String _socketPath = '/socket.io/';

  final String baseUrl;
  final String token;
  final WalletSocketLog onLog;
  final WalletSocketEvent onTrackedEvent;
  final bool allowBadCertificate;

  sio.Socket? _socket;
  bool _disposed = false;

  bool get isConnected => _socket?.connected ?? false;

  void connect() {
    /*  print('Connecting to wallet WebSocket with token:000000000000000 $token');
    Future.delayed(const Duration(seconds: 10), () {
      print('Connecting to wallet WebSocket with token:111111111 $token');
      onTrackedEvent("session:approval_request", {
        'id': 'example',
        'title': 'Example Device',
        'subtitle': 'Flutter SDK Demo',
        'description':
            'Approve this login to see realtime events in the demo app.',
        'expiresAt': DateTime.now().add(const Duration(minutes: 5)),
      });
    });*/
    if (token.trim().isEmpty) return;
    if (_socket != null && _socket!.connected) return;

    // Re-arm after a previous disconnect so reconnection on the same instance
    // (e.g. WalletReconnectWebSocketRequested) delivers events again.
    _disposed = false;

    if (allowBadCertificate) {
      _applyBadCertificateOverride();
    }

    final base = _normalizeBase(baseUrl);

    final options = sio.OptionBuilder()
        // WebSocket only: lowest latency for realtime updates, no polling
        // overhead. (No transport fallback is configured.)
        .setTransports(["websocket"])
        .setPath(_socketPath)
        .enableForceNew()
        .disableMultiplex()
        .disableAutoConnect()
        .setAuth({'token': token.trim()})
        .enableReconnection()
        .setReconnectionAttempts(10)
        // Exponential-ish backoff with jitter to avoid a reconnect stampede
        // when the server restarts and every client retries at once.
        .setReconnectionDelay(2000)
        .setReconnectionDelayMax(30000)
        .setRandomizationFactor(0.5)
        .setTimeout(10000)
        .build();

    if (kDebugMode) {
      onLog(' $base$_namespace Socket options: $options');
    }

    _socket = sio.io('$base$_namespace', options);

    _socket!
      ..onConnect((_) {
        onLog('Connected to $_namespace namespace via path $_socketPath.');
      })
      ..onDisconnect((reason) {
        onLog('Disconnected: $reason');
      })
      ..onConnectError((err) {
        onLog('Connect error: $err');
        if (err.toString().contains('was not upgraded to websocket')) {
          onLog(
            'WebSocket rejected by server/proxy. No transport fallback is '
            'configured (websocket-only); the client will keep retrying.',
          );
        }
      })
      ..onError((err) {
        onLog('Socket error: $err');
      })
      ..on('authenticated', (_) {
        onLog('Authenticated by server.');
      })
      ..on('reconnect_attempt', (attempt) {
        onLog('Reconnecting... attempt $attempt');
      })
      ..on('reconnect', (attempt) {
        onLog('Reconnected after $attempt attempt(s).');
      })
      ..on('reconnect_failed', (_) {
        onLog('Reconnection failed after max attempts.');
      });

    for (final event in trackedEvents) {
      _socket!.on(event, (data) {
        // Ignore any in-flight callbacks that fire after disconnect().
        if (_disposed) return;
        // Per-event logging is debug-only: it runs on every realtime event and
        // would otherwise allocate strings and flood logs in release builds.
        if (kDebugMode) {
          onLog('Event received: $event');
          debugPrint('[WalletWS] Payload: $data');
        }
        onTrackedEvent(event, data);
      });
    }
    onLog('Connecting to $base$_namespace (path=$_socketPath) ...');
    _socket!.connect();
  }

  void disconnect() {
    // Stop callbacks immediately so nothing fires for a disposed consumer,
    // even if a socket event is already queued on the event loop.
    _disposed = true;
    _socket?.clearListeners();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    onLog('Disconnected.');
  }

  String _normalizeBase(String value) {
    final t = value.trim();
    return t.endsWith('/') ? t.substring(0, t.length - 1) : t;
  }

  static bool _insecureOverrideApplied = false;

  void _applyBadCertificateOverride() {
    if (_insecureOverrideApplied) return;
    HttpOverrides.global = _WalletSocketHttpOverrides();
    _insecureOverrideApplied = true;
    onLog('Applied insecure TLS override (development only).');
  }
}

class _WalletSocketHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  }
}
