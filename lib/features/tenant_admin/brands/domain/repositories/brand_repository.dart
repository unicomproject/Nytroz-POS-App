import '../entities/brand.dart';
import '../entities/brand_list_query.dart';

abstract class BrandRepository {
  Future<BrandListResult> listBrands({required BrandListQuery query});

  Future<Brand> getBrandById(String id);

  Future<Brand> createBrand(BrandUpsertInput input);

  Future<Brand> updateBrand(String id, BrandUpsertInput input);

  Future<void> deleteBrand(String id);
}
