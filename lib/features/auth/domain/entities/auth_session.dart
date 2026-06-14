class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.userId,
    required this.userDisplayName,
    this.permissionCodes = const [],
    this.refreshToken,
    this.expiresAt,
  });

  final String accessToken;
  final String? refreshToken;
  final String userId;
  final String userDisplayName;
  final List<String> permissionCodes;
  final DateTime? expiresAt;

  bool get isAuthenticated => accessToken.isNotEmpty;

  bool hasPermission(String permissionCode) {
    return permissionCodes.contains(permissionCode);
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'userId': userId,
      'userDisplayName': userDisplayName,
      'permissionCodes': permissionCodes,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken'] as String? ?? '',
      refreshToken: json['refreshToken'] as String?,
      userId: json['userId'] as String? ?? '',
      userDisplayName: json['userDisplayName'] as String? ?? '',
      permissionCodes: _stringList(json['permissionCodes']),
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value
        .map((item) => item.toString())
        .where((item) => item.trim().isNotEmpty)
        .toList(growable: false);
  }

  return const [];
}
