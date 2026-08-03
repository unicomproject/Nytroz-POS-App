class MediaUrlResolver {
  const MediaUrlResolver._();

  static String? resolve(
    String? value, {
    required String apiBaseUrl,
    bool replaceLoopbackHost = false,
  }) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    final mediaUri = Uri.tryParse(trimmed);
    final baseUri = Uri.tryParse(apiBaseUrl.trim());
    if (mediaUri == null || baseUri == null || !baseUri.hasScheme) {
      return trimmed;
    }

    if (!mediaUri.hasScheme) {
      if (!baseUri.hasAuthority) {
        return trimmed;
      }
      final origin = baseUri.replace(path: '/', query: null, fragment: null);
      return origin.resolveUri(mediaUri).toString();
    }

    if (replaceLoopbackHost &&
        _isLoopback(mediaUri.host) &&
        baseUri.host.isNotEmpty &&
        !_isLoopback(baseUri.host)) {
      return mediaUri.replace(host: baseUri.host).toString();
    }

    return mediaUri.toString();
  }

  static bool _isLoopback(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1';
  }
}
