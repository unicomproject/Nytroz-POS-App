import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nytroz_pos/features/tenant_admin/products/domain/entities/tenant_product.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/tenant_product_filter_options_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/mappers/tenant_product_mapper.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/providers/tenant_product_providers.dart';

void main() {
  group('Product Filter Options DTO & Mapper Tests', () {
    test('TenantProductFilterOptionsDto parses correctly', () {
      final json = {
        'categories': [
          {'id': 'cat-1', 'categoryName': 'Beverages', 'categoryCode': 'BEV'},
        ],
        'brands': [
          {'id': 'brand-1', 'brandName': 'Pepsi', 'brandCode': 'PEP'},
        ],
        'productStatuses': ['ACTIVE', 'DRAFT'],
        'stockStatuses': ['IN_STOCK', 'OUT_OF_STOCK'],
      };

      final dto = TenantProductFilterOptionsDto.fromJson(json);

      expect(dto.categories, hasLength(1));
      expect(dto.categories[0].id, 'cat-1');
      expect(dto.categories[0].name, 'Beverages');
      expect(dto.categories[0].code, 'BEV');

      expect(dto.brands, hasLength(1));
      expect(dto.brands[0].id, 'brand-1');
      expect(dto.brands[0].name, 'Pepsi');

      expect(dto.productStatuses, equals(['ACTIVE', 'DRAFT']));
      expect(dto.stockStatuses, equals(['IN_STOCK', 'OUT_OF_STOCK']));
    });

    test('toFilterOptions maps DTO to domain correctly', () {
      final dto = TenantProductFilterOptionsDto.fromJson({
        'categories': [
          {'id': 'cat-1', 'categoryName': 'Beverages', 'categoryCode': 'BEV'},
        ],
        'brands': [
          {'id': 'brand-1', 'brandName': 'Pepsi', 'brandCode': 'PEP'},
        ],
        'productStatuses': ['ACTIVE'],
        'stockStatuses': ['IN_STOCK'],
      });

      final entity = TenantProductMapper.toFilterOptions(dto);

      expect(entity.categories, hasLength(1));
      expect(entity.categories[0].id, 'cat-1');
      expect(entity.categories[0].name, 'Beverages');
      expect(entity.brands, hasLength(1));
      expect(entity.brands[0].id, 'brand-1');
      expect(entity.brands[0].name, 'Pepsi');
      expect(entity.productStatuses, equals(['ACTIVE']));
      expect(entity.stockStatuses, equals(['IN_STOCK']));
    });
  });

  group('Product List Query Serialization Tests', () {
    test('TenantProductListQuery fields serialization parameters', () {
      const query = TenantProductListQuery(
        search: 'Soda',
        categoryId: 'cat-1',
        brandId: 'brand-1',
        productStatus: 'ACTIVE',
        stockStatus: 'IN_STOCK',
        sortBy: 'name',
        sortDirection: 'desc',
        pageNumber: 3,
        pageSize: 25,
      );

      expect(query.search, 'Soda');
      expect(query.categoryId, 'cat-1');
      expect(query.brandId, 'brand-1');
      expect(query.productStatus, 'ACTIVE');
      expect(query.stockStatus, 'IN_STOCK');
      expect(query.sortBy, 'name');
      expect(query.sortDirection, 'desc');
      expect(query.pageNumber, 3);
      expect(query.pageSize, 25);
    });
  });

  group('Riverpod Filter State Notifier Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is correct', () {
      final state = container.read(productListFilterProvider);
      expect(state.search, isEmpty);
      expect(state.categoryId, isNull);
      expect(state.brandId, isNull);
      expect(state.productStatus, isNull);
      expect(state.stockStatus, isNull);
      expect(state.pageNumber, 1);
      expect(state.pageSize, 5);
    });

    test('Filter changes reset page to 1', () {
      final notifier = container.read(productListFilterProvider.notifier);

      notifier.setPage(5);
      expect(container.read(productListFilterProvider).pageNumber, 5);

      notifier.setCategory('cat-1');
      expect(container.read(productListFilterProvider).categoryId, 'cat-1');
      expect(container.read(productListFilterProvider).pageNumber, 1);

      notifier.setPage(4);
      notifier.setBrand('brand-1');
      expect(container.read(productListFilterProvider).brandId, 'brand-1');
      expect(container.read(productListFilterProvider).pageNumber, 1);
    });

    test('Reset clears all filters and preserves page size', () {
      final notifier = container.read(productListFilterProvider.notifier);

      notifier.setSearch('Soda');
      notifier.setCategory('cat-1');
      notifier.setBrand('brand-1');
      notifier.setProductStatus('ACTIVE');
      notifier.setStockStatus('IN_STOCK');
      notifier.setPageSize(50);
      notifier.setPage(4);

      notifier.resetFilters();

      final state = container.read(productListFilterProvider);
      expect(state.search, isEmpty);
      expect(state.categoryId, isNull);
      expect(state.brandId, isNull);
      expect(state.productStatus, isNull);
      expect(state.stockStatus, isNull);
      expect(state.pageNumber, 1);
      expect(state.pageSize, 50); // Preserved
    });
  });
}
