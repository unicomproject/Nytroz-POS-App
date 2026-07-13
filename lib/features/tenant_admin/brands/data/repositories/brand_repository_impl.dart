import '../../domain/entities/brand.dart';
import '../../domain/entities/brand_list_query.dart';
import '../../domain/repositories/brand_repository.dart';
import '../datasources/brand_remote_datasource.dart';
import '../mappers/brand_mapper.dart';

class BrandRepositoryImpl implements BrandRepository {
  const BrandRepositoryImpl(this._remoteDatasource);

  final BrandRemoteDatasource _remoteDatasource;

  @override
  Future<BrandListResult> listBrands({required BrandListQuery query}) async {
    final dto = await _remoteDatasource.listBrands(query);
    return BrandMapper.toListResult(dto);
  }

  @override
  Future<Brand> getBrandById(String id) async {
    final dto = await _remoteDatasource.getBrandById(id);
    return BrandMapper.toEntity(dto);
  }

  @override
  Future<Brand> createBrand(BrandUpsertInput input) async {
    final dto = await _remoteDatasource.createBrand(
      BrandMapper.toRequestDto(input),
    );
    return BrandMapper.toEntity(dto);
  }

  @override
  Future<Brand> updateBrand(String id, BrandUpsertInput input) async {
    final dto = await _remoteDatasource.updateBrand(
      id,
      BrandMapper.toRequestDto(input),
    );
    return BrandMapper.toEntity(dto);
  }

  @override
  Future<void> deleteBrand(String id) async {
    await _remoteDatasource.deleteBrand(id);
  }
}
