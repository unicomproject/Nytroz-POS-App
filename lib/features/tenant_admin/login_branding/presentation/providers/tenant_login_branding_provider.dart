import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../data/datasources/tenant_login_branding_remote_datasource.dart';
import '../../data/repositories/tenant_login_branding_repository_impl.dart';
import '../../domain/entities/tenant_login_branding_settings.dart';
import '../../domain/repositories/tenant_login_branding_repository.dart';

final tenantLoginBrandingRepositoryProvider =
    Provider<TenantLoginBrandingRepository>((ref) {
  return TenantLoginBrandingRepositoryImpl(
    TenantLoginBrandingRemoteDatasource(ref.watch(appDioProvider)),
  );
});

class TenantLoginBrandingController
    extends StateNotifier<AsyncValue<TenantLoginBrandingSettings>> {
  TenantLoginBrandingController(this._repository)
      : super(const AsyncValue.loading()) {
    load();
  }

  final TenantLoginBrandingRepository _repository;
  bool _saving = false;

  Future<void> load() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_repository.get);
  }

  Future<bool> save(UpdateTenantLoginBrandingSettings request) async {
    if (_saving) return false;
    _saving = true;
    try {
      state = AsyncValue.data(await _repository.update(request));
      return true;
    } catch (_) {
      // Keep the loaded settings and the user's form values visible so a
      // transient save failure does not replace the editor with a load error.
      return false;
    } finally {
      _saving = false;
    }
  }

  Future<bool> reset() => save(const UpdateTenantLoginBrandingSettings());

  Future<TenantLoginBrandingMediaUpload> uploadMedia(
    String purpose,
    TenantLoginBrandingMediaInput input,
  ) =>
      _repository.uploadMedia(purpose, input);
}

final tenantLoginBrandingProvider = StateNotifierProvider.autoDispose<
    TenantLoginBrandingController,
    AsyncValue<TenantLoginBrandingSettings>>((ref) {
  return TenantLoginBrandingController(
    ref.watch(tenantLoginBrandingRepositoryProvider),
  );
});
