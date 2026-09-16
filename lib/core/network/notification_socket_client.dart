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
    this.ticketProvider,
  }) : _wsBaseUrl = _toWebSocketOrigin(httpBaseUrl);

  static const _backoffSeconds = [2, 5, 10, 30, 60];

  final String _wsBaseUrl;
  final void Function()? onConnected;
  final Future<String?> Function()? ticketProvider;
  final _eventController =
      StreamController<RealtimeNotificationEvent>.broadcast();

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  String? _currentToken;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _wasConnected = false;

  Stream<RealtimeNotificationEvent> get events => _eventController.stream;

  void connect(String accessToken) {
    if (_disposed || accessToken.isEmpty) return;
    if (_currentToken == accessToken && _channel != null) return;
    _currentToken = accessToken;
    _reconnectAttempt = 0;
    _openConnection();
  }

  void disconnect() {
    _currentToken = null;
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
    final token = _currentToken;
    if (token == null) return;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _teardownChannel();

    Map<String, String> queryParams;
    if (ticketProvider != null) {
      try {
        final ticket = await ticketProvider!();
        if (ticket != null && ticket.isNotEmpty) {
          queryParams = {'ticket': ticket};
        } else {
          // Ticket retrieval failed; wait and retry with backoff rather than sending large JWT.
          _scheduleReconnect();
          return;
        }
      } catch (_) {
        _scheduleReconnect();
        return;
      }
    } else {
      queryParams = {'access_token': token};
    }

    final uri = Uri.parse('$_wsBaseUrl${ApiEndpoints.tenantNotificationsSocketPath}')
        .replace(queryParameters: queryParams);

    try {
      final channel = WebSocketChannel.connect(uri);
      _channel = channel;
      void disconnected() {
        if (identical(_channel, channel)) _handleDisconnected();
      }
      _subscription = channel.stream.listen(
        _handleMessage,
        onDone: disconnected,
        onError: (_) => disconnected(),
        cancelOnError: true,
      );
      // A stream listener is not evidence of a successful handshake.
      // Ignore completion from disconnected or superseded connections.
      try {
        await channel.ready;
      } catch (_) {
        disconnected();
        return;
      }
      if (_disposed || !identical(_channel, channel)) return;
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
    if (_disposed || _currentToken == null) return;

    _reconnectTimer?.cancel();
    final delaySeconds = _backoffSeconds[
        _reconnectAttempt.clamp(0, _backoffSeconds.length - 1)];
    _reconnectAttempt =
        (_reconnectAttempt + 1).clamp(0, _backoffSeconds.length - 1);
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), _openConnection);
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
