import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/network/dio_provider.dart';
import '../../domain/entities/brand.dart';
import '../../domain/entities/brand_list_query.dart';
import '../../domain/repositories/brand_repository.dart';
import '../../data/datasources/brand_remote_datasource.dart';
import '../../data/repositories/brand_repository_impl.dart';

final brandRemoteDatasourceProvider = Provider<BrandRemoteDatasource>((ref) {
  return BrandRemoteDatasource(ref.watch(appDioProvider));
});

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepositoryImpl(ref.watch(brandRemoteDatasourceProvider));
});

final brandSearchProvider = StateProvider<String>((ref) => '');

final brandListQueryProvider = Provider<BrandListQuery>((ref) {
  return BrandListQuery(
    search: ref.watch(brandSearchProvider),
    pageNumber: 1,
    pageSize: 50,
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
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(brandRepositoryProvider);
      if (brandId == null || brandId.isEmpty) {
        await repository.createBrand(input);
      } else {
        await repository.updateBrand(brandId, input);
      }

      ref.invalidate(brandListProvider);
    });

    if (state.hasError) {
      throw state.error!;
    }

    final repository = ref.read(brandRepositoryProvider);
    if (brandId == null || brandId.isEmpty) {
      final result = await repository.listBrands(
        query: const BrandListQuery(pageSize: 1),
      );
      return result.items.first;
    }

    return repository.getBrandById(brandId);
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
