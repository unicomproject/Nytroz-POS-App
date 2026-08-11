import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_provider.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/pos_login_branding_cache_datasource.dart';
import '../../data/datasources/pos_login_branding_remote_datasource.dart';
import '../../data/repositories/pos_login_branding_repository_impl.dart';
import '../../domain/entities/pos_login_branding.dart';
import '../../domain/repositories/pos_login_branding_repository.dart';

/// Optional compile-time tenant for web login branding when no device context
/// exists: `--dart-define=POS_LOGIN_TENANT_SLUG=arenasports`
const _posLoginTenantSlugDefine = String.fromEnvironment(
  'POS_LOGIN_TENANT_SLUG',
);

/// Development tenant that owns the seeded POS login branding fixtures.
const _developmentLoginBrandingTenantSlug = 'arenasports';

final posLoginBrandingRepositoryProvider =
    Provider<PosLoginBrandingRepository>((ref) {
  return PosLoginBrandingRepositoryImpl(
    PosLoginBrandingRemoteDatasource(ref.watch(appDioProvider)),
    PosLoginBrandingCacheDatasource(ref.watch(secureStorageProvider)),
  );
});

class PosLoginBrandingController extends StateNotifier<PosLoginBranding> {
  PosLoginBrandingController(this._repository, this._readTenantSlug)
      : super(PosLoginBranding.unloaded) {
    load();
  }
  final PosLoginBrandingRepository _repository;
  final Future<String> Function() _readTenantSlug;
  bool _loading = false;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    final slug = (await _readTenantSlug()).trim().toLowerCase();
    if (slug.isEmpty) {
      // No tenant identity → keep unloaded shell (no local artwork fallback).
      state = PosLoginBranding.unloaded;
      _loading = false;
      return;
    }
    final cached = await _repository.readCached(slug);
    if (cached != null) {
      state = cached;
    }
    try {
      state = await _repository.refresh(slug);
    } catch (_) {
      // Keep tenant cache only. Never substitute packaged local artwork.
      if (cached != null) {
        state = cached;
      }
    } finally {
      _loading = false;
    }
  }
}

Future<String> resolvePosLoginBrandingTenantSlug({
  required String? deviceTenantSlug,
  required Future<String?> Function() readStoredTenantSlug,
}) async {
  final fromDevice = deviceTenantSlug?.trim() ?? '';
  if (fromDevice.isNotEmpty) return fromDevice;

  final stored = (await readStoredTenantSlug())?.trim() ?? '';
  if (stored.isNotEmpty) return stored;

  if (kIsWeb) {
    final fromQuery = Uri.base.queryParameters['tenant']?.trim() ?? '';
    if (fromQuery.isNotEmpty) return fromQuery;
    if (_posLoginTenantSlugDefine.trim().isNotEmpty) {
      return _posLoginTenantSlugDefine.trim();
    }
    // Local Chrome/dev: use the seeded development branding tenant.
    if (kDebugMode) return _developmentLoginBrandingTenantSlug;
  }

  return '';
}

final posLoginBrandingProvider =
    StateNotifierProvider<PosLoginBrandingController, PosLoginBranding>((ref) {
  final activeDevice = ref.watch(
    deviceActivationProvider.select((state) => state.deviceContext),
  );
  return PosLoginBrandingController(
    ref.watch(posLoginBrandingRepositoryProvider),
    () => resolvePosLoginBrandingTenantSlug(
      deviceTenantSlug: activeDevice?.tenantSlug,
      readStoredTenantSlug: () async =>
          (await ref.read(deviceContextStorageProvider).read())?.tenantSlug,
    ),
  );
});
