import 'dart:convert';

import '../../../../core/storage/app_secure_storage.dart';
import '../models/pos_login_branding_dto.dart';
import '../../domain/entities/pos_login_branding.dart';

class PosLoginBrandingCacheEntry {
  const PosLoginBrandingCacheEntry(this.branding, this.etag);
  final PosLoginBranding branding;
  final String? etag;
}

class PosLoginBrandingCacheDatasource {
  const PosLoginBrandingCacheDatasource(this._storage);
  // Version 2 stores media URLs resolved against the configured API origin.
  static const _schemaVersion = 2;
  static const _maxAge = Duration(hours: 24);
  final AppSecureStorage _storage;

  String _key(String slug) => 'pos.login.branding.${slug.trim().toLowerCase()}';

  Future<PosLoginBrandingCacheEntry?> read(String slug) async {
    if (slug.trim().isEmpty) return null;
    final raw = await _storage.read(_key(slug));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return null;
      final map = Map<String, dynamic>.from(json);
      final cachedAt = DateTime.tryParse(map['cachedAt']?.toString() ?? '');
      if (map['schemaVersion'] != _schemaVersion ||
          cachedAt == null ||
          DateTime.now().toUtc().difference(cachedAt.toUtc()) > _maxAge) {
        await _storage.delete(_key(slug));
        return null;
      }
      final data = map['branding'];
      if (data is! Map) return null;
      final branding =
          PosLoginBrandingDto(Map<String, dynamic>.from(data)).toDomain();
      if (branding.tenantSlug.toLowerCase() != slug.trim().toLowerCase()) {
        await _storage.delete(_key(slug));
        return null;
      }
      return PosLoginBrandingCacheEntry(branding, map['etag']?.toString());
    } catch (_) {
      await _storage.delete(_key(slug));
      return null;
    }
  }

  Future<void> write(PosLoginBranding branding, String? etag) => _storage.write(
      _key(branding.tenantSlug),
      jsonEncode({
        'schemaVersion': _schemaVersion,
        'cachedAt': DateTime.now().toUtc().toIso8601String(),
        'etag': etag,
        'branding': {
          'tenantSlug': branding.tenantSlug,
          'brandDisplayName': branding.brandDisplayName,
          'systemName': branding.systemName,
          'description': branding.description,
          'loginSubtitle': branding.loginSubtitle,
          'backgroundMode': branding.backgroundMode.name.toUpperCase(),
          'backgroundColor': branding.backgroundColor,
          'logoUrl': branding.logoUrl,
          'backgroundImageUrl': branding.backgroundImageUrl,
          'heroImageUrl': branding.heroImageUrl,
          'updatedAt': branding.updatedAt.toIso8601String(),
        },
      }));
}
