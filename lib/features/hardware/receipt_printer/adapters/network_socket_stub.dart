class NetworkSocket {
  NetworkSocket._();

  static Future<NetworkSocket> connect(
    String host,
    int port, {
    Duration? timeout,
  }) {
    throw UnsupportedError(
      'Network receipt printing is not supported on web.',
    );
  }

  void add(List<int> data) {}

  Future<void> flush() async {}

  Future<void> close() async {}
}
