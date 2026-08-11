import '../../domain/entities/pos_login_branding.dart';
import '../../domain/repositories/pos_login_branding_repository.dart';
import '../datasources/pos_login_branding_cache_datasource.dart';
import '../datasources/pos_login_branding_remote_datasource.dart';

class PosLoginBrandingRepositoryImpl implements PosLoginBrandingRepository {
  const PosLoginBrandingRepositoryImpl(this._remote, this._cache);
  final PosLoginBrandingRemoteDatasource _remote;
  final PosLoginBrandingCacheDatasource _cache;

  @override
  Future<PosLoginBranding?> readCached(String tenantSlug) async =>
      (await _cache.read(tenantSlug))?.branding;

  @override
  Future<PosLoginBranding> refresh(String tenantSlug) async {
    final cached = await _cache.read(tenantSlug);
    final result = await _remote.get(tenantSlug, etag: cached?.etag);
    if (result.dto == null && cached != null) return cached.branding;
    final branding = result.dto!.toDomain();
    if (branding.tenantSlug.toLowerCase() != tenantSlug.trim().toLowerCase()) {
      throw const FormatException('Branding tenant mismatch.');
    }
    await _cache.write(branding, result.etag);
    return branding;
  }
}
