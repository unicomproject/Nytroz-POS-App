class AuthBranding {
  const AuthBranding({
    this.logoUrl,
    this.loginIllustrationUrl,
  });

  final String? logoUrl;
  final String? loginIllustrationUrl;

  bool get hasLogo => logoUrl != null && logoUrl!.trim().isNotEmpty;
  bool get hasLoginIllustration =>
      loginIllustrationUrl != null && loginIllustrationUrl!.trim().isNotEmpty;
}
