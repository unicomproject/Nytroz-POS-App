import 'dart:developer' as developer;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../core/access/pos_permission_access.dart';
import '../../../../core/network/dio_error_message.dart';
import '../../../../core/network/dio_provider.dart';
import '../../../auth/domain/entities/auth_session.dart';
import '../../../auth/presentation/providers/session_provider.dart';
import '../../../device_activation/presentation/providers/device_activation_provider.dart';
import '../../data/datasources/pos_catalog_remote_datasource.dart';
import '../../domain/entities/pos_catalog_models.dart';
import 'pos_new_sale_cart_provider.dart';

final posCatalogRemoteDatasourceProvider =
    Provider<PosCatalogRemoteDatasource>((ref) {
  return PosCatalogRemoteDatasource(ref.watch(appDioProvider));
});

class PosNewSaleCatalogState {
  const PosNewSaleCatalogState({
    required this.products,
  });

  final List<PosCatalogProductSummary> products;
}

final posNewSaleSelectedCategoryIdProvider =
    StateProvider.autoDispose<String?>((ref) => null);

final posNewSaleCategoriesProvider =
    FutureProvider.autoDispose<List<PosCatalogCategoryOption>>((ref) async {
  final session = ref.watch(authSessionProvider);
  final deviceContext = ref.watch(deviceActivationProvider).deviceContext;

  if (session == null || !session.isAuthenticated || deviceContext == null) {
    return const [PosCatalogCategoryOption(name: 'All')];
  }

  if (!PosPermissionAccess.canViewProductsSession(session)) {
    return const [PosCatalogCategoryOption(name: 'All')];
  }

  _ensureAuthorizationHeader(ref.read(appDioProvider), session);

  try {
    final categories =
        await ref.read(posCatalogRemoteDatasourceProvider).getCategories(
              deviceId: deviceContext.deviceId,
            );

    return [
      const PosCatalogCategoryOption(name: 'All'),
      ...categories.map(
        (category) => PosCatalogCategoryOption(
          id: category.id,
          name: category.name,
        ),
      ),
    ];
  } catch (error, stackTrace) {
    developer.log(
      'POS catalog categories failed to load.',
      name: 'pos.catalog',
      error: error,
      stackTrace: stackTrace,
    );
    return const [PosCatalogCategoryOption(name: 'All')];
  }
});

final posNewSaleCatalogProvider =
    FutureProvider.autoDispose<PosNewSaleCatalogState>((ref) async {
  final session = ref.watch(authSessionProvider);
  ref.watch(deviceActivationProvider);
  final selectedCategoryId = ref.watch(posNewSaleSelectedCategoryIdProvider);
  final searchQuery = ref.watch(posNewSaleSearchQueryProvider).trim();

  if (searchQuery.isNotEmpty) {
    var wasDisposed = false;
    ref.onDispose(() => wasDisposed = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (wasDisposed) {
      return const PosNewSaleCatalogState(products: []);
    }
  }

  if (session == null || !session.isAuthenticated) {
    throw StateError('POS catalog requires an active session.');
  }

  if (!PosPermissionAccess.canViewProductsSession(session)) {
    return const PosNewSaleCatalogState(products: []);
  }

  await ref.read(deviceActivationProvider.notifier).ensureHydrated();
  final deviceContext = ref.read(deviceActivationProvider).deviceContext;
  if (deviceContext == null || deviceContext.deviceId.trim().isEmpty) {
    throw StateError(
      'POS catalog requires an activated device. Open till or activate this device first.',
    );
  }

  _ensureAuthorizationHeader(ref.read(appDioProvider), session);

  try {
    final products =
        await ref.read(posCatalogRemoteDatasourceProvider).getProducts(
              deviceId: deviceContext.deviceId,
              categoryId: selectedCategoryId,
              search: searchQuery,
            );

    return PosNewSaleCatalogState(products: products);
  } on DioException catch (error) {
    final message = messageFromDioException(
      error,
      contextPrefix: 'POS products failed at ${error.requestOptions.path}',
      fallback: 'Unable to load products from the server.',
    );
    developer.log(
      message,
      name: 'pos.catalog',
      error: error,
    );
    throw StateError(message);
  }
});
final posProductDetailProvider = FutureProvider.autoDispose
    .family<PosCatalogProductDetail, String>((ref, productId) async {
  final session = ref.watch(authSessionProvider);
  final deviceContext = ref.watch(deviceActivationProvider).deviceContext;

  if (session == null || !session.isAuthenticated || deviceContext == null) {
    throw StateError(
      'Product detail requires an active session and activated device.',
    );
  }

  if (!PosPermissionAccess.canViewProductsSession(session)) {
    throw StateError('Product detail requires products.view permission.');
  }

  _ensureAuthorizationHeader(ref.read(appDioProvider), session);

  return ref.watch(posCatalogRemoteDatasourceProvider).getProductDetail(
        deviceId: deviceContext.deviceId,
        productId: productId,
      );
});

void _ensureAuthorizationHeader(Dio dio, AuthSession session) {
  final currentValue = dio.options.headers['Authorization'];
  if (currentValue is String && currentValue.trim().isNotEmpty) {
    return;
  }

  dio.options.headers['Authorization'] = 'Bearer ${session.accessToken}';
}
