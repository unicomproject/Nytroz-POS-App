import '../entities/pos_login_branding.dart';

abstract class PosLoginBrandingRepository {
  Future<PosLoginBranding?> readCached(String tenantSlug);
  Future<PosLoginBranding> refresh(String tenantSlug);
}
