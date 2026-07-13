import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nytroz_pos/features/tenant_admin/products/presentation/utils/product_api_errors.dart';

void main() {
  group('productValidationErrors', () {
    test('maps duplicate sku code to sku field', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/products'),
        response: Response(
          requestOptions: RequestOptions(path: '/products'),
          statusCode: 409,
          data: {
            'code': 'product.duplicate_sku',
            'message': 'SKU already exists.',
            'details': [],
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        productValidationErrors(error),
        {'sku': 'SKU already exists.'},
      );
    });

    test('maps duplicate barcode code to barcode field', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/products'),
        response: Response(
          requestOptions: RequestOptions(path: '/products'),
          statusCode: 409,
          data: {
            'code': 'product.duplicate_barcode',
            'message': 'Barcode already exists.',
            'details': [],
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        productValidationErrors(error),
        {'barcode': 'Barcode already exists.'},
      );
    });

    test('maps validation details array', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/products'),
        response: Response(
          requestOptions: RequestOptions(path: '/products'),
          statusCode: 400,
          data: {
            'code': 'product.validation_failed',
            'message': 'Product validation failed.',
            'details': [
              {'field': 'productName', 'message': 'Product name is required.'},
              {'field': 'sku', 'message': 'SKU is required.'},
            ],
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(productValidationErrors(error), {
        'productName': 'Product name is required.',
        'sku': 'SKU is required.',
      });
    });
  });

  group('productDeleteErrorMessage', () {
    test('returns backend message for delete blocked', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/products/1'),
        response: Response(
          requestOptions: RequestOptions(path: '/products/1'),
          statusCode: 409,
          data: {
            'code': 'product.delete_blocked',
            'message': 'Product is already deleted.',
          },
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        productDeleteErrorMessage(error),
        'Product is already deleted.',
      );
    });

    test('returns permission message for forbidden', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/products/1'),
        response: Response(
          requestOptions: RequestOptions(path: '/products/1'),
          statusCode: 403,
          data: const {},
        ),
        type: DioExceptionType.badResponse,
      );

      expect(
        productDeleteErrorMessage(error),
        'You do not have permission to delete products.',
      );
    });
  });
}
