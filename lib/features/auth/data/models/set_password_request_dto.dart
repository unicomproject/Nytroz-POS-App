class SetPasswordRequestDto {
  const SetPasswordRequestDto({
    required this.setupToken,
    required this.password,
    required this.confirmPassword,
  });

  Map<String, dynamic> toJson() {
    return {
      'setupToken': setupToken,
      'password': password,
      'confirmPassword': confirmPassword,
    };
  }

  final String setupToken;
  final String password;
  final String confirmPassword;
}
