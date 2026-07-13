import '../../domain/entities/brand.dart';
import '../models/brand_dto.dart';

class BrandMapper {
  const BrandMapper._();

  static Brand toEntity(BrandDto dto) {
    return Brand(
      id: dto.id,
      code: dto.brandCode,
      name: dto.brandName,
      status: dto.status,
      description: dto.description,
      createdAt: dto.createdAt,
      updatedAt: dto.updatedAt,
    );
  }

  static BrandListResult toListResult(BrandListResultDto dto) {
    return BrandListResult(
      items: dto.items.map(toEntity).toList(growable: false),
      pageNumber: dto.pageNumber,
      pageSize: dto.pageSize,
      totalCount: dto.totalCount,
    );
  }

  static BrandUpsertRequestDto toRequestDto(BrandUpsertInput input) {
    final code = input.code.trim().toUpperCase();
    return BrandUpsertRequestDto(
      brandCode: code,
      name: input.name.trim(),
      status: input.status.trim().toUpperCase(),
      description: input.description,
      brandSlug: code.toLowerCase(),
    );
  }
}
