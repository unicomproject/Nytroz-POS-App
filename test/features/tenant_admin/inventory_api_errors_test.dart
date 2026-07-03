import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/inventory/presentation/utils/inventory_api_errors.dart';

void main() {
  group('inventoryValidationErrors', () {
    test('maps list-style backend field errors', () {
      final errors = inventoryValidationErrors(
        _dioExceptionWithBody({
          'errors': [
            {'field': 'quantity', 'message': 'Quantity must be positive.'},
            {'field': 'productId', 'message': 'Product is required.'},
          ],
        }),
      );

      expect(errors['quantity'], 'Quantity must be positive.');
      expect(errors['productId'], 'Product is required.');
    });

    test('maps map-style backend field errors', () {
      final errors = inventoryValidationErrors(
        _dioExceptionWithBody({
          'errors': {
            'unitCost': ['Unit cost is required.'],
          },
        }),
      );

      expect(errors['unitCost'], 'Unit cost is required.');
    });
  });
}

DioException _dioExceptionWithBody(Map<String, dynamic> body) {
  final requestOptions = RequestOptions(path: '/test');
  return DioException(
    requestOptions: requestOptions,
    response: Response(
      requestOptions: requestOptions,
      data: body,
      statusCode: 400,
    ),
  );
}
