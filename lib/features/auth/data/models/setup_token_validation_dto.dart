class SetupTokenValidationDto {
  const SetupTokenValidationDto({
    required this.setupToken,
    required this.valid,
    required this.expired,
    this.email,
    this.message,
    this.code,
  });

  factory SetupTokenValidationDto.fromJson(Map<String, dynamic> json) {
    return SetupTokenValidationDto(
      setupToken: json['setupToken'] as String? ?? '',
      valid: json['valid'] as bool? ?? false,
      expired: json['expired'] as bool? ?? false,
      email: json['email'] as String?,
      message: json['message'] as String?,
      code: json['code'] as String?,
    );
  }

  final String setupToken;
  final bool valid;
  final bool expired;
  final String? email;
  final String? message;
  final String? code;
}
