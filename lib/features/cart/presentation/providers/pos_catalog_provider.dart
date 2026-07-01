import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/pos_catalog_fallback_data.dart';
import '../../data/datasources/pos_catalog_remote_datasource.dart';
import '../../domain/entities/pos_catalog_models.dart';

final posCatalogRemoteDatasourceProvider =
    Provider<PosCatalogRemoteDatasource>((ref) {
  return PosCatalogRemoteDatasource(ref.watch(appDioProvider));
});

class PosNewSaleCatalogState {
  const PosNewSaleCatalogState({
    required this.products,
    required this.usedFallback,
  });

  final List<PosCatalogProductSummary> products;
  final bool usedFallback;
}

final posNewSaleCatalogProvider =
    FutureProvider.autoDispose<PosNewSaleCatalogState>((ref) async {
  final session = ref.watch(authSessionProvider);
  final deviceContext = ref.watch(deviceActivationProvider).deviceContext;

  if (session == null || !session.isAuthenticated || deviceContext == null) {
    return const PosNewSaleCatalogState(
      products: posCatalogFallbackSummaries,
      usedFallback: true,
    );
  }

  if (!PosPermissionAccess.canViewProductsSession(session)) {
    return const PosNewSaleCatalogState(
      products: [],
      usedFallback: false,
    );
  }

  _ensureAuthorizationHeader(ref.read(appDioProvider), session);

  try {
    final products =
        await ref.watch(posCatalogRemoteDatasourceProvider).getProducts(
              deviceId: deviceContext.deviceId,
            );

    if (products.isEmpty) {
      return const PosNewSaleCatalogState(
        products: posCatalogFallbackSummaries,
        usedFallback: true,
      );
    }

    return PosNewSaleCatalogState(products: products, usedFallback: false);
  } catch (_) {
    return const PosNewSaleCatalogState(
      products: posCatalogFallbackSummaries,
      usedFallback: true,
    );
  }
});

final posProductDetailProvider = FutureProvider.autoDispose
    .family<PosCatalogProductDetail, String>((ref, productId) async {
  final session = ref.watch(authSessionProvider);
  final deviceContext = ref.watch(deviceActivationProvider).deviceContext;

  if (session == null || !session.isAuthenticated || deviceContext == null) {
    return posCatalogFallbackDetail(productId);
  }

  if (!PosPermissionAccess.canViewProductsSession(session)) {
    throw StateError('Product detail requires products.view permission.');
  }

  _ensureAuthorizationHeader(ref.read(appDioProvider), session);

  try {
    return await ref.watch(posCatalogRemoteDatasourceProvider).getProductDetail(
          deviceId: deviceContext.deviceId,
          productId: productId,
        );
  } catch (_) {
    return posCatalogFallbackDetail(productId);
  }
});

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}
