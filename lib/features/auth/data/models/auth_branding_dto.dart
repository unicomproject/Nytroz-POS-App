class AuthBrandingDto {
  const AuthBrandingDto({
    this.logoUrl,
    this.loginIllustrationUrl,
  });

  factory AuthBrandingDto.fromJson(Map<String, dynamic> json) {
    return AuthBrandingDto(
      logoUrl: json['logoUrl'] as String?,
      loginIllustrationUrl: json['loginIllustrationUrl'] as String?,
    );
  }

  final String? logoUrl;
  final String? loginIllustrationUrl;
}
