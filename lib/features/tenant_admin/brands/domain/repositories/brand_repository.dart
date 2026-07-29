import 'dart:typed_data';

import '../entities/brand.dart';
import '../entities/brand_list_query.dart';

abstract class BrandRepository {
  Future<BrandListResult> listBrands({required BrandListQuery query});

  Future<Brand> getBrandById(String id);

  Future<Brand> createBrand(BrandUpsertInput input);

  Future<Brand> updateBrand(String id, BrandUpsertInput input);

  Future<void> deleteBrand(String id);

  Future<Brand> uploadBrandLogo(String id, Uint8List bytes, String fileName);
}
