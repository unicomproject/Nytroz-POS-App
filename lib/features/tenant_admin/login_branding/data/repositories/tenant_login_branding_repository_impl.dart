import '../../domain/entities/tenant_login_branding_settings.dart';
import '../../domain/repositories/tenant_login_branding_repository.dart';
import '../datasources/tenant_login_branding_remote_datasource.dart';

class TenantLoginBrandingRepositoryImpl
    implements TenantLoginBrandingRepository {
  const TenantLoginBrandingRepositoryImpl(this._remote);

  final TenantLoginBrandingRemoteDatasource _remote;

  @override
  Future<TenantLoginBrandingSettings> get() => _remote.get();

  @override
  Future<TenantLoginBrandingSettings> update(
    UpdateTenantLoginBrandingSettings request,
  ) =>
      _remote.update(request);

  @override
  Future<TenantLoginBrandingMediaUpload> uploadMedia(
    String purpose,
    TenantLoginBrandingMediaInput input,
  ) =>
      _remote.uploadMedia(purpose, input);
}
