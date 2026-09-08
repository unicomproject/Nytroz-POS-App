/// Transport adapter only. Possession of a well-formed link is not authorization;
/// the existing onboarding API must validate the token before showing the form.
class TenantAdminSetupLink {
  const TenantAdminSetupLink(this.setupToken);

  final String setupToken;
  static const invalidLocation = '/tenant-admin/setup';

  String get location =>
      '/tenant-admin/setup/${Uri.encodeComponent(setupToken)}';

  static TenantAdminSetupLink? parse(Uri uri) {
    if (uri.scheme != 'oneverz' ||
        uri.host != 'tenant-admin' ||
        uri.path != '/setup' ||
        uri.userInfo.isNotEmpty ||
        uri.hasPort ||
        uri.hasFragment) {
      return null;
    }
    try {
      final parameters = uri.queryParametersAll;
      final tokens = parameters['token'];
      if (parameters.length != 1 || tokens == null || tokens.length != 1) {
        return null;
      }
      final token = tokens.single;
      if (token.isEmpty ||
          token.length > 2048 ||
          token.contains('%') ||
          RegExp(r'\s|[\x00-\x1f\x7f]').hasMatch(token)) {
        return null;
      }
      return TenantAdminSetupLink(token);
    } on FormatException {
      return null;
    }
  }

  /// Shared by cold-start platform routing and warm VIEW intents in GoRouter.
  static String? redirect(Uri uri) {
    if (!uri.hasScheme || uri.scheme == 'http' || uri.scheme == 'https') {
      return null;
    }
    return parse(uri)?.location ?? invalidLocation;
  }
}
