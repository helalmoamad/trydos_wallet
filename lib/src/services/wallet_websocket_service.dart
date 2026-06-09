import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as sio;

typedef WalletSocketLog = void Function(String message);
typedef WalletSocketEvent = void Function(String event, dynamic payload);

/// Socket.IO WebSocket client for real-time wallet + session updates.
///
/// Opens one connection per namespace (`/wallet` and `/sessions`) using the
/// same JWT. Socket.IO multiplexes them to the same host, so holding both open
/// is cheap. Each tracked event is registered on exactly one namespace so the
/// server's cross-namespace broadcast (`emitToUser` fans a user event out to
/// every connected namespace) never delivers the same event twice.
class WalletWebSocketService {
  WalletWebSocketService({
    required this.baseUrl,
    required this.token,
    required this.onLog,
    required this.onTrackedEvent,
    this.allowBadCertificate = false,
  });

  static const String _walletNamespace = '/wallet';
  static const String _sessionsNamespace = '/sessions';
  static const String _socketPath = '/socket.io/';

  /// Live wallet events (balances + ledger) delivered on `/wallet`.
  static const Set<String> walletEvents = <String>{
    'balance:updated',
    'ledger:created',
    'ledger:completed',
    'ledger:failed',
    'ledger:cancelled',
  };

  /// Session-lifecycle events (approval / lock / switch / revocation)
  /// delivered on `/sessions` — the canonical namespace for `session:*`.
  static const Set<String> sessionEvents = <String>{
    'session:approval_request',
    'session:approved',
    'session:rejected',
    'session:locked',
    'session:activated',
    'session:revoked_by_switch',
    'session:revoked_by_new_login',
    'session:revoked',
    'session:all_revoked',
  };

  /// Namespace → the events this service subscribes to on it. Listening to a
  /// given event on a single namespace avoids duplicate dispatch from the
  /// server's cross-namespace user broadcast.
  static const Map<String, Set<String>> _namespaceEvents = <String, Set<String>>{
    _walletNamespace: walletEvents,
    _sessionsNamespace: sessionEvents,
  };

  final String baseUrl;
  final String token;
  final WalletSocketLog onLog;
  final WalletSocketEvent onTrackedEvent;
  final bool allowBadCertificate;

  /// One socket per namespace, keyed by namespace path.
  final Map<String, sio.Socket> _sockets = <String, sio.Socket>{};
  bool _disposed = false;

  /// Connected only when every namespace socket is live.
  bool get isConnected =>
      _sockets.isNotEmpty && _sockets.values.every((s) => s.connected);

  void connect() {
    if (token.trim().isEmpty) return;
    if (isConnected) return;

    // Re-arm after a previous disconnect so reconnection on the same instance
    // (e.g. WalletReconnectWebSocketRequested) delivers events again.
    _disposed = false;

    if (allowBadCertificate) {
      _applyBadCertificateOverride();
    }

    final base = _normalizeBase(baseUrl);

    for (final entry in _namespaceEvents.entries) {
      final existing = _sockets[entry.key];
      // Leave an already-live namespace socket untouched; only (re)wire ones
      // that are missing or disconnected.
      if (existing != null && existing.connected) continue;
      if (existing != null) {
        existing.clearListeners();
        existing.dispose();
      }
      _connectNamespace(base, entry.key, entry.value);
    }
  }

  /// Builds, wires and connects a single namespace socket.
  void _connectNamespace(String base, String namespace, Set<String> events) {
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
      onLog(' $base$namespace Socket options: $options');
    }

    final socket = sio.io('$base$namespace', options);
    _sockets[namespace] = socket;

    socket
      ..onConnect((_) {
        onLog('Connected to $namespace namespace via path $_socketPath.');
      })
      ..onDisconnect((reason) {
        onLog('[$namespace] Disconnected: $reason');
      })
      ..onConnectError((err) {
        onLog('[$namespace] Connect error: $err');
        if (err.toString().contains('was not upgraded to websocket')) {
          onLog(
            'WebSocket rejected by server/proxy. No transport fallback is '
            'configured (websocket-only); the client will keep retrying.',
          );
        }
      })
      ..onError((err) {
        onLog('[$namespace] Socket error: $err');
      })
      ..on('authenticated', (_) {
        onLog('[$namespace] Authenticated by server.');
      })
      ..on('reconnect_attempt', (attempt) {
        onLog('[$namespace] Reconnecting... attempt $attempt');
      })
      ..on('reconnect', (attempt) {
        onLog('[$namespace] Reconnected after $attempt attempt(s).');
      })
      ..on('reconnect_failed', (_) {
        onLog('[$namespace] Reconnection failed after max attempts.');
      });

    for (final event in events) {
      socket.on(event, (data) {
        // Ignore any in-flight callbacks that fire after disconnect().
        if (_disposed) return;
        // Per-event logging is debug-only: it runs on every realtime event and
        // would otherwise allocate strings and flood logs in release builds.
        if (kDebugMode) {
          onLog('[$namespace] Event received: $event');
          debugPrint('[WalletWS] Payload: $data');
        }
        onTrackedEvent(event, data);
      });
    }
    onLog('Connecting to $base$namespace (path=$_socketPath) ...');
    socket.connect();
  }

  void disconnect() {
    // Stop callbacks immediately so nothing fires for a disposed consumer,
    // even if a socket event is already queued on the event loop.
    _disposed = true;
    for (final socket in _sockets.values) {
      socket.clearListeners();
      socket.disconnect();
      socket.dispose();
    }
    _sockets.clear();
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
