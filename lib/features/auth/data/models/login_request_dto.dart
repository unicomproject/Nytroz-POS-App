class LoginRequestDto {
  const LoginRequestDto({
    required this.tenantCode,
    required this.login,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'tenantCode': tenantCode,
      'login': login,
      'password': password,
    };
  }

  final String tenantCode;
  final String login;
  final String password;
}
