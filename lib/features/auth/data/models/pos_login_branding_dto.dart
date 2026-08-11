import '../../../../core/network/media_url_resolver.dart';
import '../../domain/entities/pos_login_branding.dart';

class PosLoginBrandingDto {
  const PosLoginBrandingDto(
    this.json, {
    this.apiBaseUrl = '',
    this.replaceLoopbackHost = false,
  });

  final Map<String, dynamic> json;
  final String apiBaseUrl;
  final bool replaceLoopbackHost;

  PosLoginBranding toDomain() {
    final fallback = PosLoginBranding.packagedDefault;
    final mode = _text('backgroundMode').toUpperCase() == 'IMAGE'
        ? PosLoginBackgroundMode.image
        : PosLoginBackgroundMode.color;
    final color = _text('backgroundColor').toUpperCase();
    return PosLoginBranding(
      tenantSlug: _text('tenantSlug'),
      brandDisplayName:
          _required('brandDisplayName', fallback.brandDisplayName),
      systemName: _required('systemName', fallback.systemName),
      description: _required('description', fallback.description),
      loginSubtitle: _required('loginSubtitle', fallback.loginSubtitle),
      backgroundMode: mode,
      backgroundColor:
          color.posLoginColorValue == null ? fallback.backgroundColor : color,
      logoUrl: _mediaUrl('logoUrl'),
      backgroundImageUrl: _mediaUrl('backgroundImageUrl'),
      heroImageUrl: _mediaUrl('heroImageUrl'),
      updatedAt:
          DateTime.tryParse(_text('updatedAt'))?.toUtc() ?? fallback.updatedAt,
    );
  }

  String _text(String key) => json[key]?.toString().trim() ?? '';
  String _required(String key, String fallback) {
    final value = _text(key);
    return value.isEmpty ? fallback : value;
  }

  String? _optional(String key) {
    final value = _text(key);
    return value.isEmpty ? null : value;
  }

  String? _mediaUrl(String key) {
    final value = _optional(key);
    if (value == null || apiBaseUrl.trim().isEmpty) return value;
    return MediaUrlResolver.resolve(
      value,
      apiBaseUrl: apiBaseUrl,
      replaceLoopbackHost: replaceLoopbackHost,
    );
  }
}
