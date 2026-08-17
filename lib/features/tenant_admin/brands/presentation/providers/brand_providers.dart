import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/brand_list_query.dart';
import '../../domain/repositories/brand_repository.dart';
import '../../data/datasources/brand_remote_datasource.dart';
import '../../data/repositories/brand_repository_impl.dart';
import '../../../presentation/theme/tenant_admin_theme.dart';

final brandRemoteDatasourceProvider = Provider<BrandRemoteDatasource>((ref) {
  return BrandRemoteDatasource(ref.watch(appDioProvider));
});

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepositoryImpl(ref.watch(brandRemoteDatasourceProvider));
});

final brandSearchProvider = StateProvider<String>((ref) => '');

final brandPageProvider = StateProvider<int>((ref) => 1);

final brandListQueryProvider = Provider<BrandListQuery>((ref) {
  return BrandListQuery(
    search: ref.watch(brandSearchProvider),
    pageNumber: ref.watch(brandPageProvider),
    pageSize: TenantAdminContentTokens.defaultListPageSize,
  );
});

final brandListProvider =
    FutureProvider.autoDispose<BrandListResult?>((ref) async {
  final query = ref.watch(brandListQueryProvider);
  return ref.watch(brandRepositoryProvider).listBrands(query: query);
});

final brandSaveControllerProvider =
    AutoDisposeAsyncNotifierProvider<BrandSaveController, void>(
  BrandSaveController.new,
);

class BrandSaveController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Brand> save({
    String? brandId,
    required BrandUpsertInput input,
    Uint8List? logoBytes,
    String? logoFileName,
  }) async {
    state = const AsyncLoading();

    final result = await AsyncValue.guard<Brand>(() async {
      final repository = ref.read(brandRepositoryProvider);
      final isCreate = brandId == null || brandId.isEmpty;
      var brand = isCreate
          ? await repository.createBrand(input)
          : await repository.updateBrand(brandId, input);

      if (logoBytes != null && logoBytes.isNotEmpty) {
        brand = await repository.uploadBrandLogo(
          brand.id,
          logoBytes,
          logoFileName ?? 'logo.jpg',
        );
      }

      return brand;
    });

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      throw result.error!;
    }

    state = const AsyncData(null);
    ref.invalidate(brandListProvider);
    return result.requireValue;
  }

  Future<void> delete(String brandId) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      await ref.read(brandRepositoryProvider).deleteBrand(brandId);
      ref.invalidate(brandListProvider);
    });

    if (state.hasError) {
      throw state.error!;
    }
  }
}
