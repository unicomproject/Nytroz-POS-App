import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../features/notifications/domain/entities/realtime_notification_event.dart';
import 'api_endpoints.dart';

/// Push-only WebSocket client for `/ws/notifications`. Hand-rolls
/// reconnect-with-backoff on top of `web_socket_channel` (the official
/// Dart-team package) rather than depending on a third-party SignalR client.
class NotificationSocketClient {
  NotificationSocketClient({
    required String httpBaseUrl,
    this.onConnected,
  }) : _wsBaseUrl = _toWebSocketOrigin(httpBaseUrl);

  static const _backoffSeconds = [1, 2, 5, 10, 30];

  final String _wsBaseUrl;
  final void Function()? onConnected;
  final _eventController =
      StreamController<RealtimeNotificationEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  // Identifies the logged-in session a connection belongs to (e.g. the full
  // session access token) -- used only to detect "same session, skip
  // reconnect", never sent over the wire. The actual handshake credential is
  // always fetched fresh via [_fetchToken] just before connecting, since it
  // is short-lived and a stale copy would fail auth on any real reconnect.
  String? _currentSessionKey;
  Future<String?> Function()? _fetchToken;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _wasConnected = false;

  Stream<RealtimeNotificationEvent> get events => _eventController.stream;

  void connect(String sessionKey, Future<String?> Function() fetchToken) {
    if (_disposed || sessionKey.isEmpty) return;
    if (_currentSessionKey == sessionKey && _channel != null) return;
    _currentSessionKey = sessionKey;
    _fetchToken = fetchToken;
    _reconnectAttempt = 0;
    unawaited(_openConnection());
  }

  void disconnect() {
    _currentSessionKey = null;
    _fetchToken = null;
    _wasConnected = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _teardownChannel();
  }

  void dispose() {
    _disposed = true;
    disconnect();
    unawaited(_eventController.close());
  }

  Future<void> _openConnection() async {
    if (_disposed) return;
    final sessionKey = _currentSessionKey;
    final fetchToken = _fetchToken;
    if (sessionKey == null || fetchToken == null) return;

    _teardownChannel();

    final token = await fetchToken();
    if (token == null || _disposed) return;

    final uri =
        Uri.parse('$_wsBaseUrl${ApiEndpoints.tenantNotificationsSocketPath}')
            .replace(queryParameters: {'access_token': token});

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: _handleDisconnected,
        onError: (_) => _handleDisconnected(),
        cancelOnError: true,
      );
      // web_socket_channel opens asynchronously; treat listen attach as connected
      // for reconnect recovery (missed events while down).
      final isReconnect = _wasConnected;
      _wasConnected = true;
      _reconnectAttempt = 0;
      if (isReconnect) {
        onConnected?.call();
      }
    } catch (error) {
      developer.log(
        'Notification socket connect failed.',
        name: 'notifications.socket',
        error: error,
      );
      _scheduleReconnect();
    }
  }

  void _handleDisconnected() {
    _scheduleReconnect();
  }

  void _handleMessage(dynamic raw) {
    _reconnectAttempt = 0;
    if (raw is! String) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        _eventController.add(RealtimeNotificationEvent.fromJson(decoded));
      }
    } catch (error) {
      developer.log(
        'Malformed notification socket payload ignored.',
        name: 'notifications.socket',
        error: error,
      );
    }
  }

  void _scheduleReconnect() {
    _teardownChannel();
    if (_disposed || _currentSessionKey == null) return;

    _reconnectTimer?.cancel();
    final delaySeconds =
        _backoffSeconds[_reconnectAttempt.clamp(0, _backoffSeconds.length - 1)];
    _reconnectAttempt =
        (_reconnectAttempt + 1).clamp(0, _backoffSeconds.length - 1);
    _reconnectTimer = Timer(
      Duration(seconds: delaySeconds),
      () => unawaited(_openConnection()),
    );
  }

  void _teardownChannel() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    unawaited(_channel?.sink.close());
    _channel = null;
  }

  static String _toWebSocketOrigin(String httpBaseUrl) {
    final uri = Uri.parse(httpBaseUrl);
    final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
    return uri.replace(scheme: wsScheme, path: '').toString();
  }
}
