import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/data/mappers/brand_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/data/models/brand_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/domain/entities/brand.dart';
import 'package:nytroz_pos/features/tenant_admin/brands/presentation/widgets/brand_details_side_panel.dart';
import 'package:nytroz_pos/features/tenant_admin/presentation/layout/tenant_admin_footer_navigation.dart';

void main() {
  group('BrandMapper', () {
    test('maps logo, sortOrder and productCount from dto', () {
      final entity = BrandMapper.toEntity(
        const BrandDto(
          id: '1',
          brandCode: 'ACME',
          brandName: 'Acme',
          status: 'ACTIVE',
          description: 'Desc',
          logoUrl: 'https://cdn.example/logo.png',
          logoMediaAssetId: 'media-1',
          sortOrder: 5,
          productCount: 12,
        ),
      );

      expect(entity.code, 'ACME');
      expect(entity.logoUrl, 'https://cdn.example/logo.png');
      expect(entity.sortOrder, 5);
      expect(entity.productCount, 12);
      expect(entity.hasLogo, isTrue);
    });

    test('maps upsert sortOrder into request dto', () {
      final dto = BrandMapper.toRequestDto(
        const BrandUpsertInput(
          code: 'ACME',
          name: 'Acme',
          status: 'ACTIVE',
          sortOrder: 7,
        ),
      );

      expect(dto.sortOrder, 7);
      expect(dto.toJson()['sortOrder'], 7);
    });
  });

  group('Brand helpers', () {
    test('deriveBrandCode normalizes name', () {
      expect(deriveBrandCode('One Verz Originals'), 'ONE_VERZ_ORIGINALS');
    });
  });

  group('Tenant Admin footer path helper', () {
    test('marks brands and products as settings area', () {
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/brands'), isTrue);
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/products'), isFalse);
      expect(isTenantAdminSettingsAreaPath('/tenant-admin/dashboard'), isFalse);
      expect(isTenantAdminSettingsAreaPath('/pos/home'), isFalse);
    });
  });
}
