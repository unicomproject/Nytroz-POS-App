class AuthException implements Exception {
  const AuthException({
    required this.errorCode,
    required this.message,
  });

  final String errorCode;
  final String message;

  @override
  String toString() => '$errorCode: $message';
}
