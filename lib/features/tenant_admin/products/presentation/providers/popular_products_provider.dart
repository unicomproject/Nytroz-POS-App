import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/access/tenant_admin_access_codes.dart';
import '../../../../../core/network/dio_provider.dart';
import '../../../presentation/providers/tenant_admin_access_provider.dart';
import '../../domain/entities/curated_popular_product.dart';
import '../../domain/entities/tenant_product.dart';
import 'tenant_product_providers.dart';

class PopularProductsCurationNotifier
    extends AutoDisposeAsyncNotifier<List<CuratedPopularProduct>> {
  @override
  Future<List<CuratedPopularProduct>> build() async {
    final accessChecker =
        await ref.watch(tenantAdminAccessCheckerProvider.future);
    if (!accessChecker.can(TenantAdminPermissionCodes.catalogCollectionsView) &&
        !accessChecker
            .can(TenantAdminPermissionCodes.catalogCollectionsManage)) {
      return const [];
    }

    final dio = ref.watch(appDioProvider);
    final response =
        await dio.get<dynamic>('/api/v1/collections/pos-popular/products');
    final data = response.data;
    List<dynamic> list = [];
    if (data is Map && data['data'] is List) {
      list = data['data'] as List;
    } else if (data is List) {
      list = data;
    }
    return list
        .map((item) => CuratedPopularProduct.fromJson(
            Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  void reorder(int oldIndex, int newIndex) {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final updated = List<CuratedPopularProduct>.from(currentList);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    for (int i = 0; i < updated.length; i++) {
      updated[i] = CuratedPopularProduct(
        productId: updated[i].productId,
        productName: updated[i].productName,
        sku: updated[i].sku,
        status: updated[i].status,
        sortOrder: i,
      );
    }
    state = AsyncData(updated);
  }

  void addProduct(
      String productId, String productName, String? sku, String status) {
    final currentList = state.valueOrNull ?? [];
    if (currentList.any((p) => p.productId == productId)) return;

    final updated = List<CuratedPopularProduct>.from(currentList);
    updated.add(CuratedPopularProduct(
      productId: productId,
      productName: productName,
      sku: sku,
      status: status,
      sortOrder: updated.length,
    ));
    state = AsyncData(updated);
  }

  void removeProduct(String productId) {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    final updated = currentList.where((p) => p.productId != productId).toList();
    for (int i = 0; i < updated.length; i++) {
      updated[i] = CuratedPopularProduct(
        productId: updated[i].productId,
        productName: updated[i].productName,
        sku: updated[i].sku,
        status: updated[i].status,
        sortOrder: i,
      );
    }
    state = AsyncData(updated);
  }

  Future<void> save() async {
    final currentList = state.valueOrNull;
    if (currentList == null) return;

    state = const AsyncLoading();
    try {
      final dio = ref.read(appDioProvider);
      final productIds = currentList.map((p) => p.productId).toList();
      final response = await dio.put<dynamic>(
        '/api/v1/collections/pos-popular/products',
        data: productIds,
      );
      final data = response.data;
      List<dynamic> list = [];
      if (data is Map && data['data'] is List) {
        list = data['data'] as List;
      } else if (data is List) {
        list = data;
      }
      final updated = list
          .map((item) => CuratedPopularProduct.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList();
      state = AsyncData(updated);
    } catch (e, stack) {
      state = AsyncError(e, stack);
      rethrow;
    }
  }
}

final popularProductsCurationProvider = AsyncNotifierProvider.autoDispose<
    PopularProductsCurationNotifier, List<CuratedPopularProduct>>(() {
  return PopularProductsCurationNotifier();
});

final popularSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');
final popularSearchPageProvider = StateProvider.autoDispose<int>((ref) => 1);

final popularSearchProductsProvider =
    FutureProvider.autoDispose<TenantProductListResult?>((ref) async {
  final accessChecker =
      await ref.watch(tenantAdminAccessCheckerProvider.future);
  if (!accessChecker.can(TenantAdminPermissionCodes.catalogCollectionsView) &&
      !accessChecker.can(TenantAdminPermissionCodes.catalogCollectionsManage)) {
    return null;
  }

  final query = TenantProductListQuery(
    search: ref.watch(popularSearchQueryProvider),
    pageNumber: ref.watch(popularSearchPageProvider),
    pageSize: 15,
    productStatus: 'ACTIVE',
  );
  return ref.watch(getProductsProvider).call(query: query);
});
