class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.userDisplayName,
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final String userId;
  final String userDisplayName;
  final DateTime? expiresAt;

  bool get isAuthenticated => accessToken.isNotEmpty;
}
