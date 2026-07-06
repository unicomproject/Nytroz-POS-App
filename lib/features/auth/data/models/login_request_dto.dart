class LoginRequestDto {
  const LoginRequestDto({
    required this.login,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': login,
      'password': password,
    };
  }

  final String login;
  final String password;
}
