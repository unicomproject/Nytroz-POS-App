import '../entities/tenant_login_branding_settings.dart';

abstract interface class TenantLoginBrandingRepository {
  Future<TenantLoginBrandingSettings> get();

  Future<TenantLoginBrandingSettings> update(
    UpdateTenantLoginBrandingSettings request,
  );

  Future<TenantLoginBrandingMediaUpload> uploadMedia(
    String purpose,
    TenantLoginBrandingMediaInput input,
  );
}
