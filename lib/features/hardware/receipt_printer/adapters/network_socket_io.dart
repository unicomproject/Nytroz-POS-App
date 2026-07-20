import 'dart:io';

class NetworkSocket {
  NetworkSocket._(this._socket);

  final Socket _socket;

  static Future<NetworkSocket> connect(
    String host,
    int port, {
    Duration? timeout,
  }) async {
    final socket = await Socket.connect(host, port, timeout: timeout);
    return NetworkSocket._(socket);
  }

  void add(List<int> data) => _socket.add(data);

  Future<void> flush() => _socket.flush();

  Future<void> close() => _socket.close();
}
