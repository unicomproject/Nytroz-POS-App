import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_delete_response_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/mappers/tenant_product_mapper.dart';

void main() {
  group('ProductDeleteResponseDto', () {
    test('parses delete response payload', () {
      final dto = ProductDeleteResponseDto.fromJson({
        'productId': 'prod-1',
        'outcome': 'Deleted',
        'status': 'DELETED',
      });

      expect(dto.productId, 'prod-1');
      expect(dto.outcome, 'Deleted');
      expect(dto.status, 'DELETED');
    });

    test('maps archived outcome to entity', () {
      final result = TenantProductMapper.toDeleteResult(
        ProductDeleteResponseDto.fromJson({
          'productId': 'prod-2',
          'outcome': 'Archived',
          'status': 'INACTIVE',
        }),
      );

      expect(result.productId, 'prod-2');
      expect(result.outcome, 'Archived');
      expect(result.status, 'INACTIVE');
      expect(result.wasArchived, isTrue);
    });
  });
}
