import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/data/models/product_status_update_dto.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/utils/product_status_actions.dart';

void main() {
  group('ProductStatusUpdateRequestDto', () {
    test('maps status to backend payload', () {
      const dto = ProductStatusUpdateRequestDto(status: 'ACTIVE');

      expect(dto.toJson(), {'status': 'ACTIVE'});
    });
  });

  group('ProductStatusUpdateResponseDto', () {
    test('parses backend response', () {
      final dto = ProductStatusUpdateResponseDto.fromJson({
        'productId': '11111111-1111-1111-1111-111111111111',
        'status': 'INACTIVE',
      });

      expect(dto.productId, '11111111-1111-1111-1111-111111111111');
      expect(dto.status, 'INACTIVE');
    });
  });

  group('ProductStatusAction', () {
    test('hides current status actions for active product', () {
      final actions =
          ProductStatusAction.availableForStatus('ACTIVE').map((a) => a.label);

      expect(actions, ['Inactive', 'Draft']);
    });

    test('shows activate action for inactive product', () {
      final actions =
          ProductStatusAction.availableForStatus('INACTIVE').map((a) => a.label);

      expect(actions, ['Active']);
    });
  });
}
